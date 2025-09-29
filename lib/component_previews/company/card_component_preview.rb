# frozen_string_literal: true

class Company::CardComponentPreview < ViewComponent::Preview
  layout "lookbook"

  def default
    render(Company::Card::CardComponent.new(company: Company.first))
  end
end
