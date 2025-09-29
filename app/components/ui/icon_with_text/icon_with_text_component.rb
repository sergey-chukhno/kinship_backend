# frozen_string_literal: true

class Ui::IconWithText::IconWithTextComponent < ViewComponent::Base
  def initialize(icon:, text:, color:)
    super

    @icon = icon
    @text = text
    @color = color
  end
end
