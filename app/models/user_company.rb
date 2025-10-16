class UserCompany < ApplicationRecord
  belongs_to :user
  belongs_to :company

  enum :status, {pending: 0, confirmed: 1}, default: :pending
  enum :role, {
    member: 0,
    intervenant: 1,
    referent: 2,
    admin: 3,
    superadmin: 4
  }, default: :member

  validates :status, :role, presence: true
  validates :user_id, uniqueness: {scope: :company_id}
  validate :unique_superadmin_by_company

  # Permission check methods
  def can_manage_members?
    admin? || superadmin?
  end

  def can_manage_superadmins?
    false  # Only system-level super_admin can manage superadmins
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

  def can_create_project?
    referent? || admin? || superadmin?
  end

  def is_owner?
    superadmin?
  end

  # Backward compatibility alias
  alias_method :owner?, :superadmin?

  private

  def unique_superadmin_by_company
    return unless superadmin?
    return if self == self.class.find_by(role: :superadmin, company_id: company_id)
    return if self.class.where(role: :superadmin, company_id: company_id).count.zero?

    errors.add(:role, "Il ne peut y avoir qu'un seul superadmin par entreprise")
  end
end
