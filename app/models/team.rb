class Team < ApplicationRecord
  belongs_to :project
  has_many :team_members, dependent: :destroy
  has_many :members, -> { distinct }, through: :team_members, source: :user
  has_many :users, through: :team_members

  validates :title, :description, presence: true

  accepts_nested_attributes_for :team_members, allow_destroy: true
end
