FactoryBot.define do
  factory :partnership_member do
    association :partnership
    association :participant, factory: :company
    member_status { :pending }
    role_in_partnership { :partner }
    joined_at { Time.current }
    
    trait :confirmed do
      member_status { :confirmed }
      confirmed_at { Time.current }
    end
    
    trait :declined do
      member_status { :declined }
    end
    
    trait :sponsor do
      role_in_partnership { :sponsor }
      member_status { :confirmed }
      confirmed_at { Time.current }
    end
    
    trait :beneficiary do
      role_in_partnership { :beneficiary }
    end
    
    trait :with_school do
      association :participant, factory: :school
    end
    
    trait :with_company do
      association :participant, factory: :company
    end
  end
end
