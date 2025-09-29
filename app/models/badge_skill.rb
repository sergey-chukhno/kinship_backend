class BadgeSkill < ApplicationRecord
  has_many :user_badge_skills, dependent: :destroy
  belongs_to :badge

  enum :category, {domain: 0, expertise: 1}, default: 0

  validates :name, :category, presence: true
end
