class Tag < ApplicationRecord
  has_many :project_tags, dependent: :destroy
  has_many :projects, through: :project_tags

  validates :name, presence: true, uniqueness: {case_sensitive: false}
end
