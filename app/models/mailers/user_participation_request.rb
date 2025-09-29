module Mailers
  class UserParticipationRequest
    include ActiveModel::Model
    attr_accessor :project_id, :message, :participant_id

    validates :participant_id, :message, presence: true
  end
end
