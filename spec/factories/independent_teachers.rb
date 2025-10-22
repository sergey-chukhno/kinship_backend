FactoryBot.define do
  factory :independent_teacher do
    association :user, factory: [:user, :teacher, :confirmed]
    organization_name { "#{user.full_name} - Enseignant Indépendant" }
    city { "Paris" }
    description { "Cours particuliers et soutien scolaire" }
    status { :active }
    
    trait :with_contract do
      after(:create) do |independent_teacher|
        create(:contract, contractable: independent_teacher, active: true)
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

