# frozen_string_literal: true

module SmallCardInfo
  class AddParticipantsComponent < ViewComponent::Base
    include SvgHelper

    def initialize(owner:, project_id:)
      super
      @owner = owner
      @project_id = project_id
    end
  end
end
