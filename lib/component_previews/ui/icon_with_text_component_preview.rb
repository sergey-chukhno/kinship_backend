# frozen_string_literal: true

class Ui::IconWithTextComponentPreview < ViewComponent::Preview
  layout "lookbook"

  def default
    render(Ui::IconWithText::IconWithTextComponent.new(icon: "new/job", text: "Text", color: "primary"))
  end
end
