class Badge < ApplicationRecord
  has_many :user_badges, dependent: :destroy
  has_many :badge_skills, dependent: :destroy
  has_one_attached :icon

  accepts_nested_attributes_for :badge_skills, allow_destroy: true

  enum :level, {level_1: 0, level_2: 1, level_3: 2, level_4: 3}

  validates :name, :description, :level, :icon, presence: true

  def domains
    badge_skills.domain
  end

  def expertises
    badge_skills.expertise
  end
end
