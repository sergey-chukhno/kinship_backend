class UserSchoolLevel < ApplicationRecord
  belongs_to :user
  belongs_to :school_level

  validates :user_id, uniqueness: {scope: :school_level_id}
end
