FactoryBot.define do
  factory :user_company do
    user { create(:user) }
    company { create(:company) }

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

    trait :pending_company do
      company { create(:company, :pending) }
    end

    trait :confirmed_company do
      company { create(:company, :confirmed) }
    end

    trait :tutor_user do
      user { create(:user, :tutor) }
    end

    trait :voluntary_user do
      user { create(:user, :voluntary) }
    end
  end
end
