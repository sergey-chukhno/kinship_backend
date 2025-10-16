class UserSchool < ApplicationRecord
  after_create :set_status

  belongs_to :school
  belongs_to :user

  enum :status, {pending: 0, confirmed: 1}, default: :pending
  enum :role, {
    member: 0,
    intervenant: 1,
    referent: 2,
    admin: 3,
    superadmin: 4
  }, default: :member

  validates :status, :role, presence: true
  validates :user_id, uniqueness: {scope: :school_id}
  validate :unique_superadmin_by_school

  # Permission check methods
  def can_manage_members?
    admin? || superadmin?
  end

  def can_manage_projects?
    referent? || admin? || superadmin?
  end

  def can_assign_badges?
    intervenant? || referent? || admin? || superadmin?
  end

  def can_manage_partnerships?
    superadmin?
  end

  def can_manage_branches?
    superadmin?
  end

  def is_owner?
    superadmin?
  end

  # Backward compatibility alias
  alias_method :owner?, :superadmin?

  private

  def unique_superadmin_by_school
    return unless superadmin?
    return if self == self.class.find_by(role: :superadmin, school_id: school_id)
    return if self.class.where(role: :superadmin, school_id: school_id).count.zero?

    errors.add(:role, "Il ne peut y avoir qu'un seul superadmin par établissement")
  end

  def set_status
    return update(status: :confirmed) unless user.teacher?

    update(status: :pending)
  end
end
