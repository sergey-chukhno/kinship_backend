module Custom
  class ContactParticipant
    include ActiveModel::Model
    attr_accessor :subject, :message, :sender_id, :recipient_id

    SUBJECTS = %w[Stage Projet Autre].freeze

    validates :subject, :message, :sender_id, :recipient_id, presence: true
    validates :subject, inclusion: {in: SUBJECTS}
  end
end
