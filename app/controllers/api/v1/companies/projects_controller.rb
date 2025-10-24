# Company Projects API controller
# Handles company project management
class Api::V1::Companies::ProjectsController < Api::V1::Companies::BaseController
  include Pagy::Backend
  
  # GET /api/v1/companies/:company_id/projects
  # List company projects (own + branch projects if main company)
  def index
    # Company projects are accessed via direct association (project_companies)
    if @company.main_company? && params[:include_branches] == 'true'
      # Main company can see all projects (own + branches)
      @projects = @company.all_projects_including_branches
    else
      # Branch company or main company without branch filter - only this company's projects
      @projects = @company.projects
    end
    
    @projects = @projects.includes(:owner, :skills, :tags, :companies)
    
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
  
  # POST /api/v1/companies/:company_id/projects
  # Create a company project
  def create
    # Check permissions (referent, admin, superadmin can create projects)
    unless @current_user_company.can_create_project?
      return render json: {
        error: 'Forbidden',
        message: 'You do not have permission to create projects for this company'
      }, status: :forbidden
    end
    
    @project = Project.new(project_params)
    @project.owner = current_user
    @project.private ||= false
    @project.status ||= :in_progress
    
    # Associate with the company via company_ids
    if params[:project][:company_ids].blank?
      # Default: associate with current company only
      @project.company_ids = [@company.id]
    else
      # Validate company access
      requested_company_ids = params[:project][:company_ids].map(&:to_i)
      
      # Always ensure the current company is included
      unless requested_company_ids.include?(@company.id)
        requested_company_ids << @company.id
      end
      
      @project.company_ids = requested_company_ids
    end
    
    if @project.save
      render json: {
        message: 'Project created successfully',
        data: ActiveModelSerializers::SerializableResource.new(@project, serializer: ProjectSerializer).as_json
      }, status: :created
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
      :title, :description, :start_date, :end_date, :status, :private, :participants_number,
      skill_ids: [], tag_ids: [], company_ids: []
    )
  end
end
