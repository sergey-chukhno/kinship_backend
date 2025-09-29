# require "rails_helper"

# RSpec.describe "SchoolAdminPanel::ManageMembers", type: :system do
#   before do
#     driven_by(:selenium_chrome_headless)
#   end

#   context "In school admin panel, school admin users" do
#     let(:school) { create(:school, referent_phone_number: "020202020202", school_type: "primaire") }
#     let(:user) { create(:user) }
#     let(:teacher) { create(:user, :teacher, email: "example@ac-nantes.fr") }
#     let(:tutor) { create(:user, :tutor) }
#     before do
#       tutor.confirm
#       teacher.confirm
#       create(:user_school, school: school, user: tutor)
#       create(:user_school, school: school, user: teacher)
#     end

#     it "can access to the page if user is school admin user" do
#       user_school = user.user_schools.create(school: school)
#       Availability.create(user: user)
#       user.confirm
#       sign_in user

#       visit school_admin_panel_school_member_path(school)
#       expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

#       user_school.update(admin: true)
#       visit school_admin_panel_school_member_path(school)
#       expect(page).to have_content("Affichage administrateur")
#     end

#     it "can see pending members" do
#       user.user_schools.create(school: school, admin: true)
#       Availability.create(user: user)
#       user.confirm
#       sign_in user

#       visit school_admin_panel_school_member_path(school, status: :pending)
#       expect(page).to have_content("Affichage administrateur")

#       expect(page).to have_content(teacher.full_name)
#       expect(page).not_to have_content(tutor.full_name)
#     end

#     it "can see confirmed members" do
#       user.user_schools.create(school: school, admin: true)
#       Availability.create(user: user)
#       user.confirm
#       sign_in user

#       visit school_admin_panel_school_member_path(school, status: :confirmed)
#       expect(page).to have_content("Affichage administrateur")

#       expect(page).to have_content(tutor.full_name)
#       expect(page).not_to have_content(teacher.full_name)
#     end

#     it "can confirm pending members" do
#       user.user_schools.create(school: school, admin: true)
#       Availability.create(user: user)
#       user.confirm
#       sign_in user

#       visit school_admin_panel_school_member_path(school, status: :pending)
#       expect(page).to have_content("Affichage administrateur")

#       find("input[class='btn-toggle']").click
#       sleep(0.01)
#       expect(teacher.user_schools.find_by(school: school).status).to eq("confirmed")

#       visit school_admin_panel_school_member_path(school, status: :confirmed)
#       expect(page).to have_content(teacher.full_name)
#     end

#     it "can unconfirm confirmed members" do
#       user.user_schools.create(school: school, admin: true)
#       Availability.create(user: user)
#       user.confirm
#       sign_in user

#       visit school_admin_panel_school_member_path(school, status: :confirmed)
#       expect(page).to have_content("Affichage administrateur")

#       find("input[class='btn-toggle']").click
#       sleep(0.01)
#       expect(tutor.user_schools.find_by(school: school).status).to eq("pending")

#       visit school_admin_panel_school_member_path(school, status: :pending)
#       expect(page).to have_content(tutor.full_name)
#     end

#     it "can set pending members admin" do
#       user.user_schools.create(school: school, admin: true)
#       Availability.create(user: user)
#       user.confirm
#       sign_in user

#       visit school_admin_panel_school_member_path(school, status: :pending)
#       expect(page).to have_content("Affichage administrateur")

#       find("select[id='user_school_admin']").select("Administrateur")
#       sleep(0.01)
#       expect(teacher.user_schools.find_by(school: school).admin).to eq(true)

#       find("select[id='user_school_admin']").select("Utilisateur rattaché")
#       sleep(0.01)
#       expect(teacher.user_schools.find_by(school: school).admin).to eq(false)
#     end

#     it "can set confirmed members admin" do
#       user.user_schools.create(school: school, admin: true)
#       Availability.create(user: user)
#       user.confirm
#       sign_in user

#       visit school_admin_panel_school_member_path(school, status: :confirmed)
#       expect(page).to have_content("Affichage administrateur")

#       find("select[id='user_school_admin']").select("Administrateur")
#       sleep(0.01)
#       expect(tutor.user_schools.find_by(school: school).admin).to eq(true)

#       find("select[id='user_school_admin']").select("Utilisateur rattaché")
#       sleep(0.01)
#       expect(tutor.user_schools.find_by(school: school).admin).to eq(false)
#     end

#     it "can change school level of members" do
#       user.user_schools.create(school: school, admin: true)
#       Availability.create(user: user)
#       user.confirm
#       school_level_1 = create(:school_level, name: "1", level: "cp", school: school)
#       school_level_2 = create(:school_level, name: "2", level: "ce1", school: school)
#       school_level_3 = create(:school_level, name: "3", level: "ce2", school: school)
#       sign_in user

#       visit school_admin_panel_school_member_path(school, status: :pending)
#       expect(page).to have_content("Affichage administrateur")

#       within("#school_level_#{teacher.id}") do
#         find("#user_school_level_ids-ts-control").click
#         find("#user_school_level_ids-opt-1").click
#         find("#user_school_level_ids-opt-2").click
#       end
#       find(".admin-panel-member__card").click
#       sleep(0.01)
#       teacher.reload
#       expect(teacher.school_levels).to eq([school_level_1, school_level_2])
#       expect(teacher.school_levels).not_to eq([school_level_3])

#       within("#school_level_#{teacher.id}") do
#         find("#user_school_level_ids-ts-control").click
#         find("#user_school_level_ids-opt-1").click
#         find("#user_school_level_ids-opt-2").click
#         find("#user_school_level_ids-opt-3").click
#       end
#       find(".admin-panel-member__card").click
#       sleep(0.01)
#       teacher.reload
#       expect(teacher.school_levels).to eq([school_level_3])
#       expect(teacher.school_levels).not_to eq([school_level_1, school_level_2])
#     end

#     it "can delete confirmed members" do
#       user.user_schools.create(school: school, admin: true)
#       Availability.create(user: user)
#       user.confirm
#       sign_in user

#       visit school_admin_panel_school_member_path(school, status: :confirmed)
#       expect(page).to have_content("Affichage administrateur")

#       find("button.btn-trash").click
#       sleep(0.01)
#       expect(tutor.user_schools.find_by(school: school)).to eq(nil)
#     end

#     it "can delete pending members" do
#       user.user_schools.create(school: school, admin: true)
#       Availability.create(user: user)
#       user.confirm
#       sign_in user

#       visit school_admin_panel_school_member_path(school, status: :pending)
#       expect(page).to have_content("Affichage administrateur")

#       find("button.btn-trash").click
#       sleep(0.01)
#       expect(teacher.user_schools.find_by(school: school)).to eq(nil)
#     end
#   end
# end
