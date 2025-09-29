FactoryBot.define do
  factory :project_member do
    status { 0 }
    admin { false }
    user { create(:user, :confirmed) }
    project { create(:project) }
  end
end
