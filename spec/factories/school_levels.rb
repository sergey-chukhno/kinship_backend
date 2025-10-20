FactoryBot.define do
  factory :school_level do
    name { "Paquerette" }
    level { "sixieme" }
    school { create(:school, school_type: "college") }
    
    # Traits for independent classes (Change #8)
    trait :independent do
      school { nil }
      
      after(:create) do |school_level|
        teacher = create(:user, :teacher, :confirmed)
        create(:teacher_school_level, :creator, user: teacher, school_level: school_level)
      end
    end
    
    trait :with_teacher do
      after(:create) do |school_level|
        teacher = create(:user, :teacher, :confirmed)
        create(:teacher_school_level, user: teacher, school_level: school_level)
      end
    end
    
    trait :with_teachers do
      after(:create) do |school_level|
        create_list(:teacher_school_level, 3, school_level: school_level)
      end
    end
  end
end
