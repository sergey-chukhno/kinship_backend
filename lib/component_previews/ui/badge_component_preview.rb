# frozen_string_literal: true

class Ui::BadgeComponentPreview < ViewComponent::Preview
  layout "lookbook"

  # @param color select { choices: ["green", "red", "cyan", "yellow", "purple", "grey", "light-grey", "pink"] }
  # @param content text
  def playground(color: "green", content: "Playground")
    render(Ui::Badge::BadgeComponent.new(color:).with_content(content))
  end

  # @!group Preview

  def green
    render(Ui::Badge::BadgeComponent.new(color: "green").with_content("Green"))
  end

  def red
    render(Ui::Badge::BadgeComponent.new(color: "red").with_content("Red"))
  end

  def cyan
    render(Ui::Badge::BadgeComponent.new(color: "cyan").with_content("Cyan"))
  end

  def yellow
    render(Ui::Badge::BadgeComponent.new(color: "yellow").with_content("Yellow"))
  end

  def purple
    render(Ui::Badge::BadgeComponent.new(color: "purple").with_content("Purple"))
  end

  def grey
    render(Ui::Badge::BadgeComponent.new(color: "grey").with_content("Grey"))
  end

  def light_grey
    render(Ui::Badge::BadgeComponent.new(color: "light-grey").with_content("Light Grey"))
  end

  def pink
    render(Ui::Badge::BadgeComponent.new(color: "pink").with_content("Pink"))
  end

  # @!endgroup
end
