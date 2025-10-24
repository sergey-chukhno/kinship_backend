# School Partnerships API controller
# Handles partnership management with companies/schools (superadmin only)
class Api::V1::Schools::PartnershipsController < Api::V1::Schools::BaseController
  include Pagy::Backend
  
  before_action :ensure_superadmin
  before_action :set_partnership, only: [:update, :destroy, :confirm, :reject]
  
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
  # Create a new partnership (initiate partnership request)
  def create
    partnership_type = params[:partnership_type] || 'bilateral'
    partner_ids = Array(params[:partner_school_ids]) + Array(params[:partner_company_ids])
    
    if partner_ids.empty?
      return render json: {
        error: 'Validation Failed',
        message: 'At least one partner organization is required'
      }, status: :unprocessable_entity
    end
    
    ActiveRecord::Base.transaction do
      # Create partnership
      @partnership = Partnership.new(
        initiator: @school,
        partnership_type: partnership_type,
        name: params[:name],
        description: params[:description],
        share_members: params[:share_members] || false,
        share_projects: params[:share_projects] || false,
        has_sponsorship: params[:has_sponsorship] || false,
        status: :pending
      )
      
      unless @partnership.save
        return render json: {
          error: 'Validation Failed',
          details: @partnership.errors.full_messages
        }, status: :unprocessable_entity
      end
      
      # Add initiating school as confirmed member
      PartnershipMember.create!(
        partnership: @partnership,
        participant: @school,
        role_in_partnership: params[:initiator_role] || :partner,
        member_status: :confirmed,
        confirmed_at: Time.current
      )
      
      # Add partner schools and send emails
      Array(params[:partner_school_ids]).each do |school_id|
        partner_school = School.find(school_id)
        PartnershipMember.create!(
          partnership: @partnership,
          participant: partner_school,
          role_in_partnership: params[:partner_role] || :partner,
          member_status: :pending
        )
        
        # Send email notification
        PartnershipMailer.partnership_request_created(
          @partnership,
          partner_school
        ).deliver_later
      end
      
      # Add partner companies and send emails
      Array(params[:partner_company_ids]).each do |company_id|
        partner_company = Company.find(company_id)
        PartnershipMember.create!(
          partnership: @partnership,
          participant: partner_company,
          role_in_partnership: params[:partner_role] || :partner,
          member_status: :pending
        )
        
        # Send email notification
        PartnershipMailer.partnership_request_created(
          @partnership,
          partner_company
        ).deliver_later
      end
      
      render json: {
        message: 'Partnership request created successfully',
        data: serialize_partnership(@partnership)
      }, status: :created
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: {
      error: 'Not Found',
      message: 'Partner organization not found'
    }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      error: 'Validation Failed',
      details: e.record.errors.full_messages
    }, status: :unprocessable_entity
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
  
  # PATCH /api/v1/schools/:school_id/partnerships/:id/confirm
  # Confirm partnership request (accept invitation)
  def confirm
    # Find the school's membership in this partnership
    partnership_member = @partnership.partnership_members.find_by(
      participant: @school,
      member_status: :pending
    )
    
    unless partnership_member
      return render json: {
        error: 'Bad Request',
        message: 'No pending partnership request found for this school'
      }, status: :bad_request
    end
    
    ActiveRecord::Base.transaction do
      partnership_member.confirm!
      
      # Send confirmation email to initiator
      PartnershipMailer.partnership_confirmed(
        @partnership,
        @school,
        @partnership.initiator
      ).deliver_later
      
      render json: {
        message: 'Partnership confirmed successfully',
        data: serialize_partnership(@partnership.reload)
      }
    end
  rescue => e
    render json: {
      error: 'Confirmation Failed',
      message: e.message
    }, status: :unprocessable_entity
  end
  
  # PATCH /api/v1/schools/:school_id/partnerships/:id/reject
  # Reject partnership request (decline invitation)
  def reject
    # Find the school's membership in this partnership
    partnership_member = @partnership.partnership_members.find_by(
      participant: @school,
      member_status: :pending
    )
    
    unless partnership_member
      return render json: {
        error: 'Bad Request',
        message: 'No pending partnership request found for this school'
      }, status: :bad_request
    end
    
    ActiveRecord::Base.transaction do
      partnership_member.decline!
      
      # Send rejection email to initiator
      PartnershipMailer.partnership_rejected(
        @partnership,
        @school,
        @partnership.initiator
      ).deliver_later
      
      render json: {
        message: 'Partnership request rejected'
      }
    end
  rescue => e
    render json: {
      error: 'Rejection Failed',
      message: e.message
    }, status: :unprocessable_entity
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

