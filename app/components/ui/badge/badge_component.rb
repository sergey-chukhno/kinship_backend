# frozen_string_literal: true

class Ui::Badge::BadgeComponent < ViewComponent::Base
  COLORS = %w[green red cyan yellow purple grey light-grey pink]

  with_collection_parameter :text

  def initialize(text:, color:)
    super

    @text = text
    @color = color if valid_color?(color)
    @classes = classes
  end

  def classes
    classes = ["badge"]
    classes << "badge--#{@color}"
    classes.join(" ")
  end

  private

  def valid_color?(color)
    return true if COLORS.include?(color)

    raise ArgumentError, "Invalid color: #{color}"
  end
end
