require "faker"

FactoryBot.define do
  factory :skill do
    name { Faker::Name.first_name }
    official { false }
  end

  trait :official do
    official { true }
  end
end
