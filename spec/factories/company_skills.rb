FactoryBot.define do
  factory :company_skill do
    company { create(:company) }
    skill { create(:skill) }
  end
end
