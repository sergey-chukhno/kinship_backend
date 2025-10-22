FactoryBot.define do
  factory :project_member do
    user { create(:user, :confirmed) }
    project { create(:project) }
    status { :pending }
    role { :member }

    trait :pending do
      status { :pending }
    end

    trait :confirmed do
      status { :confirmed }
    end

    trait :member do
      role { :member }
    end

    trait :admin do
      role { :admin }
      status { :confirmed }
    end

    trait :co_owner do
      role { :co_owner }
      status { :confirmed }
    end
  end
end
