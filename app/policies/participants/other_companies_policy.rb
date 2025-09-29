class Participants::OtherCompaniesPolicy < Participants::BasePolicy
  class Scope < Scope
    def resolve
      sponsorships = user.user_schools.confirmed.map { |user_school| user_school.school.school_companies.confirmed }.flatten.map(&:company)
      companies = user.user_company.confirmed.map { |user_company| user_company.company }
      company_sponsors = companies.map { |company| company.company_partners.confirmed }.flatten.map(&:company)
      reverse_company_sponsors = companies.map { |company| company.reverse_company_partners.confirmed }.flatten.map(&:company_sponsor)

      (sponsorships + companies + company_sponsors + reverse_company_sponsors).uniq
    end
  end
end
