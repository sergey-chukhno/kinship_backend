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
  end
end
