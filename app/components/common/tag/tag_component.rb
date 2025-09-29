# frozen_string_literal: true

class Common::Tag::TagComponent < ViewComponent::Base
  AVAILABLE_COLORS = %w[green confirmed red blue yellow pending purple grey light-grey pink]

  def initialize(color:)
    @color = color

    validate_color
  end

  private

  def validate_color
    raise "Invalid color #{@color}, available colors are #{AVAILABLE_COLORS}" unless AVAILABLE_COLORS.include?(@color)
  end
end
