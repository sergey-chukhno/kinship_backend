# frozen_string_literal: true

class AdminPanel::Company::CompanyMemberCardComponentPreview < ViewComponent::Preview
  layout "lookbook"

  def default
    render(AdminPanel::Company::CompanyMemberCard::CompanyMemberCardComponent.new(UserCompany.first))
  end
end
