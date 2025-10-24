class Project < ApplicationRecord
  belongs_to :owner, class_name: "User"
  belongs_to :partnership, optional: true

  has_many :project_companies, dependent: :destroy
  has_many :companies, through: :project_companies

  has_many :project_tags, dependent: :destroy
  has_many :tags, through: :project_tags
  has_many :project_skills, dependent: :destroy
  has_many :skills, through: :project_skills
  has_many :keywords, dependent: :destroy
  has_many :project_school_levels, dependent: :destroy
  has_many :school_levels, through: :project_school_levels
  has_many :users, through: :school_levels
  has_many :schools, through: :school_levels
  has_many :links, dependent: :destroy
  has_many :teams, dependent: :destroy
  has_many :team_members, through: :teams
  has_many :project_members, dependent: :destroy
  
  # Co-owner associations
  has_many :co_owner_members, 
           -> { where(role: :co_owner) }, 
           class_name: 'ProjectMember'
  has_many :co_owners, through: :co_owner_members, source: :user
  
  has_many :admin_members,
           -> { where(role: [:admin, :co_owner]) },
           class_name: 'ProjectMember'
  has_many :admins, through: :admin_members, source: :user
  
  has_many :user_badges, -> { where(status: :approved) }, dependent: :destroy
  has_one_attached :main_picture
  has_many_attached :pictures
  has_many_attached :documents

  accepts_nested_attributes_for :project_tags, allow_destroy: true
  accepts_nested_attributes_for :links, allow_destroy: true
  accepts_nested_attributes_for :keywords, allow_destroy: true
  accepts_nested_attributes_for :project_skills, allow_destroy: true
  accepts_nested_attributes_for :project_school_levels, allow_destroy: true
  accepts_nested_attributes_for :project_companies, allow_destroy: true
  accepts_nested_attributes_for :teams, allow_destroy: true

  enum :status, [:coming, :in_progress, :ended], default: :coming

  validates :title, :description, :start_date, :end_date, :owner, :status, presence: true
  validate :start_date_before_end_date, if: -> { start_date.present? && end_date.present? }
  validate :school_levels_or_company_presence
  validate :partnership_organizations_must_include_project_orgs, if: :partnership_id?

  # Partner project scopes
  scope :partner_projects, -> { where.not(partnership_id: nil) }
  scope :regular_projects, -> { where(partnership_id: nil) }
  scope :for_partnership, ->(partnership) { where(partnership: partnership) }
  
  scope :kinship, -> {
    Project
      .where(project_school_levels: {id: nil})
  }

  scope :default_project, ->(current_user) {
    includes(:team_members, :project_members, :project_school_levels, :schools, :school_levels, :main_picture_attachment)
      .all
  }

  scope :search, ->(query) {
    query_words = query.split(" ")
    where(
      query_words.map { |word| "projects.title ILIKE ? OR projects.description ILIKE ?" }.join(" OR "),
      *query_words.map { |word| ["%#{word}%", "%#{word}%"] }.flatten
    )
  }

  scope :my_projects, ->(user) {
    team_member_projects = where(team_members: {user: user})

    project_member_projects = where(project_members: {user: user, status: "confirmed"})

    team_member_projects.or(project_member_projects)
  }

  scope :my_administration_projects, ->(user) {
    left_joins(:project_members)
      .where('projects.owner_id = ? OR project_members.user_id = ? AND project_members.role IN (?)', 
             user.id, user.id, [:admin, :co_owner])
  }

  scope :by_tags, ->(tag_ids) {
    tag_ids = tag_ids.flatten.reject(&:blank?)

    joins(:tags)
      .where(tags: {
        id: tag_ids
      })
  }

  scope :by_school, ->(school_id) {
    where(school_levels: {
      school_id: Project.convert_to_array(school_id)
    })
  }

  scope :by_companies, ->(company_ids) {
    project_companies = ProjectCompany.where(company_id: company_ids)

    where(
      project_companies: project_companies
    )
  }

  scope :by_school_level, ->(school_level_id) {
    where(school_levels: {
      id: school_level_id
    })
  }

  def start_date_before_end_date
    return unless start_date > end_date

    errors.add(:start_date, "La date de début doit être avant la date de fin")
    errors.add(:end_date, "La date de fin doit être après la date de début")
  end

  def school_levels_or_company_presence
    # All projects must have at least school levels OR companies
    if project_school_levels.present? || project_companies.present?
      return true
    end

    # If neither is present, add appropriate error
    errors.add(:base, "Vous devez sélectionner au moins un niveau scolaire ou une entreprise")
  end

  def schools
    school_levels.map(&:school).uniq
  end

  def formatted_date_start
    start_date.strftime("%d/%m/%Y %H:%M")
  end

  def formatted_date_end
    end_date.strftime("%d/%m/%Y %H:%M")
  end

  def short_start_date
    start_date.strftime("%d/%m/%Y")
  end

  def short_end_date
    end_date.strftime("%d/%m/%Y")
  end

  def number_of_participants
    team_members.uniq.count
  end

  def self.convert_to_array(input)
    if input.is_a?(Array)
      return input.map(&:to_i)
    end

    if /^\[.*\]$/.match?(input) # Vérifie si la chaîne est entre crochets
      input[1..-2].split(",").map(&:to_i)
    else
      [input.to_i]
    end
  end

  def pending_participants?
    project_members.pending.any?
  end

  def pending_participants
    project_members.pending
  end

  def can_edit?(user)
    owner == user || project_members.where(user: user, role: [:admin, :co_owner]).any?
  end

  def companies_full_name_joined
    companies.map(&:full_name).join(", ")
  end

  def have_companies
    companies.present?
  end

  # ========================================
  # PARTNER PROJECT METHODS
  # ========================================
  
  after_update :notify_partner_organizations, if: :saved_change_to_partnership_id?
  
  def partner_project?
    partnership_id.present?
  end
  
  def all_partner_organizations
    return [] unless partner_project?
    partnership.all_participants
  end
  
  def user_from_partner_organization?(user)
    return false unless partner_project?
    
    all_partner_organizations.any? do |org|
      if org.is_a?(Company)
        user.user_company.exists?(company: org, status: :confirmed)
      elsif org.is_a?(School)
        user.user_schools.exists?(school: org, status: :confirmed)
      end
    end
  end
  
  def assign_to_partnership(partnership_to_assign, assigned_by:)
    # Verify user has permission
    return {success: false, error: "Unauthorized"} unless can_assign_to_partnership?(assigned_by)
    
    # Verify partnership is confirmed
    return {success: false, error: "Partnership must be confirmed"} unless partnership_to_assign.confirmed?
    
    # Verify partnership includes project's organizations
    return {success: false, error: "Partnership must include all project organizations"} unless eligible_for_partnership?(partnership_to_assign)
    
    if update(partnership: partnership_to_assign)
      {success: true}
    else
      {success: false, error: errors.full_messages.join(", ")}
    end
  end
  
  def remove_from_partnership(removed_by:)
    return {success: false, error: "Unauthorized"} unless can_assign_to_partnership?(removed_by)
    return {success: false, error: "Not a partner project"} unless partner_project?
    
    if update(partnership: nil)
      {success: true}
    else
      {success: false, error: errors.full_messages.join(", ")}
    end
  end
  
  def eligible_for_partnership?(partnership_to_check)
    return false unless partnership_to_check.confirmed?
    
    project_orgs = (companies + schools).uniq
    partnership_orgs = partnership_to_check.all_participants
    
    # All project orgs must be in partnership
    project_orgs.all? { |org| partnership_orgs.include?(org) }
  end
  
  def partner_organizations_can_see?
    partner_project? && partnership.share_projects?
  end
  
  # ========================================
  # CO-OWNER MANAGEMENT METHODS
  # ========================================
  
  def add_co_owner(user, added_by:)
    # Verify the person adding has permission
    return {success: false, error: "Unauthorized"} unless can_add_co_owners?(added_by)
    
    # Verify user is eligible
    return {success: false, error: "User not eligible for co-ownership"} unless user_eligible_for_co_ownership?(user)
    
    # Find or create project member
    member = project_members.find_or_initialize_by(user: user)
    
    if member.update(role: :co_owner, status: :confirmed)
      {success: true, member: member}
    else
      {success: false, error: member.errors.full_messages.join(", ")}
    end
  end
  
  def remove_co_owner(user, removed_by:)
    # Cannot remove primary owner
    return {success: false, error: "Cannot remove primary owner"} if user == owner
    
    # Verify the person removing has permission
    return {success: false, error: "Unauthorized"} unless can_add_co_owners?(removed_by)
    
    member = co_owner_members.find_by(user: user)
    return {success: false, error: "User is not a co-owner"} unless member
    
    if member.update(role: :member)
      {success: true, member: member}
    else
      {success: false, error: member.errors.full_messages.join(", ")}
    end
  end
  
  def user_is_co_owner?(user)
    co_owners.include?(user)
  end
  
  def user_is_admin_or_co_owner?(user)
    owner == user || admin_members.exists?(user: user)
  end
  
  def user_eligible_for_co_ownership?(user)
    # Must be admin/referent/superadmin of affiliated company or school
    # For partner projects: also eligible if from ANY partner organization
    
    eligible_orgs = if partner_project?
      all_partner_organizations  # ALL partner orgs
    else
      companies + schools  # Just directly affiliated orgs
    end
    
    eligible_orgs.any? { |org| user_has_elevated_role_in?(user, org) }
  end
  
  private
  
  def user_has_elevated_role_in?(user, organization)
    if organization.is_a?(Company)
      uc = user.user_company.find_by(company: organization)
      uc&.referent? || uc&.admin? || uc&.superadmin?
    elsif organization.is_a?(School)
      us = user.user_schools.find_by(school: organization)
      us&.referent? || us&.admin? || us&.superadmin?
    else
      false
    end
  end
  
  def can_add_co_owners?(user)
    user == owner || user_is_co_owner?(user)
  end
  
  def can_assign_to_partnership?(user)
    user == owner || user_is_co_owner?(user)
  end
  
  def partnership_organizations_must_include_project_orgs
    return unless partnership
    
    unless eligible_for_partnership?(partnership)
      errors.add(:partnership, "doit inclure toutes les organisations du projet")
    end
  end
  
  def notify_partner_organizations
    return unless partnership && partnership_id_before_last_save.nil?
    
    # Notify all partner organization superadmins about new partner project
    partnership.all_participants.each do |org|
      superadmins = if org.is_a?(Company)
        org.user_companies.where(role: :superadmin).map(&:user)
      elsif org.is_a?(School)
        org.user_schools.where(role: :superadmin).map(&:user)
      end
      
      superadmins&.each do |admin|
        PartnerProjectMailer.notify_new_partner_project(admin, self, org).deliver_later
      end
    end
  end
end
