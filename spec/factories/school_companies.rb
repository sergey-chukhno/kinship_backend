FactoryBot.define do
  factory :school_company do
    school { create(:school) }
    company { create(:company) }

    trait :pending do
      status { :pending }
    end

    trait :confirmed do
      status { :confirmed }
    end
  end
end
