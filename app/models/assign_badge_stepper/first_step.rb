module AssignBadgeStepper
  class FirstStep
    include ActiveModel::Model

    attr_accessor :receiver_id, :sender_id, :organization, :organization_id, :organization_type

    validates :receiver_id, presence: true
    validates :sender_id, presence: true
    validates :organization, presence: true

    validate :organization_is_valid

    def receiver
      User.find(receiver_id)
    end

    private

    def organization_is_valid
      case organization_type
      when "School"
        errors.add(:organization, "Organization non valid") unless School.exists?(organization_id)
      when "Company"
        errors.add(:organization, "Organization non valid") unless Company.exists?(organization_id)
      else
        errors.add(:organization, "Organization non valid")
      end
    end
  end
end
