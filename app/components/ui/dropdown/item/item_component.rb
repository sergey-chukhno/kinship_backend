# frozen_string_literal: true

class Ui::Dropdown::Item::ItemComponent < ViewComponent::Base
  BUILDER_OPTIONS = %i[button link button_to]
  STYLE_OPTIONS = %i[default destructive]

  def initialize(builder:, style: :default, **options)
    super

    @buidler = builder if valid_builder?(builder)
    @options = options
    @options[:class] = classes(style)
  end

  private

  def classes(style)
    classes = [@options[:class]]
    classes << "dropdown-item"
    classes << "dropdown-item--#{style}"
    classes.join(" ")
  end

  def valid_builder?(builder)
    return true if BUILDER_OPTIONS.include?(builder)

    raise ArgumentError, "Invalid builder: #{builder}"
  end
end
