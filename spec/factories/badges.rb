FactoryBot.define do
  factory :badge do
    name { Faker::Lorem.word }
    level { rand(0..3) }
    description { Faker::Lorem.sentence }
    series { "Série TouKouLeur" }

    after(:build) do |badge|
      badge.icon.attach(io: File.open(Rails.root.join("spec", "factories", "files", "badge.webp")),
        filename: "badge.webp", content_type: "image/webp")
    end

    trait :level_1 do
      level { :level_1 }
    end

    trait :level_2 do
      level { :level_2 }
    end

    trait :level_3 do
      level { :level_3 }
    end

    trait :level_4 do
      level { :level_4 }
    end
  end
end
