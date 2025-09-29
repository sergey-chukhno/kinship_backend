FactoryBot.define do
  factory :availability do
    user { create(:user) }
    monday { false }
    tuesday { false }
    wednesday { false }
    thursday { false }
    friday { false }
    saturday { false }
    sunday { false }
    other { false }
  end
end
