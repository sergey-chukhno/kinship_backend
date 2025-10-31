# Authentication endpoints for React frontend
# Handles login, logout, token refresh, registration, and current user retrieval
class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [:login, :register]
  
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
  
  # POST /api/v1/auth/register
  # Unified registration endpoint for all 4 user types
  # Accepts both application/json and multipart/form-data for file uploads (avatar, company_logo)
  # @param registration_type [String] One of: personal_user, teacher, school, company
  # @param user [Hash] User attributes (email, password, first_name, last_name, etc.)
  # @param avatar [File] Optional avatar file upload
  # @param company_logo [File] Optional company logo file upload (company registration only)
  # @param children_info [Array] Optional array of child info hashes (personal_user only)
  # @param school [Hash] Optional school attributes (school registration only)
  # @param company [Hash] Optional company attributes (company registration only)
  # @return [JSON] {message: String, email: String, requires_confirmation: Boolean, avatar_url: String, company_logo_url: String, warnings: Array}
  def register
    result = RegistrationService.new(registration_params).call
    
    if result[:success]
      response_data = {
        message: "Registration successful! Please check your email to confirm your account.",
        email: result[:user].email,
        requires_confirmation: true
      }
      
      # Include avatar_url if avatar was uploaded
      if result[:user].avatar.attached?
        response_data[:avatar_url] = result[:user].avatar_url
      end
      
      # Include company_logo_url if company logo was uploaded (company registration only)
      if result[:company]&.logo&.attached?
        response_data[:company_logo_url] = result[:company].logo_url
      end
      
      # Include file upload warnings if any
      if result[:file_warnings].present?
        response_data[:warnings] = result[:file_warnings]
      end
      
      render json: response_data, status: :created
    else
      render json: {
        error: "Validation failed",
        errors: result[:errors]
      }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Registration error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    render json: {
      error: "Registration failed",
      message: e.message
    }, status: :unprocessable_entity
  end
  
  private
  
  # Strong parameters for registration
  # Handles both application/json and multipart/form-data
  # File uploads (avatar, company_logo) are at top level in multipart/form-data
  def registration_params
    params.permit(
      :registration_type,
      :avatar,           # File upload for user avatar (optional)
      :company_logo,     # File upload for company logo (optional, company registration only)
      user: [
        :email, :password, :password_confirmation, :first_name, :last_name,
        :birthday, :role, :job, :take_trainee, :propose_workshop, :show_my_skills,
        :accept_privacy_policy
      ],
      availability: [:monday, :tuesday, :wednesday, :thursday, :friday, :other],
      skills: [skill_ids: [], sub_skill_ids: []],
      join_school_ids: [],
      join_company_ids: [],
      children_info: [
        :first_name, :last_name, :birthday, :school_id, :school_name, :class_id, :class_name
      ],
      school: [:name, :address, :city, :zip_code, :school_type, :referent_phone_number],
      company: [
        :name, :description, :company_type_id, :zip_code, :city,
        :siret_number, :email, :website, :referent_phone_number, :branch_request_to_company_id
      ]
    ).to_h
  end
end

