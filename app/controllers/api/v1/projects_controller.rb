# Projects API controller for User Dashboard
# Handles project listing, CRUD, and join requests
class Api::V1::ProjectsController < Api::V1::BaseController
  include Pagy::Backend
  before_action :set_project, only: [:show, :update, :destroy, :join]
  skip_before_action :authenticate_api_user!, only: [:index, :show]
  
  # GET /api/v1/projects
  # Get all available projects (public + user's private projects)
  def index
    # Use Pundit scope: public + private from user's orgs
    @projects = current_user ? policy_scope(Project) : Project.where(private: false)
    @projects = @projects.includes(:owner, :skills, :tags, :teams, :school_levels)
    
    # Apply filters
    @projects = @projects.where(status: params[:status]) if params[:status].present?
    @projects = filter_by_parcours(@projects) if params[:parcours].present?
    @projects = filter_by_dates(@projects) if date_params_present?
    
    @pagy, @projects = pagy(@projects.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: ActiveModelSerializers::SerializableResource.new(@projects, each_serializer: ProjectSerializer).as_json,
      meta: pagination_meta(@pagy)
    }
  end
  
  # GET /api/v1/projects/:id
  # Get single project details
  def show
    authorize @project if current_user
    
    render json: @project, serializer: ProjectSerializer
  end
  
  # POST /api/v1/projects
  # Create new project
  def create
    @project = Project.new(project_params)
    @project.owner = current_user
    
    # Set defaults (user preference)
    @project.private ||= false  # Public by default
    @project.status ||= :in_progress  # In progress by default
    
    authorize @project
    
    # Verify organization permissions if school_levels or companies specified
    unless can_create_project_with_associations?
      return render json: {
        error: 'Forbidden',
        message: 'You must be admin or referent of the organization to create projects with their classes/members'
      }, status: :forbidden
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
  
  # PATCH /api/v1/projects/:id
  # Update project
  def update
    authorize @project
    
    if @project.update(project_params)
      render json: @project, serializer: ProjectSerializer
    else
      render json: {
        error: 'Validation Failed',
        details: @project.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/projects/:id
  # Delete project (owner only)
  def destroy
    authorize @project
    
    @project.destroy
    head :no_content
  end
  
  # POST /api/v1/projects/:id/join
  # Request to join project
  def join
    # Check if already member
    if @project.project_members.exists?(user: current_user)
      return render json: {
        error: 'Already a member',
        message: 'You are already a member of this project'
      }, status: :conflict
    end
    
    # Use service to handle complex join logic
    result = ProjectJoinService.new(
      project: @project,
      user: current_user
    ).call
    
    case result[:status]
    when :success
      render json: {
        message: 'Project join request created',
        project_member: result[:project_member]
      }, status: :created
      
    when :pending_org_approval
      render json: {
        message: 'Pending organization approval',
        detail: result[:detail]
      }, status: :accepted
      
    when :org_membership_required
      render json: {
        error: 'Organization membership required',
        detail: result[:detail],
        available_organizations: result[:available_organizations],
        next_step: 'Please join an organization first'
      }, status: :forbidden
      
    else
      render json: {
        error: 'Unable to join project',
        message: 'An unexpected error occurred'
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_project
    @project = Project.includes(:owner, :skills, :tags, :teams, :school_levels, :companies).find(params[:id])
  end
  
  def project_params
    params.require(:project).permit(
      :title, :description, :start_date, :end_date, :participants_number, :private, :status,
      school_level_ids: [], skill_ids: [], tag_ids: [], company_ids: []
    )
  end
  
  # Verify user can create project with specified associations
  def can_create_project_with_associations?
    # If no school_levels or companies, no org permission check needed
    return true if params[:project][:school_level_ids].blank? && params[:project][:company_ids].blank?
    
    # Check school_levels permissions
    if params[:project][:school_level_ids].present?
      school_level_ids = params[:project][:school_level_ids]
      school_ids = SchoolLevel.where(id: school_level_ids).pluck(:school_id).compact.uniq
      
      # User must be admin/referent/superadmin of ALL schools
      school_ids.each do |school_id|
        unless current_user.user_schools.exists?(
          school_id: school_id,
          role: [:referent, :admin, :superadmin],
          status: :confirmed
        )
          return false
        end
      end
    end
    
    # Check companies permissions
    if params[:project][:company_ids].present?
      company_ids = params[:project][:company_ids]
      
      # User must be admin/referent/superadmin of ALL companies
      company_ids.each do |company_id|
        unless current_user.user_company.exists?(
          company_id: company_id,
          role: [:referent, :admin, :superadmin],
          status: :confirmed
        )
          return false
        end
      end
    end
    
    true
  end
  
  # Filter by parcours (tag)
  def filter_by_parcours(projects)
    projects.joins(:project_tags).where(project_tags: {tag_id: params[:parcours]})
  end
  
  # Filter by dates
  def filter_by_dates(projects)
    projects = projects.where('start_date >= ?', params[:start_date_from]) if params[:start_date_from]
    projects = projects.where('start_date <= ?', params[:start_date_to]) if params[:start_date_to]
    projects = projects.where('end_date >= ?', params[:end_date_from]) if params[:end_date_from]
    projects = projects.where('end_date <= ?', params[:end_date_to]) if params[:end_date_to]
    projects
  end
  
  def date_params_present?
    params[:start_date_from] || params[:start_date_to] || params[:end_date_from] || params[:end_date_to]
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

