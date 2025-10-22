FactoryBot.define do
  factory :user_school do
    school { create(:school) }
    user { create(:user) }
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

    trait :intervenant do
      role { :intervenant }
    end

    trait :referent do
      role { :referent }
    end

    trait :admin do
      role { :admin }
    end

    trait :superadmin do
      role { :superadmin }
    end

    # Legacy alias for backward compatibility
    trait :owner do
      role { :superadmin }
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
