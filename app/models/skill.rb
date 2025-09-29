class Skill < ApplicationRecord
  has_many :user_skills, dependent: :destroy
  has_many :users, through: :user_skills

  has_many :company_skills, dependent: :destroy

  has_many :project_skills, dependent: :destroy
  has_many :projects, through: :project_skills

  has_many :sub_skills, dependent: :destroy

  accepts_nested_attributes_for :sub_skills, allow_destroy: true

  validates :name, presence: true
  validates :official, inclusion: {in: [true, false]}

  scope :officials, -> { where(official: true) }
end
