# Company Branch Requests API controller
# Handles branch invitation/request workflow (superadmin only)
class Api::V1::Companies::BranchRequestsController < Api::V1::Companies::BaseController
  include Pagy::Backend
  
  before_action :ensure_superadmin
  before_action :set_branch_request, only: [:confirm, :reject, :destroy]
  
  # GET /api/v1/companys/:company_id/branch_requests
  # List all branch requests (sent + received)
  def index
    @requests = BranchRequest.for_organization(@company)
    
    # Filter by status
    @requests = @requests.where(status: params[:status]) if params[:status].present?
    
    # Filter by direction
    case params[:direction]
    when 'sent'
      @requests = @requests.where(initiator: @company)
    when 'received'
      @requests = @requests.where.not(initiator: @company)
    end
    
    @pagy, @requests = pagy(@requests.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: @requests.map { |req| serialize_branch_request(req) },
      meta: pagination_meta(@pagy)
    }
  end
  
  # POST /api/v1/companys/:company_id/branch_requests
  # Request to become a branch of another company
  def create
    if @company.branch?
      return render json: {
        error: 'Forbidden',
        message: 'Branch companys cannot create branch requests'
      }, status: :forbidden
    end
    
    parent_company = Company.find_by(id: params[:parent_company_id])
    
    unless parent_company
      return render json: {
        error: 'Not Found',
        message: 'Parent company not found'
      }, status: :not_found
    end
    
    # Use model method to create request
    branch_request = @company.request_to_become_branch_of(parent_company)
    
    if branch_request.persisted?
      # Send notification email to parent company admins
      BranchRequestMailer.branch_request_created(
        branch_request,
        parent_company
      ).deliver_later
      
      render json: {
        message: 'Branch request sent successfully',
        data: serialize_branch_request(branch_request)
      }, status: :created
    else
      render json: {
        error: 'Validation Failed',
        details: branch_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/companys/:company_id/branch_requests/:id/confirm
  # Accept branch request (recipient only)
  def confirm
    unless can_manage_request?(@branch_request)
      return render json: {
        error: 'Forbidden',
        message: 'Only the recipient can confirm this request'
      }, status: :forbidden
    end
    
    @branch_request.confirm!
    
    # Send confirmation email to initiator
    BranchRequestMailer.branch_request_confirmed(
      @branch_request,
      @branch_request.initiator
    ).deliver_later
    
    render json: {
      message: 'Branch request confirmed successfully',
      data: serialize_branch_request(@branch_request)
    }
  end
  
  # PATCH /api/v1/companys/:company_id/branch_requests/:id/reject
  # Reject branch request (recipient only)
  def reject
    unless can_manage_request?(@branch_request)
      return render json: {
        error: 'Forbidden',
        message: 'Only the recipient can reject this request'
      }, status: :forbidden
    end
    
    @branch_request.reject!
    
    # Send rejection email to initiator
    BranchRequestMailer.branch_request_rejected(
      @branch_request,
      @branch_request.initiator
    ).deliver_later
    
    render json: {
      message: 'Branch request rejected successfully',
      data: serialize_branch_request(@branch_request)
    }
  end
  
  # DELETE /api/v1/companys/:company_id/branch_requests/:id
  # Cancel branch request (initiator only, pending only)
  def destroy
    unless @branch_request.initiator == @company
      return render json: {
        error: 'Forbidden',
        message: 'Only the initiator can cancel this request'
      }, status: :forbidden
    end
    
    unless @branch_request.pending?
      return render json: {
        error: 'Bad Request',
        message: 'Only pending requests can be cancelled'
      }, status: :bad_request
    end
    
    if @branch_request.destroy
      render json: {
        message: 'Branch request cancelled successfully'
      }
    else
      render json: {
        error: 'Failed to cancel request',
        details: @branch_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_branch_request
    @branch_request = BranchRequest.for_organization(@company).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: 'Not Found',
      message: 'Branch request not found'
    }, status: :not_found
  end
  
  def can_manage_request?(request)
    request.recipient == @company && request.pending?
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
      initiator: request.initiated_by_parent? ? 'parent' : 'child',
      recipient: request.initiated_by_parent? ? 'child' : 'parent',
      status: request.status,
      confirmed_at: request.confirmed_at,
      created_at: request.created_at,
      updated_at: request.updated_at
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

