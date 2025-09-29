# frozen_string_literal: true

class Children::CardComponentPreview < ViewComponent::Preview
  layout "lookbook"

  def default
    render(Children::Card::CardComponent.new(children: User.children.first))
  end
end
