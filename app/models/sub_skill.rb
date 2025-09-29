class SubSkill < ApplicationRecord
  belongs_to :skill

  has_many :user_sub_skills, dependent: :destroy
  has_many :users, through: :user_sub_skills
  has_many :company_sub_skills, dependent: :destroy
  validates :name, presence: true, uniqueness: {scope: :skill_id}
end
