FactoryBot.define do
  factory :link do
    name { "Test link" }
    url { Faker::Internet.url(scheme: "https") }
    project { create(:project) }
  end
end
