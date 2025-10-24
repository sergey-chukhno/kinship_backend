# School Projects API controller
# Handles school project management
class Api::V1::Schools::ProjectsController < Api::V1::Schools::BaseController
  include Pagy::Backend
  
  # GET /api/v1/schools/:school_id/projects
  # List school projects (own + branch projects if main school)
  def index
    # School projects are accessed via school_levels, not a direct association
    if @school.main_school? && params[:include_branches] == 'true'
      # Main school can see branch projects
      branch_school_ids = @school.branch_schools.pluck(:id)
      @projects = Project.joins(:project_school_levels)
                        .joins('JOIN school_levels ON project_school_levels.school_level_id = school_levels.id')
                        .where('school_levels.school_id IN (?)', [@school.id] + branch_school_ids)
                        .distinct
    else
      # Branch school or main school without branch filter - only this school's projects
      @projects = Project.joins(:project_school_levels)
                        .joins('JOIN school_levels ON project_school_levels.school_level_id = school_levels.id')
                        .where('school_levels.school_id = ?', @school.id)
                        .distinct
    end
    
    @projects = @projects.includes(:owner, :skills, :tags, :school_levels, :companies)
    
    # Filters
    @projects = @projects.where(status: params[:status]) if params[:status].present?
    @projects = @projects.where(private: params[:private]) if params[:private].present?
    
    # Search by title
    if params[:search].present?
      @projects = @projects.where("title ILIKE ? OR description ILIKE ?", 
                                  "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    @pagy, @projects = pagy(@projects.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: ActiveModelSerializers::SerializableResource.new(@projects, each_serializer: ProjectSerializer).as_json,
      meta: pagination_meta(@pagy)
    }
  end
  
  # POST /api/v1/schools/:school_id/projects
  # Create a school project
  def create
    @project = Project.new(project_params)
    @project.owner = current_user
    @project.private ||= false
    @project.status ||= :in_progress
    
    # Validate: school_levels must belong to this school (or branches if enabled)
    if params[:project][:school_level_ids].present?
      school_level_ids = params[:project][:school_level_ids].map(&:to_i)
      
      if @school.main_school? && @school.share_members_with_branches?
        # Main school with member sharing can use own + branch classes
        valid_ids = @school.all_school_levels_including_branches.pluck(:id)
      else
        # Only this school's classes
        valid_ids = @school.school_levels.pluck(:id)
      end
      
      unless (school_level_ids - valid_ids).empty?
        return render json: {
          error: 'Forbidden',
          message: 'All school levels must belong to this school'
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
  
  private
  
  def project_params
    params.require(:project).permit(
      :title, :description, :start_date, :end_date, :private, :status,
      :participants_number, skill_ids: [], tag_ids: [], school_level_ids: [], company_ids: []
    )
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

