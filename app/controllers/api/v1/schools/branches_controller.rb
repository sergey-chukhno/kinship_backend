# School Branches API controller
# Handles branch school management (superadmin only)
class Api::V1::Schools::BranchesController < Api::V1::Schools::BaseController
  include Pagy::Backend
  
  before_action :ensure_superadmin
  
  # GET /api/v1/schools/:school_id/branches
  # List all branch schools
  def index
    unless @school.main_school?
      return render json: {
        error: 'Bad Request',
        message: 'Only main schools can have branches'
      }, status: :bad_request
    end
    
    @branches = @school.branch_schools.includes(:user_schools, :school_levels)
    
    @pagy, @branches = pagy(@branches.order(name: :asc), items: params[:per_page] || 12)
    
    render json: {
      data: @branches.map { |branch| serialize_branch(branch) },
      meta: {
        **pagination_meta(@pagy),
        share_members_with_branches: @school.share_members_with_branches
      }
    }
  end
  
  # POST /api/v1/schools/:school_id/branches/invite
  # Invite another school to become a branch
  def invite
    unless @school.main_school?
      return render json: {
        error: 'Forbidden',
        message: 'Only main schools can invite branches'
      }, status: :forbidden
    end
    
    child_school = School.find_by(id: params[:child_school_id])
    
    unless child_school
      return render json: {
        error: 'Not Found',
        message: 'Target school not found'
      }, status: :not_found
    end
    
    # Use model method to create branch request
    branch_request = @school.invite_as_branch(child_school)
    
    if branch_request.persisted?
      # TODO: Send notification email
      # BranchRequestMailer.invitation(branch_request).deliver_later
      
      render json: {
        message: 'Branch invitation sent successfully',
        data: serialize_branch_request(branch_request)
      }, status: :created
    else
      render json: {
        error: 'Validation Failed',
        details: branch_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/schools/:school_id/branches/settings
  # Update branch settings (e.g., member sharing)
  def settings
    unless @school.main_school?
      return render json: {
        error: 'Forbidden',
        message: 'Only main schools can manage branch settings'
      }, status: :forbidden
    end
    
    if @school.update(branch_settings_params)
      render json: {
        message: 'Branch settings updated successfully',
        data: {
          share_members_with_branches: @school.share_members_with_branches
        }
      }
    else
      render json: {
        error: 'Validation Failed',
        details: @school.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def branch_settings_params
    params.permit(:share_members_with_branches)
  end
  
  def serialize_branch(branch)
    {
      id: branch.id,
      name: branch.name,
      city: branch.city,
      zip_code: branch.zip_code,
      school_type: branch.school_type,
      members_count: branch.users.count,
      levels_count: branch.school_levels.count,
      projects_count: branch.projects.count,
      created_at: branch.created_at
    }
  end
  
  def serialize_branch_request(request)
    {
      id: request.id,
      parent_school: {
        id: request.parent.id,
        name: request.parent.name
      },
      child_school: {
        id: request.child.id,
        name: request.child.name
      },
      initiator_type: request.initiator_type,
      status: request.status,
      created_at: request.created_at
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

