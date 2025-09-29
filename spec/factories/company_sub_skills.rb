FactoryBot.define do
  factory :company_sub_skill do
    company { create(:company) }
    sub_skill { create(:sub_skill) }
  end
end
