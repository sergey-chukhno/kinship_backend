FactoryBot.define do
  factory :user_badge do
    project_title { Faker::Lorem.sentence }
    project_description { Faker::Lorem.paragraph }
    association :sender, factory: :user
    association :receiver, factory: :user
    association :badge, :level_1
    association :project
    association :organization, factory: :school

    trait :level_1 do
      association :badge, :level_1
    end

    trait :level_2 do
      association :badge, :level_2
      after(:build) do |user_badge|
        user_badge.documents.attach(io: File.open(Rails.root.join("spec", "factories", "files", "badge.webp")),
          filename: "badge.webp", content_type: "image/webp")
      end
    end

    trait :level_3 do
      association :badge, :level_3
      after(:build) do |user_badge|
        user_badge.documents.attach(io: File.open(Rails.root.join("spec", "factories", "files", "badge.webp")),
          filename: "badge.webp", content_type: "image/webp")
      end
    end

    trait :level_4 do
      association :badge, :level_4
      after(:build) do |user_badge|
        user_badge.documents.attach(io: File.open(Rails.root.join("spec", "factories", "files", "badge.webp")),
          filename: "badge.webp", content_type: "image/webp")
      end
    end

    trait :pending do
      status { :pending }
    end

    trait :approved do
      status { :approved }
    end

    trait :rejected do
      status { :rejected }
    end
  end
end
