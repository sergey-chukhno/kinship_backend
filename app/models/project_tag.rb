class ProjectTag < ApplicationRecord
  belongs_to :tag
  belongs_to :project

  validates :tag_id, uniqueness: {scope: :project_id}
end
