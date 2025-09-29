# frozen_string_literal: true

class Ui::Link::LinkComponent < ViewComponent::Base
  BUILDER_OPTIONS = %i[button link button_to]

  def initialize(builder:, **options)
    super

    @buidler = builder if valid_builder?(builder)
    @options = options
    @options[:class] = classes
  end

  private

  def classes
    classes = [@options[:class]]
    classes << "link"
    classes.join(" ")
  end

  def valid_builder?(builder)
    return true if BUILDER_OPTIONS.include?(builder)

    raise ArgumentError, "Invalid builder: #{builder}"
  end
end
