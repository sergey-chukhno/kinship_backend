require "faker"

FactoryBot.define do
  factory :school do
    name { Faker::University.name }
    school_type { "lycee" }
    zip_code { "44200" }
    city { "Nantes" }
    status { "confirmed" }
    referent_phone_number { "0606060606" }

    trait :pending do
      status { "pending" }
    end

    trait :confirmed do
      status { "confirmed" }
    end
    
    # Branch traits (Change #4)
    trait :branch do
      parent_school { association :school }
    end
    
    trait :with_branches do
      after(:create) do |school|
        create_list(:school, 2, parent_school: school)
      end
    end
    
    trait :sharing_members_with_branches do
      share_members_with_branches { true }
    end
  end
end
