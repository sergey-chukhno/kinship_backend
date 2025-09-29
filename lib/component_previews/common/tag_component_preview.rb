# frozen_string_literal: true

class Common::TagComponentPreview < ViewComponent::Preview
  layout "lookbook"

  # @!group Preview

  def green
    render Common::Tag::TagComponent.new(color: "green") do
      "green"
    end
  end

  def red
    render Common::Tag::TagComponent.new(color: "red") do
      "red"
    end
  end

  def blue
    render Common::Tag::TagComponent.new(color: "blue") do
      "blue"
    end
  end

  def yellow
    render Common::Tag::TagComponent.new(color: "yellow") do
      "yellow"
    end
  end

  def purple
    render Common::Tag::TagComponent.new(color: "purple") do
      "purple"
    end
  end

  def grey
    render Common::Tag::TagComponent.new(color: "grey") do
      "grey"
    end
  end

  def light_grey
    render Common::Tag::TagComponent.new(color: "light-grey") do
      "light-grey"
    end
  end

  def pink
    render Common::Tag::TagComponent.new(color: "pink") do
      "pink"
    end
  end

  # @!endgroup

  # @param color select { choices: ["green", "red", "blue", "yellow", "purple", "grey", "light-grey", "pink"] }
  # @param content text
  def playground(color: "green", content: "Tag")
    render Common::Tag::TagComponent.new(color: color) do
      content
    end
  end
end
