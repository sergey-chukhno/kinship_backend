class Api::V1::TeachersController < Api::V1::Teachers::BaseController
  
  # GET /api/v1/teachers/projects
  def projects
    # Projects owned by teacher OR linked to teacher's classes
    teacher_classes = current_user.assigned_classes.pluck(:id)
    
    @projects = Project
      .left_joins(:project_school_levels)
      .where('projects.owner_id = ? OR project_school_levels.school_level_id IN (?)', 
             current_user.id, teacher_classes)
      .distinct
      .includes(:owner, :skills, :tags, :school_levels)
    
    # Filters
    @projects = @projects.where(status: params[:status]) if params[:status]
    @projects = @projects.joins(:project_school_levels).where(project_school_levels: {school_level_id: params[:class_id]}) if params[:class_id]
    @projects = @projects.joins(:project_school_levels).joins('JOIN school_levels ON project_school_levels.school_level_id = school_levels.id').where(school_levels: {school_id: params[:school_id]}) if params[:school_id]
    
    @pagy, @projects = pagy(@projects.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: ActiveModelSerializers::SerializableResource.new(@projects, each_serializer: ProjectSerializer).as_json,
      meta: pagination_meta(@pagy)
    }
  end
  
  # POST /api/v1/teachers/projects
  def create_project
    @project = Project.new(project_params)
    @project.owner = current_user
    @project.private ||= false
    @project.status ||= :in_progress
    
    # Validate: All school_levels must be teacher's classes
    if params[:project][:school_level_ids].present?
      teacher_class_ids = current_user.assigned_classes.pluck(:id)
      requested_class_ids = params[:project][:school_level_ids].map(&:to_i)
      
      unless (requested_class_ids - teacher_class_ids).empty?
        return render json: {
          error: 'Forbidden',
          message: 'You can only create projects for your own classes'
        }, status: :forbidden
      end
    end
    
    if @project.save
      render json: @project, serializer: ProjectSerializer, status: :created
    else
      render json: { 
        error: 'Validation Failed',
        details: @project.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  # GET /api/v1/teachers/schools
  def schools
    @schools = current_user.user_schools
      .confirmed
      .includes(:school)
      .where(role: [:intervenant, :referent, :admin, :superadmin])
    
    render json: {
      data: @schools.map { |us| serialize_teacher_school(us) },
      meta: {
        total_schools: @schools.count,
        total_classes_across_schools: @schools.sum { |us| us.school.school_levels.count }
      }
    }
  end
  
  # GET /api/v1/teachers/stats
  def stats
    teacher_classes = current_user.assigned_classes.includes(:students, :projects)
    teacher_projects = current_user.projects.includes(:user_badges)
    
    overview = {
      total_classes: teacher_classes.count,
      independent_classes: teacher_classes.where(school_id: nil).count,
      school_classes: teacher_classes.where.not(school_id: nil).count,
      total_students: teacher_classes.sum { |c| c.students.count },
      total_projects: teacher_projects.count,
      badges_assigned: UserBadge.where(sender: current_user).count
    }
    
    by_school = teacher_classes.group_by(&:school_id).map do |school_id, classes|
      school = classes.first.school
      {
        school_id: school_id,
        school_name: school&.name || 'Independent',
        classes: classes.count,
        students: classes.sum { |c| c.students.count }
      }
    end
    
    recent_activity = UserBadge.where(sender: current_user)
      .order(created_at: :desc)
      .limit(5)
      .map do |badge|
        {
          type: 'badge_assigned',
          student_name: badge.receiver.full_name,
          badge_name: badge.badge.name,
          date: badge.created_at.strftime('%Y-%m-%d')
        }
      end
    
    render json: {
      overview: overview,
      by_school: by_school,
      recent_activity: recent_activity
    }
  end
  
  # GET /api/v1/teachers/independent-status
  def independent_status
    independent_teacher = current_user.independent_teacher
    
    unless independent_teacher
      return render json: {
        error: 'Not Found',
        message: 'No independent teacher record found'
      }, status: :not_found
    end
    
    independent_classes = current_user.assigned_classes.where(school_id: nil)
    independent_students = independent_classes.sum { |c| c.students.count }
    
    render json: {
      independent_teacher: {
        id: independent_teacher.id,
        organization_name: independent_teacher.organization_name,
        status: independent_teacher.status,
        has_contract: independent_teacher.active_contract?,
        can_assign_badges: independent_teacher.can_assign_badges?,
        current_contract: independent_teacher.current_contract ? {
          id: independent_teacher.current_contract.id,
          start_date: independent_teacher.current_contract.start_date,
          end_date: independent_teacher.current_contract.end_date,
          active: independent_teacher.current_contract.active
        } : nil
      },
      independent_classes: independent_classes.count,
      independent_students: independent_students
    }
  end
  
  private
  
  def project_params
    params.require(:project).permit(
      :title, :description, :start_date, :end_date, :private, :status,
      :participants_number, skill_ids: [], tag_ids: [], school_level_ids: []
    )
  end
  
  def serialize_teacher_school(user_school)
    school = user_school.school
    
    {
      id: school.id,
      name: school.name,
      city: school.city,
      my_role: user_school.role,
      joined_at: user_school.created_at
    }
  end
end
