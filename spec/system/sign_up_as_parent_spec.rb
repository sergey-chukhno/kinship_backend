require "rails_helper"

RSpec.describe "Sign up as parent process", type: :system do
  before do
    driven_by(:rack_test)
  end

  pending "test sign up "
end

# Capybara.default_max_wait_time = 5

# describe "Sign up as teacher process", type: :feature, javascript: true do
#   let(:frozen_time) { Time.zone.parse "2020-05-15 14:00:00" }
#   let(:tutor) { create(:user, :tutor, first_name: "Bob", last_name: "Morane", birthday: "08/08/1989", email: "bob@morane.com") }
#   # let(:availability) { create(:availability, user: tutor) }
#   let(:skill) { create(:skill, name: "Chanter", official: true) }
#   let(:skill_2) { create(:skill, name: "Zouk", official: true) }

#   before do
#     allow(Time).to receive(:now).and_return frozen_time
#   end

#   def fullfill_first_step_form_and_continue
#     within("#new_registration_stepper_user_role") do
#       choose("Grand-parent")
#       click_on "Continuer"
#     end
#   end

#   def fullfill_second_step_form_and_continue
#     within("#new_registration_stepper_user_profile") do
#       fill_in "registration_stepper_user_profile_zip_code", with: "49000"
#       select "Lycée du test, Nantes (44000)", from: "user[schools_attributes][0][school_id]"
#       fill_in "Adresse email", with: "bob@moranee.com"
#       fill_in "Nom", with: "Morane"
#       fill_in "Prénom", with: "Bob"
#       find("#registration_stepper_user_profile_accept_privacy_policy").click
#       # check "J'accepte de recevoir des informations de la part de Kinship"
#       click_on "Continuer"
#     end
#   end

#   context "When user come from LP and click on 'Inscription en tant que parent'" do
#     it "can choose a role" do
#       visit new_registration_stepper_first_step_path(role: "tutor")

#       expect(page).to have_content "Inscription Parent"
#       fullfill_first_step_form_and_continue

#       expect(page).to have_content "Inscription parent"
#       expect(page).to have_content "Détails"
#       expect(page).to have_content "Mot de passe"
#       expect(page).to have_content "Disponibilités"
#       expect(page).to have_content "Compétences"
#       expect(page).to have_content "Code postal de l'établissement"

#       # TODO : uncomment when we know how to test session
#       # expect(session[:user_role]).to eq "tutor"
#     end

#     it "can choose a role, create a password and creates its user" do
#       create(:school, name: "Ecole du test", zip_code: "49000", city: "Angers")
#       school_nantes = create(:school, name: "Lycée du test", zip_code: "44000", city: "Nantes", school_type: "primaire")
#       create(:school_level, name: "Paquerette", level: "cm1", school: school_nantes)

#       visit new_registration_stepper_first_step_path(role: "tutor")

#       fullfill_first_step_form_and_continue
#       fullfill_second_step_form_and_continue
#       expect(page).to have_content "Les mots de passe doivent correspondre"
#       expect(page).to have_content "mot de passe"

#       expect do
#         within("#new_registration_stepper_user_password") do
#           fill_in "registration_stepper_user_password_password", with: "Password@"
#           fill_in "registration_stepper_user_password_password_confirmation", with: "Password@"
#           click_on "Continuer"
#         end
#       end.to change { User.count }.by(1)

#       expect(page).to have_content "Je suis disponible pour accompagner une sortie scolaire"
#       expect(User.last).to have_attributes(
#         first_name: "Bob",
#         last_name: "Morane",
#         email: "bob@moranee.com",
#         role: "tutor",
#         role_additional_information: "grand-parent"
#       )
#     end

#     context "When tutor user is created, after the second step" do
#       before do
#         sign_in tutor
#         skill
#         skill_2
#       end

#       it "can choose skills & availabities & availabilities and save it" do
#         visit new_registration_stepper_fourth_step_path(tutor)

#         expect(page).to have_content "Je suis disponible pour accompagner une sortie scolaire"
#         find("label", text: "Oui").click
#         expect(page).to have_content "Quand êtes-vous disponible ?"

#         within("#new_availability") do
#           check "Lundi"
#           check "Mardi"
#           check "Mercredi"
#           click_on "Continuer"
#         end

#         expect(page).to have_content "Je souhaite partager mes compétences à l'ensemble de l'établissement"
#         expect(page).to have_content "Chanter"
#         expect(page).to have_content "Zouk"

#         within("#edit_user_#{tutor.id}") do
#           check "Chanter"
#           fill_in "Ajouter une compétence ou apporter une précision sur une compétence sélectionnée", with: "I do sing time to time"

#           click_on "Continuer"
#         end

#         expect(page).to have_content "Votre compte n'est pas encore confirmé"
#         tutor.reload
#         expect(tutor).to have_attributes(
#           first_name: "Bob",
#           last_name: "Morane",
#           email: "bob@morane.com",
#           skill_additional_information: "I do sing time to time"
#         )
#         expect(tutor.skills).to include(skill)
#         expect(tutor.availability).to have_attributes(
#           monday: true,
#           tuesday: true,
#           wednesday: true,
#           thursday: false,
#           friday: false,
#           other: false
#         )
#       end
#     end
#   end
# end
