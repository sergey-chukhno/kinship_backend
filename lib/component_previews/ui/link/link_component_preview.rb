# frozen_string_literal: true

class Ui::Link::LinkComponentPreview < ViewComponent::Preview
  def default
    render(Ui::Link::LinkComponent.new)
  end
end
