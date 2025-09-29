# require "rails_helper"

# RSpec.describe "Account::EditNetworks", type: :system do
#   let(:job) { Faker::Job.title }
#   let(:take_trainee) { ["Oui", "Non"].sample }
#   let(:take_trainee_value) { take_trainee == "Oui" }
#   let(:propose_workshop) { ["Oui", "Non"].sample }
#   let(:propose_workshop_value) { propose_workshop == "Oui" }

#   before do
#     driven_by(:rack_test)
#   end

#   context "only Tutors and Voluntarys can edit her networks" do
#     it "Tutor can edit her networks" do
#       tutor = create(:user, :tutor)
#       Availability.create(user: tutor)
#       tutor.confirm
#       sign_in tutor

#       visit edit_account_network_path(tutor)
#       expect(page).to have_content "Mes informations de réseau"

#       within("#edit_user_#{tutor.id}") do
#         fill_in "user[job]", with: job
#         select take_trainee, from: "user[take_trainee]"
#         select propose_workshop, from: "user[propose_workshop]"
#         click_on "Enregistrer"
#       end

#       tutor.reload
#       expect(tutor).to have_attributes(job: job, take_trainee: take_trainee_value, propose_workshop: propose_workshop_value)
#     end

#     it "Voluntary can edit her networks" do
#       voluntary = create(:user, :voluntary)
#       Availability.create(user: voluntary)
#       voluntary.confirm
#       sign_in voluntary

#       visit edit_account_network_path(voluntary)
#       expect(page).to have_content "Mes informations de réseau"

#       within("#edit_user_#{voluntary.id}") do
#         fill_in "user[job]", with: job
#         select take_trainee, from: "user[take_trainee]"
#         select propose_workshop, from: "user[propose_workshop]"
#         click_on "Enregistrer"
#       end

#       voluntary.reload
#       expect(voluntary).to have_attributes(job: job, take_trainee: take_trainee_value, propose_workshop: propose_workshop_value)
#     end

#     it "Teacher can't edit her networks" do
#       teacher = create(:user, :teacher, email: "example@ac-nantes.fr")
#       Availability.create(user: teacher)
#       teacher.confirm
#       sign_in teacher

#       visit edit_account_network_path(teacher)
#       expect(page).to have_content "Vous n'êtes pas autorisé.e à effectuer cette action."
#     end

#     pending "add company test"
#   end
# end
