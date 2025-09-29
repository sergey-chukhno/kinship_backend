FactoryBot.define do
  factory :project_school_level do
    school_level { create(:school_level) }
    project { create(:project) }
  end
end
