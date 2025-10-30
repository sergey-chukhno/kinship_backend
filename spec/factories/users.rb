require "faker"

FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    password { "Password123!" }
    role { "tutor" }
    role_additional_information { "tutor" }
    accept_privacy_policy { true }

    trait :teacher do
      role { "school_teacher" }
      sequence(:email) { |n| "teacher#{n}@ac-nantes.fr" }
    end

    trait :school_teacher do
      role { "school_teacher" }
      sequence(:email) { |n| "teacher#{n}@ac-nantes.fr" }
    end

    trait :voluntary do
      role { "voluntary" }
    end

    trait :tutor do
      role { "tutor" }
    end

    trait :confirmed do
      after(:create) { |user| user.confirm }
    end
  end
end
