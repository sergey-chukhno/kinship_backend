FactoryBot.define do
  factory :user_school_level do
    user { create(:user) }
    school_level { create(:school_level) }
  end
end
