class ParentChildInfo < ApplicationRecord
  belongs_to :parent_user, class_name: "User", foreign_key: :parent_user_id
  belongs_to :school, optional: true
  belongs_to :school_level, optional: true, foreign_key: :class_id
  belongs_to :linked_user, class_name: "User", foreign_key: :linked_user_id, optional: true

  validates :parent_user_id, presence: true

  scope :unlinked, -> { where(linked_user_id: nil) }
  scope :linked, -> { where.not(linked_user_id: nil) }

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def linked?
    linked_user_id.present?
  end
end

