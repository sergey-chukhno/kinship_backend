require "faker"

FactoryBot.define do
  factory :project do
    title { Faker::Lorem.word }
    description { "the description of my project" }
    start_date { DateTime.parse("2023-07-07 10:02:14") }
    end_date { DateTime.parse("2023-07-10 10:02:14") }
    owner { create(:user, admin: true) }
  end
end
