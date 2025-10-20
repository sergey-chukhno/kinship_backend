FactoryBot.define do
  factory :teacher_school_level do
    association :user, factory: [:user, :teacher]
    association :school_level
    is_creator { false }
    assigned_at { Time.current }
    
    trait :creator do
      is_creator { true }
    end
    
    trait :assigned do
      is_creator { false }
    end
  end
end
