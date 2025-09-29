module AssignBadgeStepper
  class ThirdStep
    include ActiveModel::Model
    include ActiveModel::Translation

    attr_accessor :badge_id

    validates :badge_id, presence: true
  end
end
