require "rails_helper"

RSpec.describe "CompanyAdminPanel::CompanySkills", type: :request do
  let(:company_confirmed) { create(:company, :confirmed) }
  let(:company_pending) { create(:company, :pending) }

  let(:teacher) { create(:user, :teacher) }
  let(:tutor) { create(:user, :tutor) }
  let(:voluntary) { create(:user, :voluntary) }

  let(:tutor_admin) { create(:user, :tutor) }
  let(:voluntary_admin) { create(:user, :voluntary) }

  before do
    teacher.confirm
    tutor.confirm
    voluntary.confirm

    tutor_admin.confirm
    voluntary_admin.confirm

    create(:user_company, :admin, user: tutor_admin, company: company_confirmed)
    create(:user_company, :admin, user: voluntary_admin, company: company_confirmed)

    create(:user_company, :admin, user: tutor_admin, company: company_pending)
    create(:user_company, :admin, user: voluntary_admin, company: company_pending)
  end

  describe "GET /edit" do
    context "when user is not logged in" do
      it "redirects to login page" do
        get edit_company_admin_panel_company_skill_path(company_confirmed)
        expect(response).to redirect_to(new_user_session_path)

        get edit_company_admin_panel_company_skill_path(company_pending)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is logged in but not company admin" do
      it "returns http error for teacher" do
        sign_in teacher

        get edit_company_admin_panel_company_skill_path(company_confirmed)
        expect(response).to have_http_status(:found)

        get edit_company_admin_panel_company_skill_path(company_pending)
        expect(response).to have_http_status(:found)
      end

      it "returns http error for tutor" do
        sign_in tutor

        get edit_company_admin_panel_company_skill_path(company_confirmed)
        expect(response).to have_http_status(:found)

        get edit_company_admin_panel_company_skill_path(company_pending)
        expect(response).to have_http_status(:found)
      end

      it "returns http error for voluntary" do
        sign_in voluntary

        get edit_company_admin_panel_company_skill_path(company_confirmed)
        expect(response).to have_http_status(:found)

        get edit_company_admin_panel_company_skill_path(company_pending)
        expect(response).to have_http_status(:found)
      end
    end

    context "when user is logged in and company admin but the company isn't confirmed" do
      it "returns http error for tutor" do
        sign_in tutor_admin

        get edit_company_admin_panel_company_skill_path(company_pending)
        expect(response).to have_http_status(:found)
      end

      it "returns http error for voluntary" do
        sign_in voluntary_admin

        get edit_company_admin_panel_company_skill_path(company_pending)
        expect(response).to have_http_status(:found)
      end
    end

    context "when user is logged in and company admin and the company is confirmed" do
      it "returns http success for tutor" do
        sign_in tutor_admin

        get edit_company_admin_panel_company_skill_path(company_confirmed)
        expect(response).to have_http_status(:success)
      end

      it "returns http success for voluntary" do
        sign_in voluntary_admin

        get edit_company_admin_panel_company_skill_path(company_confirmed)
        expect(response).to have_http_status(:success)
      end
    end
  end
end
