FactoryBot.define do
  factory :user_skill do
    user { create(:user) }
    skill { create(:skill) }
  end
end
