require "rails_helper"

# describe "Children creation process", type: :feature, javascript: true do
#   let(:user) { create(:user, :tutor) }
#   let(:school) { create(:school, name: "Lycée du test", zip_code: "44000", city: "Nantes", school_type: "primaire") }
#   let(:school_level) { create(:school_level, name: "Paquerette", level: "cm1", school: school) }

#   before do
#     create(:user_school, user: user, school: school)
#     create(:user_school_level, user: user, school_level: school_level)
#     create(:skill, name: "Chanter", official: true)
#     sign_in user
#   end

#   context "When user is a parent and start creating children" do
#     it "can create a children" do
#       visit new_registration_stepper_pupil_path
#       within("#new_user") do
#         fill_in "Prénom", with: "Bob"
#         fill_in "Nom", with: "Morane"
#         fill_in "Date de naissance", with: "08/08/2020"
#         find('input[name="accept_privacy_policy[user_choice]"][value="Oui"]').click
#         click_on "Continuer"
#       end
#       expect(User.last).to have_attributes(first_name: "Bob", last_name: "Morane", birthday: Date.parse("08/08/2020"), parent_id: user.id, role: "student")

#       find("#toggle_skills_user_choice_oui").click
#       within("#edit_user_#{User.last.id}") do
#         find("#user_skill_ids_#{Skill.last.id}").click
#         fill_in "Ajouter des précisions générales", with: "Je suis un super chanteur"
#         click_on "Enregistrer les compétences"
#       end
#       expect(User.last.skills).to eq [Skill.last]
#       expect(User.last.skill_additional_information).to eq "Je suis un super chanteur"
#       expect(page).to have_content("Bob Morane - Informations générales")
#     end
#   end
# end
