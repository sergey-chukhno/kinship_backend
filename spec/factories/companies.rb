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
  end
end
