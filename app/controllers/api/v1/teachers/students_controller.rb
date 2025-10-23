class Api::V1::Teachers::StudentsController < Api::V1::Teachers::BaseController
  include Pagy::Backend
  
  before_action :set_class, only: [:index, :create]
  before_action :set_student, only: [:destroy, :regenerate_claim, :update_email]
  
  # GET /api/v1/teachers/classes/:class_id/students
  def index
    unless teacher_can_manage_class?(@class)
      return render json: { error: 'Forbidden' }, status: :forbidden
    end
    
    @students = @class.students
    
    # Filters
    @students = @students.where("CONCAT(first_name, ' ', last_name) ILIKE ?", "%#{params[:search]}%") if params[:search]
    @students = @students.where(has_temporary_email: params[:has_email] == 'true') if params[:has_email]
    
    @pagy, @students = pagy(@students.order(:first_name, :last_name), items: params[:per_page] || 12)
    
    render json: {
      data: @students.map { |s| serialize_student(s) },
      meta: {
        **pagination_meta(@pagy),
        total_count: @students.count,
        active_accounts: @students.where(has_temporary_email: false).count,
        pending_claims: @students.where(has_temporary_email: true).count
      }
    }
  end
  
  # POST /api/v1/teachers/classes/:class_id/students
  def create
    unless teacher_can_manage_class?(@class)
      return render json: { error: 'Forbidden' }, status: :forbidden
    end
    
    # Validate role
    unless params[:student][:role].in?(['children', 'tutor', 'voluntary'])
      return render json: {
        error: 'Invalid Role',
        message: 'Student role must be children, tutor, or voluntary'
      }, status: :bad_request
    end
    
    if params[:student][:email].present?
      create_student_with_email
    else
      create_student_with_temporary_email
    end
  end
  
  # DELETE /api/v1/teachers/classes/:class_id/students/:id
  def destroy
    unless student_in_teacher_classes?(@student)
      return render json: { error: 'Forbidden' }, status: :forbidden
    end
    
    # Remove from class
    UserSchoolLevel.where(user: @student, school_level: @class).destroy_all
    
    head :no_content
  end
  
  # POST /api/v1/teachers/students/:id/regenerate-claim
  def regenerate_claim
    unless student_in_teacher_classes?(@student)
      return render json: { error: 'Forbidden' }, status: :forbidden
    end
    
    unless @student.has_temporary_email?
      return render json: {
        error: 'Bad Request',
        message: 'Student already has a confirmed email'
      }, status: :bad_request
    end
    
    @student.generate_claim_token!
    
    render json: {
      claim_token: @student.claim_token,
      claim_url: claim_url(@student.claim_token),
      message: 'New claim link generated. Previous link is now invalid.'
    }
  end
  
  # PATCH /api/v1/teachers/students/:id/update-email
  def update_email
    unless student_in_teacher_classes?(@student)
      return render json: { error: 'Forbidden' }, status: :forbidden
    end
    
    unless @student.has_temporary_email?
      return render json: {
        error: 'Bad Request',
        message: 'Student already has a confirmed email'
      }, status: :bad_request
    end
    
    @student.email = params[:email]
    @student.has_temporary_email = false
    @student.claim_token = nil
    @student.confirmed_at = nil
    
    if @student.save
      @student.send_confirmation_instructions
      render json: { 
        message: 'Email updated. Confirmation sent to new address.'
      }
    else
      render json: { errors: @student.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_class
    @class = SchoolLevel.find(params[:class_id])
  end
  
  def set_student
    @student = User.find(params[:id])
    @class = SchoolLevel.find(params[:class_id]) if params[:class_id]
  end
  
  def student_params
    params.require(:student).permit(:first_name, :last_name, :email, :birthday, :role, :role_additional_information, :accept_privacy_policy)
  end
  
  def create_student_with_email
    # Check if user exists
    existing_user = User.find_by(email: params[:student][:email])
    
    if existing_user
      # Link existing user to class
      link_student_to_class(existing_user)
      render json: {
        id: existing_user.id,
        full_name: existing_user.full_name,
        email: existing_user.email,
        has_temporary_email: false,
        account_status: 'existing_user_linked',
        message: "Existing user linked to class"
      }, status: :created
    else
      # Create new user
      student = User.new(student_params)
      student.password = SecureRandom.hex(16)
      student.confirmed_at = nil  # Will confirm via email
      student.role_additional_information = "Student created by teacher"
      student.accept_privacy_policy = true
      
      if student.save
        # Link to class
        link_student_to_class(student)
        
        # Send welcome email with password reset
        student.send_reset_password_instructions
        
        render json: {
          id: student.id,
          full_name: student.full_name,
          email: student.email,
          has_temporary_email: false,
          account_status: 'welcome_email_sent',
          message: "Student added. Welcome email sent to #{student.email}"
        }, status: :created
      else
        render json: { errors: student.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
  
  def create_student_with_temporary_email
    # Generate temporary email
    temp_email = User.generate_temporary_email(
      params[:student][:first_name],
      params[:student][:last_name]
    )
    
    student = User.new(student_params.except(:email))
    student.email = temp_email
    student.password = SecureRandom.hex(16)
    student.has_temporary_email = true
    student.confirmed_at = Time.current  # Auto-confirm temp accounts
    student.role_additional_information = "Student created by teacher"
    student.accept_privacy_policy = true
    
    if student.save
      # Generate claim token
      student.generate_claim_token!
      
      # Link to class
      link_student_to_class(student)
      
      # Determine school membership status
      school_membership_status = if @class.school_id.present?
        case student.role
        when 'children'
          { will_become_school_member: true, will_stay_class_only: false }
        when 'tutor', 'voluntary'
          { will_become_school_member: false, will_stay_class_only: true }
        end
      else
        { will_become_school_member: false, will_stay_class_only: true }
      end
      
      render json: {
        id: student.id,
        full_name: student.full_name,
        role: student.role,
        email: student.email,
        has_temporary_email: true,
        account_status: 'pending_claim',
        claim_token: student.claim_token,
        claim_url: claim_url(student.claim_token),
        qr_code_data: claim_url(student.claim_token),
        school_membership: school_membership_status,
        message: build_success_message(student.role, school_membership_status)
      }, status: :created
    else
      render json: { errors: student.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def link_student_to_class(student)
    if @class.school_id.present?
      # ONLY students become school members automatically
      if student.children?
        UserSchool.find_or_create_by!(
          user: student,
          school: @class.school,
          role: :member,
          status: :confirmed
        )
      end
      # Tutors and volunteers stay class-only
    end
    
    # Always link to class (all roles)
    UserSchoolLevel.find_or_create_by!(
      user: student,
      school_level: @class
    )
  end
  
  def build_success_message(role, school_membership)
    case role
    when 'children'
      if school_membership[:will_become_school_member]
        "Student added. Will become school member when class transfers. Share claim link with student/parent."
      else
        "Student added. Share claim link with student/parent."
      end
    when 'tutor'
      "Tutor added. Will stay class-only (no automatic school membership). Share claim link with tutor."
    when 'voluntary'
      "Volunteer added. Will stay class-only (no automatic school membership). Share claim link with volunteer."
    end
  end
  
  def serialize_student(student)
    {
      id: student.id,
      full_name: student.full_name,
      first_name: student.first_name,
      last_name: student.last_name,
      email: student.email,
      role: student.role,
      birthday: student.birthday,
      has_temporary_email: student.has_temporary_email?,
      account_status: student.has_temporary_email? ? 'pending_claim' : 'active',
      claim_url: student.has_temporary_email? ? claim_url(student.claim_token) : nil,
      joined_class_at: student.user_school_levels.find_by(school_level: @class)&.created_at,
      avatar_url: student.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_path(student.avatar, only_path: true) : nil
    }
  end
end
