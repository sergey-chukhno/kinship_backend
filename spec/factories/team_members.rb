FactoryBot.define do
  factory :team_member do
    user { create(:user) }
    team { create(:team) }
  end
end
