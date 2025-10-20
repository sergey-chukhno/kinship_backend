# Authentication endpoints for React frontend
# Handles login, logout, token refresh, and current user retrieval
class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [:login]
  
  # POST /api/v1/auth/login
  # Login with email and password, returns JWT token + user with contexts
  # @param email [String] User email
  # @param password [String] User password
  # @return [JSON] {token: String, user: UserSerializer}
  def login
    user = User.find_by(email: params[:email])
    
    if user&.valid_password?(params[:password])
      if user.confirmed?
        token = JsonWebToken.encode(user_id: user.id)
        
        render json: {
          token: token,
          user: UserSerializer.new(user, include_contexts: true).as_json
        }, status: :ok
      else
        render json: { 
          error: 'Email not confirmed',
          message: 'Please confirm your email address before logging in'
        }, status: :unauthorized
      end
    else
      render json: { 
        error: 'Invalid credentials',
        message: 'Email or password is incorrect'
      }, status: :unauthorized
    end
  end
  
  # DELETE /api/v1/auth/logout
  # Logout current user (client-side token removal)
  # Future enhancement: Add token to blacklist in Redis
  def logout
    # For now, just return success (token removal handled client-side)
    # Future: Implement token blacklist using Redis
    # TokenBlacklist.create(token: request.headers['Authorization'], expires_at: Time.current + 24.hours)
    head :no_content
  end
  
  # POST /api/v1/auth/refresh
  # Refresh JWT token (extend expiration to 24 hours from now)
  # @return [JSON] {token: String}
  def refresh
    token = JsonWebToken.encode(user_id: current_user.id)
    render json: { token: token }, status: :ok
  end
  
  # GET /api/v1/auth/me
  # Get current authenticated user with full context information
  # @return [JSON] UserSerializer with contexts, badges, skills, availability
  def me
    render json: current_user, 
           serializer: UserSerializer,
           include_contexts: true,
           include_badges: true,
           include_skills: true,
           include_availability: true
  end
end

