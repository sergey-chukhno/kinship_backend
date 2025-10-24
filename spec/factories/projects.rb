require "faker"

FactoryBot.define do
  factory :project do
    title { Faker::Lorem.word }
    description { "the description of my project" }
    start_date { DateTime.parse("2023-07-07 10:02:14") }
    end_date { DateTime.parse("2023-07-10 10:02:14") }
    owner { create(:user) }
    partnership { nil }  # Regular project by default
    companies { [create(:company)] }  # Include company by default to satisfy validation
    
    trait :with_school_levels do
      companies { [] }  # Remove companies
      school_levels { [create(:school_level)] }  # Add school levels instead
    end
    
    trait :with_both do
      companies { [create(:company)] }
      school_levels { [create(:school_level)] }
    end
    
    trait :partner_project do
      partnership { create(:partnership, :with_school_and_company, :confirmed) }
    end
    
    trait :with_partnership do
      association :partnership, factory: [:partnership, :with_two_companies, :confirmed]
    end
  end
end
