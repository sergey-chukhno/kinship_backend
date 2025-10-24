# Company Branches API controller
# Handles branch company management (superadmin only)
class Api::V1::Companies::BranchesController < Api::V1::Companies::BaseController
  include Pagy::Backend
  
  before_action :ensure_superadmin
  
  # GET /api/v1/companys/:company_id/branches
  # List all branch companys
  def index
    unless @company.main_company?
      return render json: {
        error: 'Bad Request',
        message: 'Only main companys can have branches'
      }, status: :bad_request
    end
    
    @branches = @company.branch_companies.includes(:user_companys, :company_levels)
    
    @pagy, @branches = pagy(@branches.order(name: :asc), items: params[:per_page] || 12)
    
    render json: {
      data: @branches.map { |branch| serialize_branch(branch) },
      meta: {
        **pagination_meta(@pagy),
        share_members_with_branches: @company.share_members_with_branches
      }
    }
  end
  
  # POST /api/v1/companys/:company_id/branches/invite
  # Invite another company to become a branch
  def invite
    unless @company.main_company?
      return render json: {
        error: 'Forbidden',
        message: 'Only main companys can invite branches'
      }, status: :forbidden
    end
    
    child_company = Company.find_by(id: params[:child_company_id])
    
    unless child_company
      return render json: {
        error: 'Not Found',
        message: 'Target company not found'
      }, status: :not_found
    end
    
    # Use model method to create branch request
    branch_request = @company.invite_as_branch(child_company)
    
    if branch_request.persisted?
      # Send notification email to child company
      BranchRequestMailer.branch_request_created(
        branch_request,
        child_company
      ).deliver_later
      
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
  
  # PATCH /api/v1/companys/:company_id/branches/settings
  # Update branch settings (e.g., member sharing)
  def settings
    unless @company.main_company?
      return render json: {
        error: 'Forbidden',
        message: 'Only main companys can manage branch settings'
      }, status: :forbidden
    end
    
    if @company.update(branch_settings_params)
      render json: {
        message: 'Branch settings updated successfully',
        data: {
          share_members_with_branches: @company.share_members_with_branches
        }
      }
    else
      render json: {
        error: 'Validation Failed',
        details: @company.errors.full_messages
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
      company_type: branch.company_type,
      members_count: branch.users.count,
      levels_count: branch.company_levels.count,
      projects_count: branch.projects.count,
      created_at: branch.created_at
    }
  end
  
  def serialize_branch_request(request)
    {
      id: request.id,
      parent_company: {
        id: request.parent.id,
        name: request.parent.name
      },
      child_company: {
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

