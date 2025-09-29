# frozen_string_literal: true

class Ui::Tooltip::TooltipComponent < ViewComponent::Base
  def initialize(message:)
    super

    @message = message
  end
end
