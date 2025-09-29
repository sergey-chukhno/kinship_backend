class UserSubSkill < ApplicationRecord
  belongs_to :user
  belongs_to :sub_skill

  validates :user_id, uniqueness: {scope: :sub_skill_id}
end
