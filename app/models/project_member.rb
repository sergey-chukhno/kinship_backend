class ProjectMember < ApplicationRecord
  belongs_to :user
  belongs_to :project

  has_many :teams, through: :user
  has_many :badges_received, through: :user

  enum :status, {pending: 0, confirmed: 1}, default: :pending
  enum :role, {
    member: 0,      # Regular participant
    admin: 1,       # Project administrator
    co_owner: 2     # Co-owner with elevated rights
  }, default: :member

  validates :status, :role, presence: true
  validates :user_id, uniqueness: {scope: :project_id}
  
  after_validation :set_co_owner_if_project_owner, on: [:create, :update]

  # Permission methods
  def can_edit_project?
    admin? || co_owner?
  end

  def can_manage_members?
    admin? || co_owner?
  end

  def can_create_teams?
    admin? || co_owner?
  end

  def can_assign_badges?
    return false unless admin? || co_owner?
    # Also check if user has badge permission in affiliated organizations
    user.can_give_badges_in_project?(project)
  end

  def can_close_project?
    co_owner?
  end

  def can_delete_project?
    co_owner? && project.owner == user  # Only primary owner
  end

  def can_add_co_owners?
    co_owner?
  end

  def is_primary_owner?
    co_owner? && project.owner == user
  end

  # Backward compatibility
  def admin_rights?
    admin? || co_owner?
  end

  private

  def set_co_owner_if_project_owner
    return if co_owner?
    return unless project&.owner == user

    self.role = :co_owner
  end
end
