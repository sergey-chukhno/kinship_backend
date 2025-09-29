FactoryBot.define do
  factory :team do
    title { "Equipe de TV" }
    description { "Pour pouvoir tourner en toute sérénité" }
    project { create(:project) }
  end
end
