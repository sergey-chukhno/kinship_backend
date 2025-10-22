# Base controller for all API v1 endpoints
# Provides authentication, authorization, and standardized error handling
class Api::V1::BaseController < ActionController::API
  include Pundit::Authorization
  
  before_action :authenticate_api_user!
  
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from Pundit::NotAuthorizedError, with: :forbidden
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :bad_request
  
  private
  
  # Authenticate user from JWT token or session (hybrid mode for gradual migration)
  # @return [User, nil] Authenticated user or nil
  def authenticate_api_user!
    @current_user = authenticate_from_token || authenticate_from_session
    
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end
  
  # Authenticate from JWT token in Authorization header
  # @return [User, nil] User from valid JWT token or nil
  def authenticate_from_token
    token = request.headers['Authorization']&.split(' ')&.last
    return nil unless token
    
    decoded = JsonWebToken.decode(token)
    return nil unless decoded
    
    User.find_by(id: decoded[:user_id])
  end
  
  # Authenticate from Devise session (for hybrid mode during migration)
  # @return [User, nil] User from session or nil
  def authenticate_from_session
    warden.authenticate(scope: :user)
  end
  
  # Current authenticated user
  # @return [User] Current user
  def current_user
    @current_user
  end
  
  # Standard error response handlers
  
  # Handle 404 Not Found errors
  def not_found(exception)
    render json: { 
      error: 'Not Found',
      message: exception.message 
    }, status: :not_found
  end
  
  # Handle 403 Forbidden errors (Pundit authorization failures)
  def forbidden(exception)
    render json: { 
      error: 'Forbidden',
      message: 'You are not authorized to perform this action'
    }, status: :forbidden
  end
  
  # Handle 422 Unprocessable Entity errors (validation failures)
  def unprocessable_entity(exception)
    render json: { 
      error: 'Validation Failed',
      details: exception.record.errors.full_messages 
    }, status: :unprocessable_entity
  end
  
  # Handle 400 Bad Request errors (missing parameters)
  def bad_request(exception)
    render json: { 
      error: 'Bad Request',
      message: exception.message 
    }, status: :bad_request
  end
end

