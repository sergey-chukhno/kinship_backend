class UserCompany < ApplicationRecord
  belongs_to :user
  belongs_to :company

  enum :status, {pending: 0, confirmed: 1}, default: :pending

  validates :status, presence: true
  validates :user_id, uniqueness: {scope: :company_id}
  # validate :user_not_teacher
  validate :unique_owner_by_company

  after_validation :set_admin_if_owner, :set_create_project_if_admin, :set_access_badges_if_admin

  private

  def unique_owner_by_company
    return unless owner
    return if self == self.class.find_by(owner: true, company_id: company_id)
    return if self.class.where(owner: true, company_id: company_id).count.zero?

    errors.add(:owner, "Il ne peut y avoir qu'un seul propriétaire par association")
  end

  # def user_not_teacher
  #   return unless user&.teacher?

  #   errors.add(:user, "Un enseignant ne peut pas être associé à une association")
  # end

  def set_admin_if_owner
    return unless owner? && !admin?

    update(admin: true)
  end

  def set_access_badges_if_admin
    return unless admin? && !can_access_badges?

    update(can_access_badges: true)
  end

  def set_create_project_if_admin
    return unless admin? && !can_create_project?

    update(can_create_project: true)
  end
end
