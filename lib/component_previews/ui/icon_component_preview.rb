# frozen_string_literal: true

class Ui::IconComponentPreview < ViewComponent::Preview
  layout "lookbook"

  # @!group Preview

  def size_12
    render(Ui::Icon::IconComponent.new(icon: "award", size: "12", color: "dark-01"))
  end

  def size_16
    render(Ui::Icon::IconComponent.new(icon: "award", size: "16", color: "dark-01"))
  end

  def size_24
    render(Ui::Icon::IconComponent.new(icon: "award", size: "24", color: "dark-01"))
  end

  def size_32
    render(Ui::Icon::IconComponent.new(icon: "award", size: "32", color: "dark-01"))
  end

  # @!endgroup
end
