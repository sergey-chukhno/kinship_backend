# frozen_string_literal: true

class Ui::Button::ButtonComponent < ViewComponent::Base
  BUILDER_OPTIONS = %i[button link button_to]
  STYLE_OPTIONS = %i[primary secondary ghost]
  SIZE_OPTIONS = %i[sm md]

  def initialize(
    builder:,
    style:,
    size: :md,
    full: false,
    square: false,
    rounded: false,
    **options
  )
    super

    @buidler = builder if valid_builder?(builder)
    @options = options
    @options[:class] = classes(style:, size:, full:, square:, rounded:)
  end

  private

  def classes(style:, size:, full:, square:, rounded:)
    classes = [@options[:class]]
    classes << "button"
    classes << "button--#{style}" if valid_style?(style)
    classes << "button--#{size}" if valid_size?(size)
    classes << "button--full" if full
    classes << "button--square" if square
    classes << "button--rounded" if rounded
    classes.join(" ")
  end

  def valid_builder?(builder)
    return true if BUILDER_OPTIONS.include?(builder)

    raise ArgumentError, "Invalid builder: #{builder}"
  end

  def valid_style?(style)
    return true if STYLE_OPTIONS.include?(style)

    raise ArgumentError, "Invalid style: #{style}"
  end

  def valid_size?(size)
    return true if SIZE_OPTIONS.include?(size)

    raise ArgumentError, "Invalid size: #{size}"
  end
end
