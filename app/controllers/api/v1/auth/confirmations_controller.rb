# Email confirmation API controller
# Handles email confirmation for API (React frontend)
# Migrated from web version - fully API-based
class Api::V1::Auth::ConfirmationsController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [:show]
  
  # GET /api/v1/auth/confirmation?confirmation_token=abcdef
  # Confirm user email address
  # Auto-confirms schools/companies if user is superadmin (school/company registration)
  # @param confirmation_token [String] Token from confirmation email
  # @return [JSON] {message: String, confirmed: Boolean}
  def show
    user = User.confirm_by_token(params[:confirmation_token])
    
    if user.errors.empty?
      # Reload user to ensure associations are fresh
      user.reload
      # Auto-confirm organizations if user is superadmin
      confirm_associated_organizations!(user)
      
      render json: {
        message: 'Email confirmed successfully',
        confirmed: true,
        email: user.email
      }, status: :ok
    else
      render json: {
        error: 'Confirmation Failed',
        message: user.errors.full_messages.join(', '),
        confirmed: false
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  # Auto-confirm schools and companies when user confirms email
  # Only applies to superadmin users (school/company registration)
  def confirm_associated_organizations!(user)
    # Confirm UserSchool if user is superadmin (school registration)
    user.user_schools.where(role: :superadmin, status: :pending).each do |us|
      us.update!(status: :confirmed)
      # Also confirm the school if it's pending (reload UserSchool to clear association cache)
      us.reload
      school = School.find(us.school_id)
      school.update!(status: :confirmed) if school.pending?
    end
    
    # Confirm UserCompany if user is superadmin (company registration)
    user.user_company.where(role: :superadmin, status: :pending).each do |uc|
      uc.update!(status: :confirmed)
      # Company is already confirmed during registration, no need to update
    end
  end
end

