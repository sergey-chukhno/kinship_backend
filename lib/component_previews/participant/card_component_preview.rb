# frozen_string_literal: true

class Participant::CardComponentPreview < ViewComponent::Preview
  layout "lookbook"

  def default
    render(Participant::Card::CardComponent.new(participant: User.includes(:skills).first, current_user: User.first))
  end
end
