# require "rails_helper"

# RSpec.describe "CompanyAdminPanel::ManageCompanyMembers", type: :system do
#   let(:company_pending) { create(:company, :pending) }
#   let(:company_confirmed) { create(:company, :confirmed) }
#   let(:user_teacher) { create(:user, :teacher, :confirmed) }
#   let(:user_tutor) { create(:user, :tutor, :confirmed) }
#   let(:user_tutor_company_admin) { create(:user, :tutor, :confirmed) }
#   let(:user_voluntary) { create(:user, :voluntary, :confirmed) }
#   let(:user_voluntary_company_admin) { create(:user, :voluntary, :confirmed) }

#   before do
#     driven_by(:selenium_chrome_headless)

#     create(:user_company, user: user_tutor_company_admin, company: company_pending, admin: true)
#     create(:user_company, user: user_tutor_company_admin, company: company_confirmed, admin: true)
#     create(:user_company, user: user_voluntary_company_admin, company: company_pending, admin: true)
#     create(:user_company, user: user_voluntary_company_admin, company: company_confirmed, admin: true)
#   end

#   context "In company admin panel Members tab, users can :" do
#     context "if user is teacher" do
#       it "should not access this page" do
#         sign_in user_teacher

#         visit company_admin_panel_company_member_path(company_pending, status: :pending)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

#         visit company_admin_panel_company_member_path(company_pending, status: :confirmed)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

#         visit company_admin_panel_company_member_path(company_confirmed, status: :pending)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

#         visit company_admin_panel_company_member_path(company_confirmed, status: :confirmed)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")
#       end
#     end

#     context "if user is tutor" do
#       it "should not access this page" do
#         sign_in user_tutor

#         visit company_admin_panel_company_member_path(company_pending, status: :pending)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

#         visit company_admin_panel_company_member_path(company_pending, status: :confirmed)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

#         visit company_admin_panel_company_member_path(company_confirmed, status: :pending)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

#         visit company_admin_panel_company_member_path(company_confirmed, status: :confirmed)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")
#       end
#     end

#     context "if user is tutor and company admin but company pending" do
#       it "should not access this page" do
#         sign_in user_tutor_company_admin

#         visit company_admin_panel_company_member_path(company_pending, status: :pending)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

#         visit company_admin_panel_company_member_path(company_pending, status: :confirmed)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")
#       end
#     end

#     context "if user is tutor and company admin but company confirmed" do
#       it "should access this page" do
#         sign_in user_tutor_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :pending)
#         expect(page).to have_content("Affichage administrateur")

#         visit company_admin_panel_company_member_path(company_confirmed, status: :confirmed)
#         expect(page).to have_content("Affichage administrateur")
#       end

#       it "should see pending members and not confirmed members" do
#         pending_member = create(:user_company, :pending, user: create(:user, :voluntary, :confirmed), company: company_confirmed)
#         confirmed_member = create(:user_company, :confirmed, user: create(:user, :voluntary, :confirmed), company: company_confirmed)

#         sign_in user_tutor_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :pending)
#         expect(page).to have_content(pending_member.user.full_name)
#         expect(page).not_to have_content(confirmed_member.user.full_name)
#       end

#       it "should see confirmed members and not pending members" do
#         pending_member = create(:user_company, :pending, user: create(:user, :voluntary, :confirmed), company: company_confirmed)
#         confirmed_member = create(:user_company, :confirmed, user: create(:user, :voluntary, :confirmed), company: company_confirmed)

#         sign_in user_tutor_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :confirmed)
#         expect(page).to have_content(confirmed_member.user.full_name)
#         expect(page).not_to have_content(pending_member.user.full_name)
#       end

#       it "should set pending member as admin or default" do
#         pending_member = UserCompany.find_by(user: user_voluntary_company_admin, company: company_confirmed)

#         sign_in user_tutor_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :pending)
#         find("select[id='user_company_admin']").select("Utilisateur rattaché")
#         sleep 0.01

#         expect(pending_member.reload.admin).to eq(false)

#         find("select[id='user_company_admin']").select("Administrateur")
#         sleep 0.01

#         expect(pending_member.reload.admin).to eq(true)
#       end

#       it "should set confirmed member as admin or default" do
#         pending_member = UserCompany.find_by(user: user_voluntary_company_admin, company: company_confirmed)
#         pending_member.update(status: :confirmed)

#         sign_in user_tutor_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :confirmed)
#         find("select[id='user_company_admin']").select("Utilisateur rattaché")
#         sleep 0.01

#         expect(pending_member.reload.admin).to eq(false)

#         find("select[id='user_company_admin']").select("Administrateur")
#         sleep 0.01

#         expect(pending_member.reload.admin).to eq(true)
#       end

#       it "should confirm pending member" do
#         pending_member = UserCompany.find_by(user: user_voluntary_company_admin, company: company_confirmed)

#         sign_in user_tutor_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :pending)
#         find("input[class='btn-toggle']").click
#         sleep 0.01

#         expect(pending_member.reload.status).to eq("confirmed")
#       end

#       it "should unconfirm confirmed member" do
#         confirmed_member = UserCompany.find_by(user: user_voluntary_company_admin, company: company_confirmed)
#         confirmed_member.update(status: :confirmed)

#         sign_in user_tutor_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :confirmed)
#         find("input[class='btn-toggle']").click
#         sleep 0.01

#         expect(confirmed_member.reload.status).to eq("pending")
#       end

#       it "should delete pending member" do
#         sign_in user_tutor_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :pending)
#         find("button.btn-trash").click
#         sleep 0.01

#         expect(UserCompany.find_by(user: user_voluntary_company_admin, company: company_confirmed)).to be_nil
#       end

#       it "should delete confirmed member" do
#         UserCompany.find_by(user: user_voluntary_company_admin, company: company_confirmed).update(status: :confirmed)

#         sign_in user_tutor_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :confirmed)
#         find("button.btn-trash").click
#         sleep 0.01

#         expect(UserCompany.find_by(user: user_voluntary_company_admin, company: company_confirmed)).to be_nil
#       end
#     end

#     context "if user is voluntary" do
#       it "should not access this page" do
#         sign_in user_voluntary

#         visit company_admin_panel_company_member_path(company_pending, status: :pending)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

#         visit company_admin_panel_company_member_path(company_pending, status: :confirmed)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

#         visit company_admin_panel_company_member_path(company_confirmed, status: :pending)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

#         visit company_admin_panel_company_member_path(company_confirmed, status: :confirmed)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")
#       end
#     end

#     context "if user is voluntary and company admin but company pending" do
#       it "should not access this page" do
#         sign_in user_voluntary_company_admin

#         visit company_admin_panel_company_member_path(company_pending, status: :pending)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

#         visit company_admin_panel_company_member_path(company_pending, status: :confirmed)
#         expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")
#       end
#     end

#     context "if user is voluntary and company admin but company confirmed" do
#       it "should access this page" do
#         sign_in user_voluntary_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :pending)
#         expect(page).to have_content("Affichage administrateur")

#         visit company_admin_panel_company_member_path(company_confirmed, status: :confirmed)
#         expect(page).to have_content("Affichage administrateur")
#       end

#       it "should see pending members and not confirmed members" do
#         pending_member = create(:user_company, :pending, user: create(:user, :voluntary, :confirmed), company: company_confirmed)
#         confirmed_member = create(:user_company, :confirmed, user: create(:user, :voluntary, :confirmed), company: company_confirmed)

#         sign_in user_voluntary_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :pending)
#         expect(page).to have_content(pending_member.user.full_name)
#         expect(page).not_to have_content(confirmed_member.user.full_name)
#       end

#       it "should see confirmed members and not pending members" do
#         pending_member = create(:user_company, :pending, user: create(:user, :voluntary, :confirmed), company: company_confirmed)
#         confirmed_member = create(:user_company, :confirmed, user: create(:user, :voluntary, :confirmed), company: company_confirmed)

#         sign_in user_voluntary_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :confirmed)
#         expect(page).to have_content(confirmed_member.user.full_name)
#         expect(page).not_to have_content(pending_member.user.full_name)
#       end

#       it "should set pending member as admin or default" do
#         pending_member = UserCompany.find_by(user: user_tutor_company_admin, company: company_confirmed)

#         sign_in user_voluntary_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :pending)
#         find("select[id='user_company_admin']").select("Utilisateur rattaché")
#         sleep 0.01

#         expect(pending_member.reload.admin).to eq(false)

#         find("select[id='user_company_admin']").select("Administrateur")
#         sleep 0.01

#         expect(pending_member.reload.admin).to eq(true)
#       end

#       it "should set confirmed member as admin or default" do
#         pending_member = UserCompany.find_by(user: user_tutor_company_admin, company: company_confirmed)
#         pending_member.update(status: :confirmed)

#         sign_in user_voluntary_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :confirmed)
#         find("select[id='user_company_admin']").select("Utilisateur rattaché")
#         sleep 0.01

#         expect(pending_member.reload.admin).to eq(false)

#         find("select[id='user_company_admin']").select("Administrateur")
#         sleep 0.01

#         expect(pending_member.reload.admin).to eq(true)
#       end

#       it "should confirm pending member" do
#         pending_member = UserCompany.find_by(user: user_tutor_company_admin, company: company_confirmed)

#         sign_in user_voluntary_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :pending)
#         find("input[class='btn-toggle']").click
#         sleep 0.01

#         expect(pending_member.reload.status).to eq("confirmed")
#       end

#       it "should unconfirm confirmed member" do
#         confirmed_member = UserCompany.find_by(user: user_tutor_company_admin, company: company_confirmed)
#         confirmed_member.update(status: :confirmed)

#         sign_in user_voluntary_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :confirmed)
#         find("input[class='btn-toggle']").click
#         sleep 0.01

#         expect(confirmed_member.reload.status).to eq("pending")
#       end

#       it "should delete pending member" do
#         sign_in user_voluntary_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :pending)
#         find("button.btn-trash").click
#         sleep 0.01

#         expect(UserCompany.find_by(user: user_tutor_company_admin, company: company_confirmed)).to be_nil
#       end

#       it "should delete confirmed member" do
#         UserCompany.find_by(user: user_tutor_company_admin, company: company_confirmed).update(status: :confirmed)

#         sign_in user_voluntary_company_admin

#         visit company_admin_panel_company_member_path(company_confirmed, status: :confirmed)
#         find("button.btn-trash").click
#         sleep 0.01

#         expect(UserCompany.find_by(user: user_tutor_company_admin, company: company_confirmed)).to be_nil
#       end
#     end
#   end
# end
