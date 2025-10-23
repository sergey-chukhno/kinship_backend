class Api::V1::Teachers::ProjectsController < Api::V1::Teachers::BaseController
  include Pagy::Backend
  
  before_action :set_project, only: [:show, :update, :destroy, :add_member, :remove_member, :members]
  before_action :ensure_teacher_can_manage_project, only: [:show, :update, :destroy, :add_member, :remove_member, :members]
  
  # GET /api/v1/teachers/projects
  def index
    # Get projects owned by teacher
    owned_projects = current_user.projects.includes(:school_levels, :owner)
    
    # Get projects for classes the teacher manages
    managed_classes = current_user.assigned_classes
    class_projects = Project.joins(:school_levels)
                           .where(school_levels: managed_classes)
                           .includes(:school_levels, :owner)
    
    # Combine and deduplicate
    @projects = Project.where(id: (owned_projects.pluck(:id) + class_projects.pluck(:id)))
                      .includes(:school_levels, :owner, :project_members)
    
    # Filters
    @projects = @projects.where(status: params[:status]) if params[:status].present?
    @projects = @projects.where("title ILIKE ? OR description ILIKE ?", 
                               "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    
    @pagy, @projects = pagy(@projects.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: @projects.map { |p| serialize_teacher_project(p) },
      meta: pagination_meta(@pagy)
    }
  end
  
  # GET /api/v1/teachers/projects/:id
  def show
    render json: serialize_teacher_project(@project, include_details: true)
  end
  
  # POST /api/v1/teachers/projects
  def create
    # Get project parameters
    project_data = project_params
    
    # Get school_level_ids from either project params or root params (RSwag sends at root level)
    school_level_ids = project_data[:school_level_ids] || params[:school_level_ids] || []
    school_levels = SchoolLevel.where(id: school_level_ids)
    
    school_levels.each do |school_level|
      unless teacher_can_manage_class?(school_level)
        return render json: {
          error: 'Forbidden',
          message: 'You are not authorized to create projects for one or more of these classes'
        }, status: :forbidden
      end
    end
    
    # Remove school_level_ids from project_data since it's not a Project attribute
    @project = current_user.projects.build(project_data.except(:school_level_ids))
    
    # Associate with school levels before saving (to pass validation)
    school_levels.each do |school_level|
      @project.project_school_levels.build(school_level: school_level)
    end
    
    if @project.save
      render json: serialize_teacher_project(@project, include_details: true), status: :created
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/teachers/projects/:id
  def update
    if @project.update(project_params)
      render json: serialize_teacher_project(@project, include_details: true)
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/teachers/projects/:id
  def destroy
    @project.destroy
    head :no_content
  end

  # POST /api/v1/teachers/projects/:id/add_member
  # Add a member to the project
  def add_member
    user_id = params[:user_id]
    user = User.find_by(id: user_id)
    
    unless user
      return render json: {
        error: 'Not Found',
        message: 'User not found'
      }, status: :not_found
    end

    # Check if user is already a member
    if @project.project_members.exists?(user: user)
      return render json: {
        error: 'Conflict',
        message: 'User is already a member of this project'
      }, status: :conflict
    end

    # Check if teacher can add this user (from their classes or allow other legitimate joins)
    unless can_add_user_to_project?(user)
      return render json: {
        error: 'Forbidden',
        message: 'You can only add students and class members from your classes to this project'
      }, status: :forbidden
    end

    # Create project member with default role
    project_member = @project.project_members.build(
      user: user,
      role: :member,
      status: :confirmed
    )

    if project_member.save
      render json: {
        message: 'User added to project successfully',
        data: {
          id: project_member.id,
          user: {
            id: user.id,
            full_name: user.full_name,
            email: user.email,
            role: user.role
          },
          role: project_member.role,
          status: project_member.status
        }
      }, status: :created
    else
      render json: { errors: project_member.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/teachers/projects/:id/members/:user_id
  # Remove a member from the project
  def remove_member
    user_id = params[:user_id]
    project_member = @project.project_members.find_by(user_id: user_id)

    unless project_member
      return render json: {
        error: 'Not Found',
        message: 'User is not a member of this project'
      }, status: :not_found
    end

    if project_member.destroy
      render json: {
        message: 'User removed from project successfully'
      }, status: :ok
    else
      render json: { errors: project_member.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/teachers/projects/:id/members
  # List project members
  def members
    @project_members = @project.project_members.includes(:user)
    
    render json: {
      data: @project_members.map do |member|
        {
          id: member.id,
          user: {
            id: member.user.id,
            full_name: member.user.full_name,
            email: member.user.email,
            role: member.user.role
          },
          role: member.role,
          status: member.status,
          created_at: member.created_at
        }
      end
    }
  end
  
  private
  
  def set_project
    @project = Project.find(params[:id])
  end
  
  def ensure_teacher_can_manage_project
    unless teacher_can_manage_project?(@project)
      render json: {
        error: 'Forbidden',
        message: 'You are not authorized to manage this project'
      }, status: :forbidden
    end
  end
  
  def project_params
    params.require(:project).permit(:title, :description, :start_date, :end_date, :participants_number, :private, :status, school_level_ids: [])
  end
  
  def teacher_can_manage_project?(project)
    # Teacher can manage if they own the project or if it's for a class they manage
    project.owner == current_user || 
    project.school_levels.any? { |school_level| teacher_can_manage_class?(school_level) }
  end
  
  def serialize_teacher_project(project, include_details: false)
    data = {
      id: project.id,
      title: project.title,
      description: project.description,
      status: project.status,
      private: project.private,
      participants_number: project.participants_number,
      created_at: project.created_at,
      updated_at: project.updated_at,
      owner: {
        id: project.owner.id,
        full_name: project.owner.full_name
      }
    }
    
    if project.school_levels.present?
      data[:school_levels] = project.school_levels.map do |school_level|
        school_data = {
          id: school_level.id,
          name: school_level.name,
          level: school_level.level
        }
        
        if school_level.school.present?
          school_data[:school] = {
            id: school_level.school.id,
            name: school_level.school.name
          }
        end
        
        school_data
      end
    end
    
    if include_details
      data[:project_members] = project.project_members.includes(:user).map do |member|
        {
          id: member.id,
          user: {
            id: member.user.id,
            full_name: member.user.full_name
          },
          role: member.role,
          joined_at: member.created_at
        }
      end
      
      data[:can_manage] = teacher_can_manage_project?(project)
    end
    
    data
  end

  private

  def can_add_user_to_project?(user)
    # Teachers can add students and class members from their classes
    # Also allow if it's a public project or user is from the organization
    return true if user_from_teacher_classes?(user)
    return true if @project.private == false  # Public project
    return true if user_from_project_organization?(user)
    
    false
  end

  def user_from_teacher_classes?(user)
    # Check if user is a student or class member from teacher's classes
    teacher_classes = current_user.assigned_classes
    user_school_levels = user.user_school_levels.where(school_level: teacher_classes)
    
    user_school_levels.exists? && ['children', 'voluntary', 'tutor'].include?(user.role)
  end

  def user_from_project_organization?(user)
    # Check if user is from the project's organization (school/company)
    project_organizations = @project.school_levels.map(&:school) + @project.companies
    
    project_organizations.any? do |org|
      case org
      when School
        user.schools.include?(org)
      when Company
        user.companies.include?(org)
      end
    end
  end
end
