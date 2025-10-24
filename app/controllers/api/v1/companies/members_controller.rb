# Company Members API controller
# Handles company staff management
class Api::V1::Companies::MembersController < Api::V1::Companies::BaseController
  include Pagy::Backend
  
  # GET /api/v1/companies/:company_id/members
  # List all company members
  def index
    @members = @company.user_companies.includes(:user)
    
    # Filters
    @members = @members.where(status: params[:status]) if params[:status].present?
    @members = @members.where(role: params[:role]) if params[:role].present?
    
    # Search by name
    if params[:search].present?
      @members = @members.joins(:user).where(
        "users.first_name ILIKE ? OR users.last_name ILIKE ? OR users.email ILIKE ?",
        "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"
      )
    end
    
    @pagy, @members = pagy(@members.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: @members.map { |member| serialize_member(member) },
      meta: pagination_meta(@pagy)
    }
  end
  
  # POST /api/v1/companys/:company_id/members
  # Invite/add a member to company
  def create
    # Find user by email (existing) or create params (new user)
    user = find_or_identify_user
    
    return render json: user[:error], status: user[:status] if user[:error]
    
    existing_user = user[:user]
    is_new_user = user[:is_new]
    
    # Check if already a member
    if @company.user_companies.exists?(user: existing_user)
      return render json: {
        error: 'Conflict',
        message: 'User is already a member of this company'
      }, status: :conflict
    end
    
    # Validate role permissions
    requested_role = params[:role]&.to_sym || :member
    
    # Check superadmin creation rules
    if requested_role == :superadmin
      # Rule 1: Only superadmins can assign superadmin role
      unless @current_user_company.superadmin?
        return render json: {
          error: 'Forbidden',
          message: 'Only superadmins can assign the superadmin role'
        }, status: :forbidden
      end
      
      # Rule 2: Only ONE superadmin per company
      if @company.user_companies.exists?(role: :superadmin)
        return render json: {
          error: 'Forbidden',
          message: 'This company already has a superadmin. There can only be one superadmin per company.'
        }, status: :forbidden
      end
    end
    
    # Create membership
    user_company = @company.user_companies.build(
      user: existing_user,
      role: requested_role,
      status: :pending  # Always pending for invitation workflow
    )
    
    if user_company.save
      # Send appropriate notification based on user existence
      if is_new_user
        if existing_user.has_temporary_email?
          # TODO: Send claim link invitation
          # UserCompanyMailer.claim_invitation(user_company).deliver_later
        else
          # TODO: Send registration invitation (known email)
          # UserCompanyMailer.registration_invitation(user_company).deliver_later
        end
      else
        # TODO: Send membership notification (existing user)
        # UserCompanyMailer.membership_invitation(user_company).deliver_later
      end
      
      render json: {
        message: is_new_user ? 'Invitation sent successfully' : 'Member invited successfully',
        data: serialize_member(user_company),
        invitation_method: existing_user.has_temporary_email? ? 'claim_link' : 'email'
      }, status: :created
    else
      render json: {
        error: 'Validation Failed',
        details: user_company.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/companys/:company_id/members/:id
  # Update member role
  def update
    user = User.find(params[:id])
    user_company = @company.user_companies.find_by!(user: user)
    
    requested_role = params[:role]&.to_sym
    
    # Superadmin role management
    if requested_role == :superadmin
      # Rule 1: Only superadmins can assign superadmin role
      unless @current_user_company.superadmin?
        return render json: {
          error: 'Forbidden',
          message: 'Only superadmins can assign the superadmin role'
        }, status: :forbidden
      end
      
      # Rule 2: Only ONE superadmin per company
      existing_superadmin = @company.user_companies.find_by(role: :superadmin)
      if existing_superadmin && existing_superadmin != user_company
        return render json: {
          error: 'Forbidden',
          message: 'This company already has a superadmin. There can only be one superadmin per company.'
        }, status: :forbidden
      end
    end
    
    # Prevent modifying superadmin by non-superadmin
    if user_company.superadmin? && !@current_user_company.superadmin?
      return render json: {
        error: 'Forbidden',
        message: 'Only superadmins can modify superadmin role'
      }, status: :forbidden
    end
    
    if user_company.update(member_params)
      render json: {
        message: 'Member updated successfully',
        data: serialize_member(user_company)
      }
    else
      render json: {
        error: 'Validation Failed',
        details: user_company.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/companys/:company_id/members/:id
  # Remove member from company
  def destroy
    user = User.find(params[:id])
    user_company = @company.user_companies.find_by!(user: user)
    
    # Rule: Superadmin CANNOT be deleted
    if user_company.superadmin?
      return render json: {
        error: 'Forbidden',
        message: 'Superadmin cannot be removed from the company. Transfer superadmin role first.'
      }, status: :forbidden
    end
    
    # Only superadmin can remove other admins
    if user_company.admin? && !@current_user_company.superadmin?
      return render json: {
        error: 'Forbidden',
        message: 'Only superadmins can remove admins'
      }, status: :forbidden
    end
    
    if user_company.destroy
      render json: {
        message: 'Member removed successfully'
      }
    else
      render json: {
        error: 'Failed to remove member',
        details: user_company.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def member_params
    params.permit(:role, :status)
  end
  
  def find_or_identify_user
    # Try to find existing user by email
    if params[:email].present?
      existing_user = User.find_by(email: params[:email])
      
      if existing_user
        return { user: existing_user, is_new: false }
      else
        # Create new user with known email (will receive registration invitation)
        new_user = User.new(
          email: params[:email],
          first_name: params[:first_name] || 'New',
          last_name: params[:last_name] || 'Member',
          role: params[:user_role] || :voluntary,  # Default role for new users
          password: SecureRandom.hex(16),  # Temporary password
          confirmed_at: nil  # Will confirm via invitation link
        )
        
        if new_user.save(validate: false)  # Skip validation for invitation flow
          return { user: new_user, is_new: true }
        else
          return {
            error: {
              error: 'User Creation Failed',
              details: new_user.errors.full_messages
            },
            status: :unprocessable_entity
          }
        end
      end
    elsif params[:first_name].present? && params[:last_name].present? && params[:birthday].present?
      # Create user without email (temporary email + claim link)
      birthday = Date.parse(params[:birthday]) rescue nil
      
      unless birthday
        return {
          error: {
            error: 'Bad Request',
            message: 'Valid birthday is required for users without email'
          },
          status: :bad_request
        }
      end
      
      # Check for duplicate by name + birthday
      existing = User.where(
        first_name: params[:first_name],
        last_name: params[:last_name],
        birthday: birthday
      ).first
      
      if existing
        return {
          error: {
            error: 'Conflict',
            message: 'A user with this name and birthday already exists. Use their email instead.'
          },
          status: :conflict
        }
      end
      
      # Create user with temporary email
      temp_email = "temp_#{SecureRandom.hex(8)}@kinship-temp.local"
      claim_token = SecureRandom.urlsafe_base64(32)
      
      new_user = User.new(
        email: temp_email,
        first_name: params[:first_name],
        last_name: params[:last_name],
        birthday: birthday,
        role: params[:user_role] || :voluntary,
        password: SecureRandom.hex(16),
        has_temporary_email: true,
        claim_token: claim_token,
        confirmed_at: Time.current  # Auto-confirm temporary email accounts
      )
      
      if new_user.save(validate: false)
        return { user: new_user, is_new: true }
      else
        return {
          error: {
            error: 'User Creation Failed',
            details: new_user.errors.full_messages
          },
          status: :unprocessable_entity
        }
      end
    else
      return {
        error: {
          error: 'Bad Request',
          message: 'Either email OR (first_name + last_name + birthday) is required'
        },
        status: :bad_request
      }
    end
  end
  
  def serialize_member(user_company)
    user = user_company.user
    {
      id: user.id,
      full_name: user.full_name,
      first_name: user.first_name,
      last_name: user.last_name,
      email: user.email,
      has_temporary_email: user.has_temporary_email || false,
      claim_token: user.has_temporary_email ? user.claim_token : nil,
      role_in_system: user.role,
      role_in_company: user_company.role,
      status: user_company.status,
      avatar_url: user.avatar.attached? ? 
        Rails.application.routes.url_helpers.rails_blob_url(user.avatar, only_path: false) : nil,
      joined_at: user_company.created_at
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

