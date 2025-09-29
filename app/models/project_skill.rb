class ProjectSkill < ApplicationRecord
  belongs_to :project
  belongs_to :skill

  validates :project_id, uniqueness: {scope: :skill_id}
end
