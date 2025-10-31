FactoryBot.define do
  factory :parent_child_info do
    association :parent_user, factory: :user, role: "parent"
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    birthday { Date.today - 10.years }

    trait :with_school do
      association :school
    end

    trait :with_school_level do
      association :school_level
    end

    trait :linked do
      association :linked_user, factory: :user, role: "children"
    end

    trait :unlinked do
      linked_user_id { nil }
    end
  end
end

