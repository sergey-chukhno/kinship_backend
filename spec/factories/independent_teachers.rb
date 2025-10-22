FactoryBot.define do
  factory :independent_teacher do
    user { nil }  # Must be provided explicitly
    organization_name { "Enseignant Indépendant" }
    city { "Paris" }
    description { "Cours particuliers et soutien scolaire" }
    status { :active }
    
    trait :with_contract do
      after(:create) do |independent_teacher|
        Contract.create!(
          contractable: independent_teacher,
          active: true,
          start_date: 1.month.ago,
          end_date: 1.year.from_now
        )
      end
    end
    
    trait :paused do
      status { :paused }
    end
    
    trait :archived do
      status { :archived }
    end
  end
end

