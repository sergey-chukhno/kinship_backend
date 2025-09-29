FactoryBot.define do
  factory :contract do
    start_date { Time.now }

    trait :active do
      active { true }
      start_date { Time.now }
      end_date { Time.now + 1.year }
    end

    trait :expired do
      active { false }
      start_date { Time.now - 1.year }
      end_date { Time.now }
    end

    trait :school do
      school { create(:school, :confirmed) }

      after(:build) do |contract|
        contract.school.user_schools << create(:user_school, :owner, :confirmed, school: contract.school)
      end
    end

    trait :company do
      company { create(:company, :confirmed) }

      after(:build) do |contract|
        contract.company.user_companies << create(:user_company, :owner, :confirmed, company: contract.company)
      end
    end
  end
end
