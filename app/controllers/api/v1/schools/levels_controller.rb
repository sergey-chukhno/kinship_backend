# School Levels (Classes) API controller
# Handles class management
class Api::V1::Schools::LevelsController < Api::V1::Schools::BaseController
  include Pagy::Backend
  
  before_action :set_level, only: [:update, :destroy, :students]
  
  # GET /api/v1/schools/:school_id/levels
  # List all school classes
  def index
    @levels = @school.school_levels.includes(:students, :teachers)
    
    # Filters
    @levels = @levels.where(level: params[:level]) if params[:level].present?
    
    # Search by name
    if params[:search].present?
      @levels = @levels.where("name ILIKE ?", "%#{params[:search]}%")
    end
    
    @pagy, @levels = pagy(@levels.order(level: :asc, name: :asc), items: params[:per_page] || 12)
    
    render json: {
      data: @levels.map { |level| serialize_level(level) },
      meta: pagination_meta(@pagy)
    }
  end
  
  # POST /api/v1/schools/:school_id/levels
  # Create a new class
  def create
    @level = @school.school_levels.build(level_params)
    
    if @level.save
      render json: {
        message: 'Class created successfully',
        data: serialize_level(@level)
      }, status: :created
    else
      render json: {
        error: 'Validation Failed',
        details: @level.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/schools/:school_id/levels/:id
  # Update class
  def update
    if @level.update(level_params)
      render json: {
        message: 'Class updated successfully',
        data: serialize_level(@level)
      }
    else
      render json: {
        error: 'Validation Failed',
        details: @level.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/schools/:school_id/levels/:id
  # Delete class
  def destroy
    if @level.destroy
      render json: {
        message: 'Class deleted successfully'
      }
    else
      render json: {
        error: 'Failed to delete class',
        details: @level.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # GET /api/v1/schools/:school_id/levels/:id/students
  # List students in class
  def students
    @students = @level.students.includes(:user_school_levels)
    
    @pagy, @students = pagy(@students, items: params[:per_page] || 20)
    
    render json: {
      data: @students.map { |student| serialize_student(student) },
      meta: pagination_meta(@pagy)
    }
  end
  
  private
  
  def set_level
    @level = @school.school_levels.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: 'Not Found',
      message: 'Class not found'
    }, status: :not_found
  end
  
  def level_params
    params.require(:level).permit(:name, :level)
  end
  
  def serialize_level(level)
    {
      id: level.id,
      name: level.name,
      level: level.level,
      students_count: level.students.count,
      teachers_count: level.teachers.count,
      projects_count: level.projects.count,
      created_at: level.created_at,
      updated_at: level.updated_at
    }
  end
  
  def serialize_student(student)
    {
      id: student.id,
      full_name: student.full_name,
      first_name: student.first_name,
      last_name: student.last_name,
      email: student.email,
      birthday: student.birthday,
      has_temporary_email: student.has_temporary_email || false,
      avatar_url: student.avatar.attached? ? 
        Rails.application.routes.url_helpers.rails_blob_url(student.avatar, only_path: false) : nil
    }
  end
  
  def pagination_meta(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.items
    }
  end
end

