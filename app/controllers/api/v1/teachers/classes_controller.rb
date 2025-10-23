class Api::V1::Teachers::ClassesController < Api::V1::Teachers::BaseController
  include Pagy::Backend
  before_action :set_class, only: [:show, :update, :transfer, :destroy]
  
  # GET /api/v1/teachers/classes
  def index
    # Get classes where teacher is creator OR assigned
    @classes = SchoolLevel
      .left_joins(:teacher_school_levels)
      .where('teacher_school_levels.user_id = ?', current_user.id)
      .distinct
      .includes(:school, :teachers, :students)
    
    # Filters
    @classes = @classes.where(school_id: params[:school_id]) if params[:school_id]
    @classes = @classes.where(school_id: nil) if params[:is_independent] == 'true'
    @classes = @classes.where.not(school_id: nil) if params[:is_independent] == 'false'
    @classes = @classes.where(level: params[:level]) if params[:level]
    
    @pagy, @classes = pagy(@classes.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: @classes.map { |c| serialize_teacher_class(c) },
      meta: pagination_meta(@pagy)
    }
  end
  
  # GET /api/v1/teachers/classes/:id
  def show
    unless teacher_can_manage_class?(@class)
      return render json: { 
        error: 'Forbidden',
        message: 'You can only view classes you created or are assigned to'
      }, status: :forbidden
    end
    
    render json: serialize_teacher_class(@class, include_students: true)
  end
  
  # POST /api/v1/teachers/classes
  def create
    @class = SchoolLevel.new(class_params)
    @class.school_id = nil  # Independent class
    
    if @class.save
      # Create teacher assignment (is_creator = true)
      TeacherSchoolLevel.create!(
        user: current_user,
        school_level: @class,
        is_creator: true
      )
      
      render json: serialize_teacher_class(@class), status: :created
    else
      render json: { 
        error: 'Validation Failed',
        details: @class.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/teachers/classes/:id
  def update
    unless teacher_can_manage_class?(@class)
      return render json: { 
        error: 'Forbidden',
        message: 'You can only update classes you created or are assigned to'
      }, status: :forbidden
    end
    
    if @class.update(class_params)
      render json: serialize_teacher_class(@class)
    else
      render json: { 
        error: 'Validation Failed',
        details: @class.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/teachers/classes/:id/transfer
  def transfer
    # Validation 1: Must be creator
    unless @class.created_by?(current_user)
      return render json: { 
        error: 'Forbidden',
        message: 'Only the class creator can transfer it to a school'
      }, status: :forbidden
    end
    
    # Validation 2: Must be independent
    if @class.school_id.present?
      return render json: { 
        error: 'Bad Request',
        message: 'This class already belongs to a school'
      }, status: :bad_request
    end
    
    # Validation 3: Teacher must be member of target school
    school = School.find(params[:school_id])
    unless current_user.user_schools.confirmed.exists?(school: school)
      return render json: { 
        error: 'Forbidden',
        message: 'You must be a confirmed member of the school to transfer classes to it'
      }, status: :forbidden
    end
    
    # Transfer
    @class.update!(school_id: school.id)
    
    # Ensure teacher assignment exists
    TeacherSchoolLevel.find_or_create_by!(
      user: current_user,
      school_level: @class,
      is_creator: true
    )
    
    render json: {
      **serialize_teacher_class(@class),
      message: "Class successfully transferred to #{school.name}",
      transferred_at: Time.current
    }
  end
  
  # DELETE /api/v1/teachers/classes/:id
  def destroy
    # Validation 1: Must be creator
    unless @class.created_by?(current_user)
      return render json: { 
        error: 'Forbidden',
        message: 'Only the class creator can delete it'
      }, status: :forbidden
    end
    
    # Validation 2: Must be independent
    if @class.school_id.present?
      return render json: { 
        error: 'Forbidden',
        message: 'Cannot delete school-owned classes. Please contact school admin.'
      }, status: :forbidden
    end
    
    @class.destroy
    head :no_content
  end
  
  private
  
  def set_class
    @class = SchoolLevel.find(params[:id])
  end
  
  def class_params
    params.require(:class).permit(:name, :level)
  end
  
  def serialize_teacher_class(school_level, include_students: false)
    data = {
      id: school_level.id,
      name: school_level.name,
      level: school_level.level,
      school_id: school_level.school_id,
      school: school_level.school ? {
        id: school_level.school.id,
        name: school_level.school.name,
        city: school_level.school.city
      } : nil,
      is_independent: school_level.school_id.nil?,
      is_creator: school_level.created_by?(current_user),
      is_assigned: current_user.teacher_school_levels.exists?(school_level: school_level),
      students_count: school_level.students.count,
      teachers_count: school_level.teachers.count,
      created_at: school_level.created_at
    }
    
    if include_students
      data[:students] = school_level.students.map do |student|
        {
          id: student.id,
          full_name: student.full_name,
          email: student.email,
          role: student.role,
          has_temporary_email: student.has_temporary_email?,
          status: student.has_temporary_email? ? 'pending_claim' : 'active',
          avatar_url: student.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_path(student.avatar, only_path: true) : nil
        }
      end
      
      data[:teachers] = school_level.teachers.map do |teacher|
        {
          id: teacher.id,
          full_name: teacher.full_name,
          is_creator: school_level.created_by?(teacher)
        }
      end
      
      data[:projects] = school_level.projects.map do |project|
        {
          id: project.id,
          title: project.title,
          status: project.status,
          created_at: project.created_at
        }
      end
    end
    
    data
  end
end
