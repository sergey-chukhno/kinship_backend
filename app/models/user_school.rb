class UserSchool < ApplicationRecord
  after_create :set_status
  after_destroy :unassign_teacher_from_school_classes  # NEW - Change #8

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
    return update(status: :confirmed) unless User.is_teacher_role?(user.role)

    update(status: :pending)
  end
  
  # Callback: Remove teacher from school-owned classes when leaving (Change #8)
  def unassign_teacher_from_school_classes
    return unless User.is_teacher_role?(user.role)
    
    # Remove teacher from ALL classes belonging to this school
    # This includes:
    # - Classes created by teacher but transferred to school ✅
    # - Classes created by school and assigned to teacher ✅
    # But NOT:
    # - Independent classes (school_id: nil) ❌ (these remain visible)
    
    removed_count = user.teacher_school_levels
                        .joins(:school_level)
                        .where(school_levels: {school_id: school_id})
                        .destroy_all
                        .count
    
    Rails.logger.info "Removed #{removed_count} class assignments for teacher #{user.id} leaving school #{school_id}"
  end
end
