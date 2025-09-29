class UserSchool < ApplicationRecord
  after_create :set_status

  belongs_to :school
  belongs_to :user

  enum :status, {pending: 0, confirmed: 1}, default: :pending

  validates :status, presence: true
  validates :user_id, uniqueness: {scope: :school_id}
  validate :unique_owner_by_school

  after_validation :set_admin_if_owner
  after_validation :set_access_badges_if_admin

  private

  def unique_owner_by_school
    return unless owner
    return if self == self.class.find_by(owner: true, school_id: school_id)
    return if self.class.where(owner: true, school_id: school_id).count.zero?

    errors.add(:owner, "Il ne peut y avoir qu'un seul propriétaire par établissement")
  end

  def set_status
    return update(status: :confirmed) unless user.teacher?

    update(status: :pending)
  end

  def set_admin_if_owner
    return unless owner? && !admin?

    update(admin: true)
  end

  def set_access_badges_if_admin
    return unless admin? && !can_access_badges?

    update(can_access_badges: true)
  end
end
