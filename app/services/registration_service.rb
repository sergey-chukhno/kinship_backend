# Registration Service
# Handles user registration for all 4 types: Personal User, Teacher, School, Company
# Supports file uploads (avatar, company_logo) with graceful error handling
class RegistrationService < ApplicationService
  attr_reader :user, :school, :company, :errors, :file_warnings

  def initialize(params)
    @params = params
    @registration_type = params[:registration_type]
    @user_params = params[:user] || {}
    @availability_params = params[:availability] || {}
    @skills_params = params[:skills] || {}
    @school_params = params[:school] || {}
    @company_params = params[:company] || {}
    @join_school_ids = params[:join_school_ids] || []
    @join_company_ids = params[:join_company_ids] || []
    @children_info = params[:children_info] || []
    @avatar = params[:avatar]              # File upload (optional)
    @company_logo = params[:company_logo] # File upload (optional, company only)
    @errors = []
    @file_warnings = []                    # Track file upload warnings
  end

  def call
    validate_registration_type!
    validate_email_for_type!
    validate_role_for_type!
    
    return error_result if @errors.any?
    
    ActiveRecord::Base.transaction do
      create_user!
      
      case @registration_type
      when 'personal_user'
        handle_personal_user_registration!
      when 'teacher'
        handle_teacher_registration!
      when 'school'
        handle_school_registration!
      when 'company'
        handle_company_registration!
      end
      
      send_confirmation_email!
    end
    
    success_result
  rescue ActiveRecord::RecordInvalid => e
    @errors = e.record.errors.full_messages
    error_result
  rescue => e
    Rails.logger.error "RegistrationService error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @errors = [e.message]
    error_result
  end

  private

  # Validation methods
  def validate_registration_type!
    valid_types = %w[personal_user teacher school company]
    unless valid_types.include?(@registration_type)
      @errors << "Invalid registration_type. Must be one of: #{valid_types.join(', ')}"
    end
  end

  def validate_email_for_type!
    email = @user_params[:email]
    return unless email.present?

    user = User.new(email: email)
    user.role = @user_params[:role] || 'voluntary'
    
    # Check academic email requirements
    if User.is_teacher_role?(user.role) || User.is_school_admin_role?(user.role)
      unless is_academic_email?(email)
        @errors << "Teachers and school administrators must use an academic email address"
      end
    end
    
    # Check non-academic email for personal users
    if User.is_personal_user_role?(user.role)
      if is_academic_email?(email)
        @errors << "Personal users cannot use academic email addresses"
      end
    end
  end

  def validate_role_for_type!
    role = @user_params[:role]
    return unless role.present?

    case @registration_type
    when 'personal_user'
      unless User.is_personal_user_role?(role)
        @errors << "Invalid role for personal_user registration. Must be one of: #{User::PERSONAL_USER_ROLES.join(', ')}"
      end
    when 'teacher'
      unless User.is_teacher_role?(role)
        @errors << "Invalid role for teacher registration. Must be one of: #{User::TEACHER_ROLES.join(', ')}"
      end
    when 'school'
      unless User.is_school_admin_role?(role)
        @errors << "Invalid role for school registration. Must be one of: #{User::SCHOOL_ADMIN_ROLES.join(', ')}"
      end
    when 'company'
      unless User.is_company_admin_role?(role)
        @errors << "Invalid role for company registration. Must be one of: #{User::COMPANY_ADMIN_ROLES.join(', ')}"
      end
    end
  end

  def is_academic_email?(email)
    email.match?(/@(ac-aix-marseille|ac-amiens|ac-besancon|ac-bordeaux|ac-caen|ac-clermont|ac-creteil|ac-corse|ac-dijon|ac-grenoble|ac-guadeloupe|ac-guyane|ac-lille|ac-limoges|ac-lyon|ac-martinique|ac-mayotte|ac-montpellier|ac-nancy-metz|ac-nantes|ac-nice|ac-orleans-tours|ac-paris|ac-poitiers|ac-reims|ac-rennes|ac-reunion|ac-rouen|ac-strasbourg|ac-toulouse|ac-versailles)\.fr$/) || 
    email.match?(/@education\.mc$/) || 
    email.match?(/@lfmadrid\.org$/)
  end

  # User creation with avatar handling
  def create_user!
    @user = User.new(@user_params)
    @user.skip_password_validation = false
    
    # Auto-populate role_additional_information if not provided (for backward compatibility)
    # Only required if role is "other"
    if @user.role_additional_information.blank? && @user.role != "other"
      @user.role_additional_information = @user.role.to_s.humanize
    end
    
    # Attach avatar if provided (with error handling)
    if @avatar.present?
      begin
        @user.avatar.attach(@avatar)
        unless @user.valid?
          # If avatar validation fails, remove it and add warning
          avatar_errors = @user.errors.where(:avatar).map(&:full_message)
          @user.avatar.purge if @user.avatar.attached?
          @file_warnings << "Avatar upload failed: #{avatar_errors.join(', ')}"
          @user.errors.delete(:avatar)
        end
      rescue => e
        @file_warnings << "Avatar upload failed: #{e.message}"
      end
    end
    
    @user.save!
    
    # Update availability if provided
    if @availability_params.present?
      if @user.availability
        @user.availability.update!(@availability_params)
      else
        @user.create_availability!(@availability_params)
      end
    end
    
    # Add skills/sub-skills if provided
    if @skills_params[:skill_ids].present?
      @user.skill_ids = @skills_params[:skill_ids]
    end
    
    if @skills_params[:sub_skill_ids].present?
      @user.sub_skill_ids = @skills_params[:sub_skill_ids]
    end
  end

  # Registration type handlers
  def handle_personal_user_registration!
    # Join schools as member (pending)
    @join_school_ids.each do |school_id|
      school = School.find_by(id: school_id)
      next unless school
      
      UserSchool.create!(
        user: @user,
        school: school,
        role: :member,
        status: :pending
      )
      
      # Notify school admins (async)
      notify_school_admins(school)
    end
    
    # Join companies as member (pending)
    @join_company_ids.each do |company_id|
      company = Company.find_by(id: company_id)
      next unless company
      
      UserCompany.create!(
        user: @user,
        company: company,
        role: :member,
        status: :pending
      )
      
      # Notify company admins (async)
      notify_company_admins(company)
    end
    
    # Create ParentChildInfo records (if children_info provided)
    @children_info.each do |child_info|
      ParentChildInfo.create!(
        parent_user: @user,
        first_name: child_info[:first_name],
        last_name: child_info[:last_name],
        birthday: child_info[:birthday],
        school_id: child_info[:school_id],
        school_name: child_info[:school_name],
        class_id: child_info[:class_id],
        class_name: child_info[:class_name]
      )
    end
  end

  def handle_teacher_registration!
    # Join schools as member (pending)
    @join_school_ids.each do |school_id|
      school = School.find_by(id: school_id)
      next unless school
      
      UserSchool.create!(
        user: @user,
        school: school,
        role: :member,
        status: :pending
      )
      
      # Notify school admins (async)
      notify_school_admins(school)
    end
    
    # IndependentTeacher auto-created by User model callback
  end

  def handle_school_registration!
    @school = School.new(@school_params)
    @school.status = :pending
    
    @school.save!
    
    # Create UserSchool as superadmin (pending)
    UserSchool.create!(
      user: @user,
      school: @school,
      role: :superadmin,
      status: :pending
    )
  end

  def handle_company_registration!
    @company = Company.new(@company_params)
    @company.status = :confirmed
    
    # Attach logo if provided (with error handling)
    if @company_logo.present?
      begin
        @company.logo.attach(@company_logo)
        unless @company.valid?
          # If logo validation fails, remove it and add warning
          logo_errors = @company.errors.where(:logo).map(&:full_message)
          @company.logo.purge if @company.logo.attached?
          @file_warnings << "Company logo upload failed: #{logo_errors.join(', ')}"
          @company.errors.delete(:logo)
        end
      rescue => e
        @file_warnings << "Company logo upload failed: #{e.message}"
      end
    end
    
    @company.save!
    
    # Create UserCompany as superadmin (pending)
    UserCompany.create!(
      user: @user,
      company: @company,
      role: :superadmin,
      status: :pending
    )
    
    # Create BranchRequest if specified
    if @company_params[:branch_request_to_company_id].present?
      main_company = Company.find_by(id: @company_params[:branch_request_to_company_id])
      if main_company
        branch_request = BranchRequest.create!(
          parent: main_company,
          child: @company,
          initiator: @company,
          status: :pending
        )
        
        # Notify main company admins (async)
        BranchRequestMailer.branch_request_created(branch_request, main_company).deliver_later
      end
    end
  end

  # Helper methods
  def send_confirmation_email!
    @user.send_confirmation_instructions
  end

  def notify_school_admins(school)
    admins = school.user_schools.where(role: [:admin, :superadmin], status: :confirmed)
                    .includes(:user)
                    .map(&:user)
    
    admins.each do |admin|
      OrganizationMailer.notify_admins_of_pending_user_confirmation(
        organisation: school,
        contact_mail: admin.email
      ).deliver_later
    end
  end

  def notify_company_admins(company)
    admins = company.user_companies.where(role: [:admin, :superadmin], status: :confirmed)
                    .includes(:user)
                    .map(&:user)
    
    admins.each do |admin|
      OrganizationMailer.notify_admins_of_pending_user_confirmation(
        organisation: company,
        contact_mail: admin.email
      ).deliver_later
    end
  end

  def success_result
    {
      success: true,
      user: @user,
      company: @company,
      school: @school,
      file_warnings: @file_warnings
    }
  end

  def error_result
    {
      success: false,
      errors: @errors
    }
  end
end

