# frozen_string_literal: true

class Ui::Icon::IconComponent < ViewComponent::Base
  SIZES = %w[12 16 20 24 32]

  def initialize(icon:, size:, color:)
    super

    @icon = icon
    @size = size if valid_size?(size)
    @color = color
  end

  private

  def valid_size?(size)
    return true if SIZES.include?(size)

    raise ArgumentError, "Invalid size: #{size}"
  end
end
