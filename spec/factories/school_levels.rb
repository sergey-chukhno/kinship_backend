FactoryBot.define do
  factory :school_level do
    name { "Paquerette" }
    level { "sixieme" }
    school { create(:school, school_type: "college") }
  end
end
