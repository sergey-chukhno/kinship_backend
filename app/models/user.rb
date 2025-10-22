class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable]
  # ! SET THIS AFTER CREATE FOR SPRINT 2
  after_create :create_availability
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
  
  # Teacher-class assignments (NEW - Change #8)
  has_many :teacher_school_levels, dependent: :destroy
  has_many :assigned_classes, through: :teacher_school_levels, source: :school_level

  has_many :user_company, dependent: :destroy
  has_many :companies, through: :user_company

  has_many :project_members, dependent: :destroy

  has_many :badges_sent, class_name: "UserBadge", foreign_key: :sender_id
  has_many :badges_received, -> { where(status: :approved) }, class_name: "UserBadge", foreign_key: :receiver_id

  has_one_attached :avatar

  accepts_nested_attributes_for :user_skills, allow_destroy: true
  accepts_nested_attributes_for :user_sub_skills, allow_destroy: true
  accepts_nested_attributes_for :availability, allow_destroy: true
  accepts_nested_attributes_for :user_schools, allow_destroy: true
  accepts_nested_attributes_for :user_school_levels, allow_destroy: true
  accepts_nested_attributes_for :user_company, allow_destroy: true
  enum :role, {teacher: 0, tutor: 1, voluntary: 2, children: 3}, default: :voluntary

  validates :first_name, :last_name, :role, :role_additional_information, presence: true
  validates :email, presence: true
  validates :contact_email, uniqueness: true, allow_blank: true, format: {with: Devise.email_regexp}
  validate :academic_email?, if: -> { role == "teacher" && email.present? }
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
  scope :teachers, -> { where(role: "teacher") }
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
    project_ids_where_user_is_admin = project_members.where(admin: true).pluck(:project_id)
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

  def academic_email?
    if email.match?(/@(ac-aix-marseille|ac-amiens|ac-besancon|ac-bordeaux|ac-caen|ac-clermont|ac-creteil|ac-corse|ac-dijon|ac-grenoble|ac-guadeloupe|ac-guyane|ac-lille|ac-limoges|ac-lyon|ac-martinique|ac-mayotte|ac-montpellier|ac-nancy-metz|ac-nantes|ac-nice|ac-orleans-tours|ac-paris|ac-poitiers|ac-reims|ac-rennes|ac-reunion|ac-rouen|ac-strasbourg|ac-toulouse|ac-versailles)\.fr$/) || email.match?(/@education\.mc$/) || email.match?(/@lfmadrid\.org$/)
      return
    end

    errors.add(:email, "L'email doit être votre mail académique")
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
end
