class ProjectSchoolLevel < ApplicationRecord
  belongs_to :school_level
  belongs_to :project

  validates :school_level_id, uniqueness: {scope: :project_id, message: "Ce niveau existe déjà pour ce projet"}
end
