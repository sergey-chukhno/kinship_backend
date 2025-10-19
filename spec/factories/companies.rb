FactoryBot.define do
  factory :company do
    name { Faker::Company.name }
    zip_code { Faker::Address.zip_code }
    city { Faker::Address.city }
    referent_phone_number { Faker::PhoneNumber.phone_number }
    description { Faker::Lorem.paragraph }
    company_type { create(:company_type) }
    email { Faker::Internet.email }
    siret_number { Faker::Number.number(digits: 14) }

    trait :pending do
      status { :pending }
    end

    trait :confirmed do
      status { :confirmed }
    end
    
    # Branch traits (Change #4)
    trait :branch do
      parent_company { association :company }
    end
    
    trait :with_branches do
      after(:create) do |company|
        create_list(:company, 2, parent_company: company)
      end
    end
    
    trait :sharing_members_with_branches do
      share_members_with_branches { true }
    end
  end
end
