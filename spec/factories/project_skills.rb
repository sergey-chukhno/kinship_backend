FactoryBot.define do
  factory :project_skill do
    project { create(:project) }
    skill { create(:skill) }
  end
end
