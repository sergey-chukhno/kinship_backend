FactoryBot.define do
  factory :sub_skill do
    skill { create(:skill) }
    name { Faker::Lorem.word }
  end
end
