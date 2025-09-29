# frozen_string_literal: true

module SmallCardInfo
  class OwnerComponent < ViewComponent::Base
    include SvgHelper

    def initialize(owner:)
      super
      @owner = owner
    end

    def which_avatar
      return "teacher" if @owner.teacher?

      "user"
    end
  end
end
