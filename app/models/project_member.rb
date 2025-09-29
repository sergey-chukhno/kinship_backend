class ProjectMember < ApplicationRecord
  belongs_to :user
  belongs_to :project

  has_many :teams, through: :user
  has_many :badges_received, through: :user

  enum :status, {pending: 0, confirmed: 1}, default: :pending

  validates :status, presence: true
  validates :user_id, uniqueness: {scope: :project_id}
  after_validation :set_admin_if_project_owner, on: [:create, :update]

  private

  def set_admin_if_project_owner
    return if admin?
    return unless project.owner == user

    update(admin: true)
  end
end
