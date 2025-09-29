FactoryBot.define do
  factory :company_type do
    name { Faker::Alphanumeric.alphanumeric(number: 10) }
  end
end
