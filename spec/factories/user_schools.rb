FactoryBot.define do
  factory :user_school do
    school { create(:school) }
    user { create(:user) }

    trait :pending do
      status { :pending }
    end

    trait :confirmed do
      status { :confirmed }
    end

    trait :admin do
      admin { true }
    end

    trait :owner do
      admin { true }
      owner { true }
    end

    trait :pending_school do
      school { create(:school, :pending) }
    end

    trait :confirmed_school do
      school { create(:school, :confirmed) }
    end

    trait :tutor_user do
      user { create(:user, :tutor) }
    end

    trait :voluntary_user do
      user { create(:user, :voluntary) }
    end
  end
end
