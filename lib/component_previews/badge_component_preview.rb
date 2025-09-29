# frozen_string_literal: true

class BadgeComponentPreview < ViewComponent::Preview
  layout "lookbook"

  def default
    render(Badge::BadgeComponent.new(badge: Badge.first))
  end
end
