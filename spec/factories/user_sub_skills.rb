FactoryBot.define do
  factory :user_sub_skill do
    user { create(:user) }
    sub_skill { create(:sub_skill) }
  end
end
