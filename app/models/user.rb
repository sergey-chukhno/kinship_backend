class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable]
  # ! SET THIS AFTER CREATE FOR SPRINT 2
  after_create :create_availability
  after_create :create_independent_teacher_if_teacher  # Change #9
  before_validation :set_admin_if_super_admin
  attr_accessor :skip_password_validation, :role_additional_information_custom

  PARENTS_ADDITIONAL_ROLES = ["parent", "grand-parent"].freeze
  VOLUNTARYS_ADDITIONAL_ROLES = ["lycéen ou étudiant", "salarié", "bénévole", "chargé(e) de mission"].freeze
  TEACHERS_ADDITIONAL_ROLES = ["professeur", "membre direction", "cpe"].freeze

  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable, :confirmable

  belongs_to :parent, class_name: "User", optional: true
  has_many :childrens, class_name: "User", foreign_key: :parent_id, dependent: :destroy

  has_many :projects, foreign_key: :owner_id, dependent: :destroy

  has_many :user_skills, dependent: :destroy
  has_many :skills, through: :user_skills

  has_many :user_sub_skills, dependent: :destroy
  has_many :sub_skills, through: :user_sub_skills

  has_many :team_members, dependent: :destroy
  has_many :teams, through: :team_members

  has_many :user_schools, dependent: :destroy
  has_many :schools, through: :user_schools

  has_many :user_school_levels, dependent: :destroy
  has_many :school_levels, through: :user_school_levels
  has_one :availability, dependent: :destroy
  
  # Teacher-class assignments (Change #8)
  has_many :teacher_school_levels, dependent: :destroy
  has_many :assigned_classes, through: :teacher_school_levels, source: :school_level
  
  # Independent teacher status (Change #9)
  has_one :independent_teacher, dependent: :destroy

  has_many :user_company, dependent: :destroy
  has_many :companies, through: :user_company

  has_many :project_members, dependent: :destroy

  has_many :badges_sent, class_name: "UserBadge", foreign_key: :sender_id
  has_many :badges_received, -> { where(status: :approved) }, class_name: "UserBadge", foreign_key: :receiver_id

  has_many :parent_child_infos, foreign_key: :parent_user_id, dependent: :destroy

  has_one_attached :avatar

  accepts_nested_attributes_for :user_skills, allow_destroy: true
  accepts_nested_attributes_for :user_sub_skills, allow_destroy: true
  accepts_nested_attributes_for :availability, allow_destroy: true
  accepts_nested_attributes_for :user_schools, allow_destroy: true
  accepts_nested_attributes_for :user_school_levels, allow_destroy: true
  accepts_nested_attributes_for :user_company, allow_destroy: true
  
  # New informative role enum (16 roles)
  # Using prefix: true to avoid conflict with belongs_to :parent association
  enum :role, {
    # Personal User Roles
    parent: 0,
    grand_parent: 1,
    children: 2,
    voluntary: 3,
    tutor: 4,
    employee: 5,
    # Teacher Roles
    school_teacher: 6,
    college_lycee_professor: 7,
    teaching_staff: 8,
    # School Admin Roles
    school_director: 9,
    principal: 10,
    education_director: 11,
    # Company Admin Roles
    association_president: 12,
    company_director: 13,
    organization_head: 14,
    # Other
    other: 15
  }, default: :voluntary, prefix: true

  # Role group constants
  PERSONAL_USER_ROLES = [:parent, :grand_parent, :children, :voluntary, :tutor, :employee, :other].freeze
  TEACHER_ROLES = [:school_teacher, :college_lycee_professor, :teaching_staff, :other].freeze
  SCHOOL_ADMIN_ROLES = [:school_director, :principal, :education_director, :other].freeze
  COMPANY_ADMIN_ROLES = [:association_president, :company_director, :organization_head, :other].freeze

  # Role class methods
  def self.is_teacher_role?(role)
    TEACHER_ROLES.include?(role.to_sym)
  end

  def self.is_school_admin_role?(role)
    SCHOOL_ADMIN_ROLES.include?(role.to_sym)
  end

  def self.is_company_admin_role?(role)
    COMPANY_ADMIN_ROLES.include?(role.to_sym)
  end

  def self.is_personal_user_role?(role)
    PERSONAL_USER_ROLES.include?(role.to_sym)
  end

  validates :first_name, :last_name, :role, presence: true
  validate :role_additional_information_required_if_other
  validates :email, presence: true, uniqueness: true
  validates :email, format: {with: Devise.email_regexp}, unless: :has_temporary_email?
  validates :contact_email, uniqueness: true, allow_blank: true, format: {with: Devise.email_regexp}
  validate :academic_email?, if: -> { requires_academic_email? && email.present? && !has_temporary_email? }
  validate :non_academic_email_for_personal_user
  validate :password_complexity
  validate :minimum_age
  validate :avatar_format
  validate :check_for_circular_reference, if: -> { parent_id.present? }
  validate :privacy_policy_accepted?, if: -> { accept_privacy_policy == false }

  scope :participants_for_teacher, lambda { |current_user|
    joins(:skills)
      .includes(:school_levels, :schools, :availability)
      .where.not(admin: true)
      .where.not(id: current_user.id)
      .where.not(role: "voluntary")
      .where.not(skills: {id: nil})
      .where(schools: {id: current_user.schools})
  }
  scope :participants_for_tutor, lambda { |current_user|
    joins(:skills)
      .includes(:school_levels, :schools, :availability)
      .where.not(admin: true)
      .where.not(id: current_user.id)
      .where.not(role: "voluntary")
      .where.not(role: "teacher")
      .where.not(skills: {id: nil})
      .where(schools: {id: current_user.schools})
      .where(school_levels: {id: current_user.school_levels})
      .or(User.teachers.where(schools: {id: current_user.schools}))
  }
  scope :voluntary, -> { where(role: "voluntary") }
  scope :teachers, -> { where(role: TEACHER_ROLES.map(&:to_s)) }
  scope :tutors, -> { where(role: "tutor") }
  scope :children, -> { where.not(parent_id: nil) }
  scope :by_school, lambda { |school_id|
    includes(:user_schools)
      .where(user_schools: {school_id:})
  }
  scope :by_school_level, lambda { |school_level_id|
    includes(:user_school_levels, :user_schools, :skills)
      .where(user_school_levels: {school_level_id:})
      .or(User.where(role: "teacher",
        user_schools: {school_id: SchoolLevel.find(school_level_id).school_id})
        .where.not(skills: {id: nil}))
  }
  scope :by_skills, lambda { |skill_ids|
    skill_ids = skill_ids.flatten.reject(&:blank?)
    where(skills: {
      id: skill_ids
    })
    # Todo new filter approch
    # .group("users.id")
    # .having("COUNT(DISTINCT skills.id) = ?", skill_ids.count)
  }
  scope :by_sub_skills, lambda { |sub_skill_ids|
    includes(:user_sub_skills)
      .where(user_sub_skills: {sub_skill_id: sub_skill_ids})
  }
  scope :by_monday, lambda {
    includes(:availability)
      .where(availabilities: {monday: true})
  }
  scope :by_tuesday, lambda {
    includes(:availability)
      .where(availabilities: {tuesday: true})
  }
  scope :by_wednesday, lambda {
    includes(:availability)
      .where(availabilities: {wednesday: true})
  }
  scope :by_thursday, lambda {
    includes(:availability)
      .where(availabilities: {thursday: true})
  }
  scope :by_friday, lambda {
    includes(:availability)
      .where(availabilities: {friday: true})
  }
  scope :by_other, lambda {
    includes(:availability)
      .where(availabilities: {other: true})
  }
  scope :by_propose_workshop, lambda {
    where(propose_workshop: true)
  }
  scope :not_by_propose_workshop, lambda {
    where(propose_workshop: false)
  }
  scope :by_take_trainee, lambda {
    where(take_trainee: true)
  }
  scope :not_by_take_trainee, lambda {
    where(take_trainee: false)
  }
  scope :admin, -> { where(admin: true) }

  after_create :send_welcome_email

  def full_name
    "#{first_name} #{last_name}"
  end

  def short_name
    "#{first_name} #{last_name.first}"
  end

  def full_name_with_role_and_school_level
    "#{full_name} | #{I18n.t("models.user.roles.#{role}")} | #{school_levels.map do |school_level|
                                                                 school_level.full_name_without_school
                                                               end.join(", ")}"
  end

  def admin?
    admin
  end

  def super_admin?
    super_admin
  end

  def privacy_policy_accepted?
    errors.add(:accept_privacy_policy, "doit être accepté") unless accept_privacy_policy
  end

  def preferred_email
    contact_email.present? ? contact_email : email
  end

  def age
    now = Time.now.utc.to_date
    now.year - birthday.year - ((now.month > birthday.month || (now.month == birthday.month && now.day >= birthday.day)) ? 0 : 1)
  end

  def skills?
    user_skills.any?
  end

  def availabilities?
    availability.available?
  end

  def this_skill?(skill)
    user_skills.where(skill:).any?
  end

  def this_sub_skill?(sub_skill)
    user_sub_skills.where(sub_skill:).any?
  end

  def has_parent
    parent_id.present?
  end

  def schools_admin
    user_schools.where(role: [:admin, :superadmin], status: :confirmed).map(&:school)
  end

  def schools_with_badge_access
    user_schools.where(
      status: :confirmed,
      role: [:intervenant, :referent, :admin, :superadmin]
    ).map(&:school)
  end

  def companies_admin
    user_company.where(role: [:admin, :superadmin], status: :confirmed).map(&:company)
  end

  def companies_with_badge_access
    user_company.where(
      status: :confirmed,
      role: [:intervenant, :referent, :admin, :superadmin]
    ).map(&:company)
  end

  def projects_owner
    project_ids_where_user_is_admin = project_members.where(role: [:admin, :co_owner]).pluck(:project_id)
    project_ids_where_user_is_owner = projects.pluck(:id)

    Project.where(id: project_ids_where_user_is_admin + project_ids_where_user_is_owner)
  end

  def school_admin?(school)
    us = user_schools.find_by(school:)
    us&.admin? || us&.superadmin?
  end

  def company_admin?(company)
    uc = user_company.find_by(company:)
    uc&.admin? || uc&.superadmin?
  end

  def school_superadmin?(school)
    user_schools.find_by(school:)&.superadmin?
  end

  def company_superadmin?(company)
    user_company.find_by(company:)&.superadmin?
  end

  def can_create_project?
    return true if admin? || teacher?
    return true if companies.select do |company|
                     company.active_contract? && company.user_can_create_project?(self)
                   end.any?

    false
  end

  def can_give_badges?
    schools = user_schools.where(role: [:intervenant, :referent, :admin, :superadmin])
    companies = user_company.where(role: [:intervenant, :referent, :admin, :superadmin])

    schools.any? || companies.any?
  end

  def can_give_badges_in_project?(project)
    # Check if user has badge permission in any of project's affiliated organizations
    project_companies = project.companies
    project_schools = project.schools
    
    project_companies.any? { |c| can_give_badges_in_company?(c) } ||
    project_schools.any? { |s| can_give_badges_in_school?(s) }
  end
  
  def can_give_badges_in_company?(company)
    uc = user_company.find_by(company: company)
    uc&.can_assign_badges?
  end
  
  def can_give_badges_in_school?(school)
    us = user_schools.find_by(school: school)
    us&.can_assign_badges?
  end
  
  # Change #9: Independent Teacher & Temporary Email Support
  
  # Check if user has any active contract (school, company, or independent)
  def active_contract?
    has_school_contract? || has_company_contract? || has_independent_contract?
  end
  
  def has_school_contract?
    user_schools.confirmed.any? { |us| us.school.active_contract? }
  end
  
  def has_company_contract?
    user_company.confirmed.any? { |uc| uc.company.active_contract? }
  end
  
  def has_independent_contract?
    independent_teacher&.active? && independent_teacher&.active_contract?
  end
  
  # Get all organizations where user can assign badges
  def badge_assignment_contexts
    contexts = []
    
    # Schools with badge permission
    user_schools.where(role: [:intervenant, :referent, :admin, :superadmin], status: :confirmed).each do |us|
      next unless us.school.active_contract?
      contexts << {
        type: 'School',
        id: us.school_id,
        name: us.school.name,
        has_contract: true
      }
    end
    
    # Companies with badge permission
    user_company.where(role: [:intervenant, :referent, :admin, :superadmin], status: :confirmed).each do |uc|
      next unless uc.company.active_contract?
      contexts << {
        type: 'Company',
        id: uc.company_id,
        name: uc.company.name,
        has_contract: true
      }
    end
    
    # Independent teacher (if active and has contract)
    if independent_teacher&.active? && independent_teacher&.active_contract?
      contexts << {
        type: 'IndependentTeacher',
        id: independent_teacher.id,
        name: independent_teacher.name,
        has_contract: true
      }
    end
    
    contexts
  end
  
  # Generate temporary email for students created without email
  def self.generate_temporary_email(first_name, last_name)
    base = "#{first_name}.#{last_name}".parameterize.gsub('-', '.')
    unique_id = SecureRandom.hex(6)
    "#{base}.pending#{unique_id}@kinship.temp"
  end
  
  # Generate claim token for account claiming
  def generate_claim_token!
    self.claim_token = SecureRandom.urlsafe_base64(32)
    self.has_temporary_email = true
    save!
  end
  
  # Check if account can be claimed
  def claimable?
    has_temporary_email? && claim_token.present?
  end
  
  # Claim account with real email (student activates their account)
  def claim_account!(real_email, password, birthday_verification)
    return false unless claimable?
    
    # Verify birthday for security
    return false unless birthday == birthday_verification
    
    self.email = real_email
    self.password = password
    self.password_confirmation = password
    self.has_temporary_email = false
    self.claim_token = nil
    self.confirmed_at = nil  # Will need to confirm new email
    
    if save
      send_confirmation_instructions if respond_to?(:send_confirmation_instructions)
      true
    else
      false
    end
  end

  def generate_delete_token
    self.delete_token = SecureRandom.hex(90)
    self.delete_token_sent_at = DateTime.now
    save
  end

  def create_availability
    Availability.create(user: self)
  end

  def confirmed_schools
    schools.confirmed
  end

  def confirmed_companies
    companies.confirmed
  end

  def avatar_url
    return nil unless avatar.attached?
    Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: false)
  end
  
  # ========================================
  # TEACHER-CLASS ASSIGNMENT METHODS (Change #8)
  # ========================================
  
  def assigned_to_class?(school_level)
    assigned_classes.include?(school_level)
  end
  
  def created_classes
    assigned_classes.joins(:teacher_school_levels)
                   .where(teacher_school_levels: {user_id: id, is_creator: true})
  end
  
  def all_teaching_classes
    assigned_classes  # All classes where teacher is assigned
  end

  private

  def requires_academic_email?
    User.is_teacher_role?(role) || User.is_school_admin_role?(role)
  end

  def academic_email?
    return if is_academic_email?(email)
    errors.add(:email, "L'email doit être votre mail académique")
  end

  def is_academic_email?(email_address)
    email_address.match?(/@(ac-aix-marseille|ac-amiens|ac-besancon|ac-bordeaux|ac-caen|ac-clermont|ac-creteil|ac-corse|ac-dijon|ac-grenoble|ac-guadeloupe|ac-guyane|ac-lille|ac-limoges|ac-lyon|ac-martinique|ac-mayotte|ac-montpellier|ac-nancy-metz|ac-nantes|ac-nice|ac-orleans-tours|ac-paris|ac-poitiers|ac-reims|ac-rennes|ac-reunion|ac-rouen|ac-strasbourg|ac-toulouse|ac-versailles)\.fr$/) || 
    email_address.match?(/@education\.mc$/) || 
    email_address.match?(/@lfmadrid\.org$/)
  end

  def non_academic_email_for_personal_user
    return unless User.is_personal_user_role?(role)
    return unless email.present?
    return if has_temporary_email?
    
    if is_academic_email?(email)
      errors.add(:email, "Les utilisateurs personnels ne peuvent pas utiliser d'email académique. Veuillez utiliser votre email personnel.")
    end
  end

  def password_complexity
    return if password.blank? || skip_password_validation
    
    errors.add(:password, "doit contenir au moins 8 caractères") if password.length < 8
    errors.add(:password, "doit contenir au moins une lettre majuscule") unless password.match?(/[A-Z]/)
    errors.add(:password, "doit contenir au moins un caractère spécial") unless password.match?(/[!@#$%^&*(),.?":{}|<>]/)
  end

  def minimum_age
    return unless birthday.present?
    
    age = ((Time.zone.now - birthday.to_time) / 1.year.seconds).floor
    if age < 13
      errors.add(:birthday, "vous devez avoir au moins 13 ans pour vous inscrire")
    end
  end

  def avatar_format
    return unless avatar.attached?
    
    acceptable_types = ["image/jpeg", "image/png", "image/gif", "image/webp", "image/svg+xml"]
    unless acceptable_types.include?(avatar.content_type)
      errors.add(:avatar, "doit être une image JPEG, PNG, GIF, WebP ou SVG")
    end
    
    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, "doit être inférieure à 5 Mo")
    end
  end

  def role_additional_information_required_if_other
    return unless role == "other"
    
    if role_additional_information.blank?
      errors.add(:role_additional_information, "doit être rempli(e) lorsque le rôle est 'autre'")
    end
  end

  def set_admin_if_super_admin
    self.admin = true if super_admin
  end

  def check_for_circular_reference
    return unless parent_id == id

    errors.add(:parent_id, "Vous ne pouvez pas être votre propre parent")
  end

  def send_welcome_email
    return if Rails.env.development? || Rails.env.test?

    UserMailer.send_welcome_email(self).deliver_later if self && email
  end
  
  # Auto-create IndependentTeacher for new teachers (Change #9)
  def create_independent_teacher_if_teacher
    return unless User.is_teacher_role?(role)
    
    IndependentTeacher.create!(
      user: self,
      organization_name: "#{full_name} - Enseignant Indépendant",
      status: :active
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn "Failed to create IndependentTeacher for user #{id}: #{e.message}"
  end
end
