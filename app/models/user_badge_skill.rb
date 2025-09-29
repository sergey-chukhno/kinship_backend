class UserBadgeSkill < ApplicationRecord
  belongs_to :user_badge
  belongs_to :badge_skill
end
