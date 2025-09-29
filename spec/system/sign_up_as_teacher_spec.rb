require "rails_helper"

RSpec.describe "Sign up as teacher process", type: :system do
  before do
    driven_by(:rack_test)
  end

  pending "test sign up "
end

# Capybara.default_max_wait_time = 5

# describe "Sign up as teacher process", type: :feature, javascript: true do
#   let(:frozen_time) { Time.zone.parse "2020-05-15 14:00:00" }
#   let(:teacher) { create(:user, :teacher, first_name: "Tony", last_name: "Parker", birthday: "08/08/1989", email: "tony@ac-nice.fr") }
#   let(:skill) { create(:skill, name: "Ruby", official: true) }
#   let(:skill_2) { create(:skill, name: "Javascript", official: true) }

#   before do
#     allow(Time).to receive(:now).and_return frozen_time
#   end

#   def fullfill_first_step_form_and_continue
#     within("#new_registration_stepper_user_role") do
#       choose("Professeur")
#       click_on "Continuer"
#     end
#   end

#   def fullfill_second_step_form_and_continue
#     within("#new_registration_stepper_user_profile") do
#       fill_in "registration_stepper_user_profile_zip_code", with: "49000"
#       select "Ecole du test, Angers (49000)", from: "user[schools_attributes][0][school_id]"
#       fill_in "Adresse email académique", with: "tony@ac-nice.fr"
#       label_no_for_contact_email = find('label.radio-button-check[for="have_contact_email_user_choice_non"]')
#       label_no_for_contact_email.click

#       fill_in "Adresse email de correspondance", with: "tony@parker.com"
#       fill_in "Nom", with: "Parker"
#       fill_in "Prénom", with: "Tony"
#       find("#registration_stepper_user_profile_accept_privacy_policy").click
#       # check "J'accepte de recevoir des informations de la part de Kinship"
#       click_on "Continuer"
#     end
#   end

#   context "When user come from LP and click on 'Inscription en tant que corps enseignant'" do
#     it "can choose a role" do
#       visit new_registration_stepper_first_step_path(role: "teacher")

#       expect(page).to have_content "Inscription Enseignant"
#       fullfill_first_step_form_and_continue

#       expect(page).to have_content "Inscription enseignant"
#       expect(page).to have_content "Détails"
#       expect(page).to_not have_content "Disponibilités"
#       expect(page).to have_content "Mot de passe"
#       expect(page).to have_content "Compétences"
#       expect(page).to have_content "Code postal de l'établissement"

#       # TODO : uncomment when we know how to test session
#       # expect(session[:user_role]).to eq "teacher"
#     end

#     it "can choose a role, create a password and creates its user" do
#       school_angers = create(:school, name: "Ecole du test", zip_code: "49000", city: "Angers", school_type: "primaire")
#       create(:school_level, name: "Paquerette", level: "cm1", school: school_angers)

#       visit new_registration_stepper_first_step_path(role: "teacher")

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

#       expect(page).to have_content "Je souhaite partager mes compétences avec la communauté éducative de mon établissement"
#       expect(User.last).to have_attributes(
#         first_name: "Tony",
#         last_name: "Parker",
#         email: "tony@ac-nice.fr",
#         contact_email: "tony@parker.com",
#         role: "teacher",
#         role_additional_information: "professeur"
#       )
#     end

#     context "When teacher user is created, after the second step" do
#       before do
#         sign_in teacher
#         skill
#         skill_2
#       end

#       it "can choose competences and save it" do
#         visit edit_registration_stepper_fifth_step_path(teacher)

#         expect(page).to have_content "Je souhaite partager mes compétences avec la communauté éducative de mon établissement"

#         find("label", text: "Oui").click

#         expect(page).to have_content "Ruby"
#         expect(page).to have_content "Javascript"

#         within("#edit_user_#{teacher.id}") do
#           check "Ruby"
#           fill_in "Ajouter une compétence ou apporter une précision sur une compétence sélectionnée", with: "I do Python"

#           click_on "Continuer"
#         end

#         expect(page).to have_content "Votre compte n'est pas encore confirmé"
#         teacher.reload
#         expect(teacher).to have_attributes(
#           first_name: "Tony",
#           last_name: "Parker",
#           skill_additional_information: "I do Python"
#         )
#         expect(teacher.skills).to include(skill)
#       end
#     end
#   end
# end
