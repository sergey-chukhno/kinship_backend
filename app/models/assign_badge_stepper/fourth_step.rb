module AssignBadgeStepper
  class FourthStep
    include ActiveModel::Model
    include ActiveModel::Translation

    attr_accessor :expertise_ids, :domain_ids, :badge_skill_ids

    validates :expertise_ids, :domain_ids, presence: true
  end
end
