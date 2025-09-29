# frozen_string_literal: true

class Company::Card::CardComponent < ViewComponent::Base
  with_collection_parameter :company

  def initialize(company:)
    @company = company
    @company_skills = @company.skills.map(&:name)
    @company_type = @company.company_type.name
    @company_members = pluralize(@company.users.count, "membre", plural: "membres")
    @owner = @company.owner
  end
end
