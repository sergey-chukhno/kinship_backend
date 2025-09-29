FactoryBot.define do
  factory :project_tag do
    tag { create(:tag) }
    project { create(:project) }
  end
end
