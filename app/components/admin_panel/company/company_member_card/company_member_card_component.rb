# frozen_string_literal: true

class AdminPanel::Company::CompanyMemberCard::CompanyMemberCardComponent < ViewComponent::Base
  def initialize(company_member)
    @company_member = company_member
    @member = company_member.user
  end

  def contracted?
    @company_member.company.active_contract?
  end
end
