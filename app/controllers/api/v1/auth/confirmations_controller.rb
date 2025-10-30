# Email confirmation API controller
# Handles email confirmation for API (React frontend)
# Migrated from web version - fully API-based
class Api::V1::Auth::ConfirmationsController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [:show]
  
  # GET /api/v1/auth/confirmation?confirmation_token=abcdef
  # Confirm user email address
  # @param confirmation_token [String] Token from confirmation email
  # @return [JSON] {message: String, confirmed: Boolean}
  def show
    user = User.confirm_by_token(params[:confirmation_token])
    
    if user.errors.empty?
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
end

