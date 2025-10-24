# School Partnerships API controller
# Handles partnership management with companies/schools (superadmin only)
class Api::V1::Schools::PartnershipsController < Api::V1::Schools::BaseController
  include Pagy::Backend
  
  before_action :ensure_superadmin
  before_action :set_partnership, only: [:update, :destroy]
  
  # GET /api/v1/schools/:school_id/partnerships
  # List all partnerships
  def index
    @partnerships = @school.partnerships.includes(:partnership_members)
    
    # Filters
    @partnerships = @partnerships.where(status: params[:status]) if params[:status].present?
    @partnerships = @partnerships.where(partnership_type: params[:partnership_type]) if params[:partnership_type].present?
    
    @pagy, @partnerships = pagy(@partnerships.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: @partnerships.map { |partnership| serialize_partnership(partnership) },
      meta: pagination_meta(@pagy)
    }
  end
  
  # POST /api/v1/schools/:school_id/partnerships
  # Create a new partnership
  def create
    # For Phase 5, we'll keep it simple - just list partnerships
    # Full partnership creation is complex and will be handled in a dedicated Partnerships API
    render json: {
      error: 'Not Implemented',
      message: 'Partnership creation will be available in a future update. Please use the web interface.'
    }, status: :not_implemented
  end
  
  # PATCH /api/v1/schools/:school_id/partnerships/:id
  # Update partnership settings
  def update
    if @partnership.update(partnership_params)
      render json: {
        message: 'Partnership updated successfully',
        data: serialize_partnership(@partnership)
      }
    else
      render json: {
        error: 'Validation Failed',
        details: @partnership.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/schools/:school_id/partnerships/:id
  # Leave/delete partnership
  def destroy
    if @partnership.destroy
      render json: {
        message: 'Partnership removed successfully'
      }
    else
      render json: {
        error: 'Failed to remove partnership',
        details: @partnership.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_partnership
    @partnership = @school.partnerships.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: 'Not Found',
      message: 'Partnership not found'
    }, status: :not_found
  end
  
  def partnership_params
    params.require(:partnership).permit(:share_members, :share_projects)
  end
  
  def serialize_partnership(partnership)
    partner_members = partnership.partnership_members.where.not(participant: @school)
    
    {
      id: partnership.id,
      partnership_type: partnership.partnership_type,
      status: partnership.status,
      share_members: partnership.share_members,
      share_projects: partnership.share_projects,
      partners: partner_members.map do |pm|
        {
          id: pm.participant.id,
          name: pm.participant.name,
          type: pm.participant_type,
          role_in_partnership: pm.role_in_partnership,
          member_status: pm.member_status
        }
      end,
      created_at: partnership.created_at,
      updated_at: partnership.updated_at
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

