class Api::V1::Account::ClaimController < Api::V1::BaseController
  # No authentication required - public endpoints
  skip_before_action :authenticate_api_user!
  
  # GET /api/v1/account/claim/info
  def info
    token = params[:token]
    
    unless token.present?
      return render json: {
        error: 'Bad Request',
        message: 'Claim token is required'
      }, status: :bad_request
    end
    
    user = User.find_by(claim_token: token, has_temporary_email: true)
    
    unless user
      return render json: {
        error: 'Not Found',
        message: 'Invalid or expired claim token'
      }, status: :not_found
    end
    
    # Get class and teacher info
    class_level = user.school_levels.first
    teacher = class_level&.creator
    
    render json: {
      student: {
        first_name: user.first_name,
        last_name: user.last_name,
        full_name: user.full_name
      },
      class: class_level ? {
        id: class_level.id,
        name: class_level.name,
        level: class_level.level
      } : nil,
      teacher: teacher ? {
        full_name: teacher.full_name
      } : nil,
      school: class_level&.school ? {
        name: class_level.school.name
      } : nil,
      created_at: user.created_at
    }
  end
  
  # POST /api/v1/account/claim
  def create
    token = params[:claim_token]
    email = params[:email]
    password = params[:password]
    password_confirmation = params[:password_confirmation]
    birthday_verification = params[:birthday]
    
    # Validate required fields
    unless token.present? && email.present? && password.present? && birthday_verification.present?
      return render json: {
        error: 'Bad Request',
        message: 'All fields are required: claim_token, email, password, birthday'
      }, status: :bad_request
    end
    
    # Validate password confirmation
    unless password == password_confirmation
      return render json: {
        error: 'Validation Failed',
        message: 'Password and password confirmation do not match'
      }, status: :unprocessable_entity
    end
    
    # Validate password strength
    unless password.match?(/\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}\z/)
      return render json: {
        error: 'Validation Failed',
        message: 'Password must be at least 8 characters with uppercase, lowercase, and number'
      }, status: :unprocessable_entity
    end
    
    # Find user by token
    user = User.find_by(claim_token: token, has_temporary_email: true)
    
    unless user
      return render json: {
        error: 'Not Found',
        message: 'Invalid or expired claim token'
      }, status: :not_found
    end
    
    # Verify birthday
    unless user.birthday == Date.parse(birthday_verification)
      return render json: {
        error: 'Birthday verification failed',
        message: 'The birthday you provided does not match our records'
      }, status: :unprocessable_entity
    end
    
    # Check if email is already taken
    if User.exists?(email: email)
      return render json: {
        error: 'Email already taken',
        message: 'This email address is already registered'
      }, status: :unprocessable_entity
    end
    
    # Claim the account
    if user.claim_account!(email, password, Date.parse(birthday_verification))
      render json: {
        message: 'Account claimed successfully!',
        email: email,
        confirmation_required: true,
        next_step: 'Please check your email to confirm your address'
      }
    else
      render json: {
        error: 'Claim failed',
        message: 'Unable to claim account. Please try again.',
        details: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
end
