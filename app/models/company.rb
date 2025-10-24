class Company < ApplicationRecord
  include PgSearch::Model

  has_many :project_companies, dependent: :destroy
  has_many :projects, through: :project_companies

  # Legacy partnership associations (kept for backward compatibility)
  has_many :company_partners, foreign_key: :company_sponsor_id, class_name: "CompanyCompany"
  has_many :reverse_company_partners, foreign_key: :company_id, class_name: "CompanyCompany"
  has_many :school_companies, dependent: :destroy
  has_many :schools, through: :school_companies, dependent: :destroy

  # New partnership system
  has_many :partnership_members_as_participant, 
           as: :participant, 
           class_name: 'PartnershipMember',
           dependent: :destroy
  has_many :partnerships, through: :partnership_members_as_participant
  has_many :initiated_partnerships, 
           as: :initiator, 
           class_name: 'Partnership',
           dependent: :destroy

  # Branch system (Change #4)
  belongs_to :parent_company, class_name: 'Company', optional: true
  has_many :branch_companies, 
           class_name: 'Company', 
           foreign_key: :parent_company_id, 
           dependent: :nullify
  
  # Branch requests (polymorphic)
  has_many :sent_branch_requests_as_parent, 
           as: :parent, 
           class_name: 'BranchRequest',
           dependent: :destroy
  has_many :received_branch_requests_as_child, 
           as: :child, 
           class_name: 'BranchRequest',
           dependent: :destroy

  has_many :user_companies, dependent: :destroy
  has_many :users, through: :user_companies
  has_many :contracts, as: :contractable, dependent: :destroy
  has_many :company_skills, dependent: :destroy
  has_many :skills, through: :company_skills
  has_many :company_sub_skills, dependent: :destroy
  has_many :sub_skills, through: :company_sub_skills
  belongs_to :company_type

  has_one_attached :logo

  enum :status, {pending: 0, confirmed: 1}, default: :pending

  validates :name, :zip_code, :city, :referent_phone_number, :description, :company_type_id, presence: true
  validates :siret_number, length: {is: 14}, allow_blank: true
  validates :siret_number, uniqueness: true, allow_blank: true
  validates :siret_number, format: {with: /\A\d{14}\z/}, allow_blank: true
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}, allow_blank: true
  validates :website, format: {with: URI::DEFAULT_PARSER.make_regexp, message: "Url invalide, l'url doit commencer par http:// ou https://"}, allow_blank: true
  # validates :referent_phone_number, format: { with: /\A0[1-9]([-. ]?[0-9]{2}){4}\z/ }
  validate :logo_format
  
  # Branch validations (Change #4)
  validate :cannot_be_own_branch
  validate :cannot_have_circular_branch_reference
  validate :branch_cannot_have_branches

  accepts_nested_attributes_for :company_skills, allow_destroy: true
  accepts_nested_attributes_for :company_sub_skills, allow_destroy: true
  accepts_nested_attributes_for :school_companies
  accepts_nested_attributes_for :company_partners

  pg_search_scope :by_full_name, against: [:name, :city, :zip_code],
    using: {
      tsearch: {
        prefix: true
      }
    }

  def full_name
    "#{name}, #{city} (#{zip_code})"
  end

  def owner?
    user_companies.where(role: :superadmin).any?
  end

  def owner
    user_companies.find_by(role: :superadmin)
  end

  def admins?
    user_companies.where(role: [:admin, :superadmin]).any?
  end

  def admins
    user_companies.where(role: [:admin, :superadmin])
  end

  def admin_user?(user)
    uc = user_companies.find_by(user: user)
    uc&.admin? || uc&.superadmin?
  end

  def superadmin_user?(user)
    user_companies.find_by(user: user)&.superadmin?
  end

  def users_waiting_for_confirmation?
    user_companies.where(status: :pending).any?
  end

  def users_waiting_for_confirmation
    user_companies.where(status: :pending)
  end

  def location
    "#{city}, #{zip_code}"
  end

  def active_contract?
    contracts.where(active: true).any?
  end

  def active_contract
    contracts.find_by(active: true)
  end

  def user_can_create_project?(user)
    user_companies.find_by(user: user).can_create_project?
  end

  def logo_url
    return nil unless logo.attached?
    Rails.application.routes.url_helpers.rails_blob_url(logo, only_path: false)
  end

  # ========================================
  # NEW PARTNERSHIP SYSTEM METHODS
  # ========================================
  
  def active_partnerships
    partnerships.active
  end
  
  def partner_companies
    active_partnerships
      .joins(:partnership_members)
      .where(partnership_members: {participant_type: 'Company'})
      .where.not(partnership_members: {participant_id: id})
      .joins("INNER JOIN companies ON companies.id = partnership_members.participant_id")
      .select('DISTINCT companies.*')
  end
  
  def partner_schools
    active_partnerships
      .joins(:partnership_members)
      .where(partnership_members: {participant_type: 'School'})
      .joins("INNER JOIN schools ON schools.id = partnership_members.participant_id")
      .select('DISTINCT schools.*')
  end
  
  def all_partners
    partner_companies.to_a + partner_schools.to_a
  end
  
  def shared_member_companies
    active_partnerships
      .sharing_members
      .joins(:partnership_members)
      .where(partnership_members: {participant_type: 'Company'})
      .where.not(partnership_members: {participant_id: id})
      .joins("INNER JOIN companies ON companies.id = partnership_members.participant_id")
      .select('DISTINCT companies.*')
  end
  
  def shared_member_schools
    active_partnerships
      .sharing_members
      .joins(:partnership_members)
      .where(partnership_members: {participant_type: 'School'})
      .joins("INNER JOIN schools ON schools.id = partnership_members.participant_id")
      .select('DISTINCT schools.*')
  end
  
  def shared_project_companies
    active_partnerships
      .sharing_projects
      .joins(:partnership_members)
      .where(partnership_members: {participant_type: 'Company'})
      .where.not(partnership_members: {participant_id: id})
      .joins("INNER JOIN companies ON companies.id = partnership_members.participant_id")
      .select('DISTINCT companies.*')
  end
  
  def shared_project_schools
    active_partnerships
      .sharing_projects
      .joins(:partnership_members)
      .where(partnership_members: {participant_type: 'School'})
      .joins("INNER JOIN schools ON schools.id = partnership_members.participant_id")
      .select('DISTINCT schools.*')
  end
  
  def partnered_with?(organization)
    active_partnerships.exists?(
      partnership_members: {participant: organization, member_status: :confirmed}
    )
  end
  
  def sponsoring?(company)
    active_partnerships
      .with_sponsorship
      .joins(:partnership_members)
      .where(partnership_members: {participant: self, role_in_partnership: :sponsor})
      .exists?(partnership_members: {participant: company, role_in_partnership: :beneficiary})
  end
  
  def sponsored_by?(company)
    active_partnerships
      .with_sponsorship
      .joins(:partnership_members)
      .where(partnership_members: {participant: self, role_in_partnership: :beneficiary})
      .exists?(partnership_members: {participant: company, role_in_partnership: :sponsor})
  end
  
  def partnership_with(organization)
    active_partnerships.for_organization(organization).first
  end

  # ========================================
  # BRANCH SYSTEM METHODS (Change #4)
  # ========================================
  
  # Scopes
  def self.main_companies
    where(parent_company_id: nil)
  end
  
  def self.branch_companies
    where.not(parent_company_id: nil)
  end
  
  # Status checks
  def main_company?
    parent_company_id.nil?
  end
  
  def branch?
    parent_company_id.present?
  end
  
  # Branch management
  def all_branch_companies
    branch_companies
  end
  
  def all_members_including_branches
    if main_company?
      User.joins(:user_company)
          .where(user_companies: {company_id: [id] + branch_companies.pluck(:id), status: :confirmed})
          .distinct
    else
      User.joins(:user_company)
          .where(user_companies: {company_id: id, status: :confirmed})
          .distinct
    end
  end
  
  def all_projects_including_branches
    if main_company?
      Project.joins(:project_companies)
             .where(project_companies: {company_id: [id] + branch_companies.pluck(:id)})
             .distinct
    else
      projects
    end
  end
  
  def members_visible_to_branch?(branch)
    branch.parent_company == self && share_members_with_branches
  end
  
  def projects_visible_to_branch?(branch)
    branch.parent_company == self  # Parent can always see branch projects
  end
  
  # Branch request management
  def request_to_become_branch_of(parent_company)
    BranchRequest.create!(
      parent: parent_company,
      child: self,
      initiator: self
    )
  end
  
  def invite_as_branch(child_company)
    BranchRequest.create!(
      parent: self,
      child: child_company,
      initiator: self
    )
  end
  
  def detach_branch(branch)
    return false unless branch.parent_company == self
    branch.update(parent_company: nil)
  end
  
  def detach_from_parent
    return false unless parent_company.present?
    update(parent_company: nil)
  end

  private

  def logo_format
    return unless logo.attached?

    acceptable_types = ["image/jpeg", "image/png", "image/gif", "image/webp", "image/svg+xml"]
    unless acceptable_types.include?(logo.content_type)
      errors.add(:logo, "doit être une image JPEG, PNG, GIF, WebP ou SVG")
    end

    if logo.byte_size > 5.megabytes
      errors.add(:logo, "doit être inférieure à 5 Mo")
    end
  end
  
  # Branch validation methods (Change #4)
  def cannot_be_own_branch
    return unless id.present? && parent_company_id.present?
    
    if id == parent_company_id
      errors.add(:parent_company, "ne peut pas être elle-même")
    end
  end
  
  def cannot_have_circular_branch_reference
    return unless parent_company_id.present? && parent_company_id_changed? && persisted?
    
    # Check if parent is already a branch of this company
    current = Company.find_by(id: parent_company_id)
    return unless current
    
    # Check one level up (sufficient for 1-level depth enforcement)
    if current.parent_company_id == id
      errors.add(:parent_company, "créerait une référence circulaire")
    end
  end
  
  def branch_cannot_have_branches
    return unless parent_company_id.present?
    
    # Check if the parent is already a branch (has a parent itself)
    parent = Company.find_by(id: parent_company_id)
    return unless parent&.parent_company_id.present?
    
    errors.add(:base, "Une filiale ne peut pas avoir de sous-filiales (profondeur max: 1 niveau)")
  end
end
