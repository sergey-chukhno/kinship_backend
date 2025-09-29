require "faker"

FactoryBot.define do
  factory :keyword do
    project { create(:project) }
    name { Faker::Lorem.word }
  end
end
