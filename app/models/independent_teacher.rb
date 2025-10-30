# Independent Teacher Model
# Allows teachers to operate independently with individual contracts
# Teacher can be BOTH independent AND affiliated with schools/companies
class IndependentTeacher < ApplicationRecord
  belongs_to :user
  has_many :contracts, as: :contractable, dependent: :destroy
  has_many :user_badges, as: :organization, dependent: :nullify
  
  # Status: active (operating), paused (temporarily inactive), archived (historical)
  enum :status, {
    active: 0,      # Currently operating as independent teacher
    paused: 1,      # Temporarily paused (e.g., full-time at school)
    archived: 2     # No longer active (historical record)
  }, default: :active
  
  validates :user_id, presence: true, uniqueness: true
  validates :organization_name, presence: true
  validates :status, presence: true
  validate :user_must_be_teacher
  
  before_validation :set_default_organization_name, on: :create
  
  scope :active_teachers, -> { where(status: :active) }
  scope :with_contracts, -> { joins(:contracts).where(contracts: {active: true}).distinct }
  
  # Check if has active contract
  def active_contract?
    return false unless active?
    
    contracts.where(active: true)
            .where('start_date <= ?', Time.current)
            .where('end_date IS NULL OR end_date >= ?', Time.current)
            .exists?
  end
  
  # Get current active contract
  def current_contract
    return nil unless active?
    
    contracts.where(active: true)
            .where('start_date <= ?', Time.current)
            .where('end_date IS NULL OR end_date >= ?', Time.current)
            .order(start_date: :desc)
            .first
  end
  
  # Name for display (used in badge assignments, etc.)
  def name
    organization_name
  end
  
  # Can assign badges? (requires active status + contract)
  def can_assign_badges?
    active? && active_contract?
  end
  
  # Pause independent status (manual action by teacher)
  def pause!
    update(status: :paused)
  end
  
  # Reactivate independent status
  def activate!
    update(status: :active)
  end
  
  # Archive (permanent deactivation, keeps history)
  def archive!
    update(status: :archived)
  end
  
  # Check if teacher has any school affiliations
  def teacher_has_school_affiliations?
    user.user_schools.confirmed.any?
  end
  
  # Suggest pausing if teacher is full-time at school (UI helper)
  def should_suggest_pausing?
    active? && 
    user.user_schools.where(role: [:superadmin, :admin, :referent], status: :confirmed).any?
  end
  
  private
  
  def user_must_be_teacher
    return if User.is_teacher_role?(user&.role)
    errors.add(:user, "Independent teacher status is only available for users with role 'teacher'")
  end
  
  def set_default_organization_name
    return if organization_name.present?
    self.organization_name = "#{user.full_name} - Enseignant Indépendant"
  end
end

