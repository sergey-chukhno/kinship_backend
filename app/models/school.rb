class School < ApplicationRecord
  # == Schema Information
  #
  # Table name: schools
  #
  # id                      :bigint     not null, primary key
  # name                    :string     not null
  # zip_code                :string     not null
  # city                    :string     not null
  # school_type             :integer    not null
  # status                  :integer    not null
  # referent_phone_number   :string
  #

  include PgSearch::Model

  has_many :school_levels, dependent: :destroy
  has_many :user_schools, dependent: :destroy
  has_many :users, through: :user_schools
  
  # Legacy partnership associations (kept for backward compatibility)
  has_many :school_companies, dependent: :destroy
  has_many :companies, through: :school_companies
  
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
  belongs_to :parent_school, class_name: 'School', optional: true
  has_many :branch_schools, 
           class_name: 'School', 
           foreign_key: :parent_school_id, 
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
  
  has_many :contracts, as: :contractable, dependent: :destroy

  has_one_attached :logo

  accepts_nested_attributes_for :school_levels, allow_destroy: true

  enum :school_type, [:primaire, :college, :lycee, :erea, :medico_social, :service_administratif, :information_et_orientation, :autre], default: :primaire
  enum :status, {pending: 0, confirmed: 1}, default: :pending

  validates :name, :zip_code, :school_type, :city, :status, presence: true
  validate :logo_format
  
  # Branch validations (Change #4)
  validate :cannot_be_own_branch
  validate :cannot_have_circular_branch_reference
  validate :branch_cannot_have_branches

  pg_search_scope :by_full_name, against: [:name, :city, :zip_code],
    using: {
      tsearch: {
        prefix: true
      }
    }

  scope :by_zip_code, ->(zip_code) { where(zip_code:) }
  scope :by_school_type, ->(school_type) { where(school_type:) }

  def full_name
    "#{name}, #{city} (#{zip_code})"
  end

  def owner?
    user_schools.where(role: :superadmin).any?
  end

  def owner
    user_schools.find_by(role: :superadmin)
  end

  def admins?
    user_schools.where(role: [:admin, :superadmin]).any?
  end

  def admins
    user_schools.where(role: [:admin, :superadmin])
  end

  def superadmin_user?(user)
    user_schools.find_by(user: user)&.superadmin?
  end

  def users_waiting_for_confirmation?
    user_schools.where(status: :pending).any?
  end

  def users_waiting_for_confirmation
    user_schools.where(status: :pending)
  end

  def companies_waiting_for_confirmation?
    school_companies.where(status: :pending).any?
  end

  def active_contract?
    contracts.where(active: true).any?
  end

  def active_contract
    contracts.find_by(active: true)
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
      .joins("INNER JOIN companies ON companies.id = partnership_members.participant_id")
      .select('DISTINCT companies.*')
  end
  
  def partner_schools
    active_partnerships
      .joins(:partnership_members)
      .where(partnership_members: {participant_type: 'School'})
      .where.not(partnership_members: {participant_id: id})
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
      .joins("INNER JOIN companies ON companies.id = partnership_members.participant_id")
      .select('DISTINCT companies.*')
  end
  
  def shared_member_schools
    active_partnerships
      .sharing_members
      .joins(:partnership_members)
      .where(partnership_members: {participant_type: 'School'})
      .where.not(partnership_members: {participant_id: id})
      .joins("INNER JOIN schools ON schools.id = partnership_members.participant_id")
      .select('DISTINCT schools.*')
  end
  
  def shared_project_companies
    active_partnerships
      .sharing_projects
      .joins(:partnership_members)
      .where(partnership_members: {participant_type: 'Company'})
      .joins("INNER JOIN companies ON companies.id = partnership_members.participant_id")
      .select('DISTINCT companies.*')
  end
  
  def shared_project_schools
    active_partnerships
      .sharing_projects
      .joins(:partnership_members)
      .where(partnership_members: {participant_type: 'School'})
      .where.not(partnership_members: {participant_id: id})
      .joins("INNER JOIN schools ON schools.id = partnership_members.participant_id")
      .select('DISTINCT schools.*')
  end
  
  def partnered_with?(organization)
    active_partnerships.exists?(
      partnership_members: {participant: organization, member_status: :confirmed}
    )
  end
  
  def partnership_with(organization)
    active_partnerships.for_organization(organization).first
  end

  # ========================================
  # BRANCH SYSTEM METHODS (Change #4)
  # ========================================
  
  # Scopes
  def self.main_schools
    where(parent_school_id: nil)
  end
  
  def self.branch_schools
    where.not(parent_school_id: nil)
  end
  
  # Status checks
  def main_school?
    parent_school_id.nil?
  end
  
  def branch?
    parent_school_id.present?
  end
  
  # Branch management
  def all_branch_schools
    branch_schools
  end
  
  def all_members_including_branches
    if main_school?
      User.joins(:user_schools)
          .where(user_schools: {school_id: [id] + branch_schools.pluck(:id), status: :confirmed})
          .distinct
    else
      User.joins(:user_schools)
          .where(user_schools: {school_id: id, status: :confirmed})
          .distinct
    end
  end
  
  def all_school_levels_including_branches
    if main_school?
      SchoolLevel.where(school_id: [id] + branch_schools.pluck(:id))
    else
      school_levels
    end
  end
  
  def members_visible_to_branch?(branch)
    branch.parent_school == self && share_members_with_branches
  end
  
  def school_levels_visible_to_branch?(branch)
    branch.parent_school == self  # Parent can always see branch school levels
  end
  
  # Branch request management
  def request_to_become_branch_of(parent_school)
    BranchRequest.create!(
      parent: parent_school,
      child: self,
      initiator: self
    )
  end
  
  def invite_as_branch(child_school)
    BranchRequest.create!(
      parent: self,
      child: child_school,
      initiator: self
    )
  end
  
  def detach_branch(branch)
    return false unless branch.parent_school == self
    branch.update(parent_school: nil)
  end
  
  def detach_from_parent
    return false unless parent_school.present?
    update(parent_school: nil)
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
    return unless id.present? && parent_school_id.present?
    
    if id == parent_school_id
      errors.add(:parent_school, "ne peut pas être elle-même")
    end
  end
  
  def cannot_have_circular_branch_reference
    return unless parent_school_id.present? && parent_school_id_changed? && persisted?
    
    # Check if parent is already a branch of this school
    current = School.find_by(id: parent_school_id)
    return unless current
    
    # Check one level up (sufficient for 1-level depth enforcement)
    if current.parent_school_id == id
      errors.add(:parent_school, "créerait une référence circulaire")
    end
  end
  
  def branch_cannot_have_branches
    return unless parent_school_id.present?
    
    # Check if the parent is already a branch (has a parent itself)
    parent = School.find_by(id: parent_school_id)
    return unless parent&.parent_school_id.present?
    
    errors.add(:base, "Une annexe ne peut pas avoir de sous-annexes (profondeur max: 1 niveau)")
  end
end
