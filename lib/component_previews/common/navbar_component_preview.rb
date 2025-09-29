# frozen_string_literal: true

class Common::NavbarComponentPreview < ViewComponent::Preview
  layout "lookbook"

  def default
    render(Common::Navbar::NavbarComponent.new(User.first))
  end
end
