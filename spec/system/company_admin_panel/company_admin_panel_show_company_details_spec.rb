require "rails_helper"

RSpec.describe "CompanyAdminPanel::ShowCompanyDetails", type: :system do
  let(:company_pending) { create(:company, :pending) }
  let(:company_confirmed) { create(:company, :confirmed) }
  let(:user_teacher) { create(:user, :teacher, :confirmed) }
  let(:user_tutor) { create(:user, :tutor, :confirmed) }
  let(:user_tutor_company_admin) { create(:user, :tutor, :confirmed) }
  let(:user_voluntary) { create(:user, :voluntary, :confirmed) }
  let(:user_voluntary_company_admin) { create(:user, :voluntary, :confirmed) }

  before do
    driven_by(:rack_test)

    create(:user_company, user: user_tutor_company_admin, company: company_pending, role: :admin)
    create(:user_company, user: user_tutor_company_admin, company: company_confirmed, role: :admin)
    create(:user_company, user: user_voluntary_company_admin, company: company_pending, role: :admin)
    create(:user_company, user: user_voluntary_company_admin, company: company_confirmed, role: :admin)
  end

  context "In company admin panel Details tab, users can :" do
    context "if user are teacher" do
      it "should not access this page" do
        sign_in user_teacher

        visit edit_company_admin_panel_company_path(company_pending)
        expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

        visit edit_company_admin_panel_company_path(company_confirmed)
        expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")
      end
    end

    context "if user are tutor" do
      it "should not access this page" do
        sign_in user_tutor

        visit edit_company_admin_panel_company_path(company_pending)
        expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

        visit edit_company_admin_panel_company_path(company_confirmed)
        expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")
      end
    end

    context "if user are tutor and company admin but company pending" do
      it "should not access this page" do
        sign_in user_tutor_company_admin

        visit edit_company_admin_panel_company_path(company_pending)
        expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")
      end
    end

    context "if user are tutor and company admin but company confirmed" do
      it "should see company details" do
        sign_in user_tutor_company_admin

        visit edit_company_admin_panel_company_path(company_confirmed)
        expect(page).to have_content("Informations générales")
        within("#edit_company_#{company_confirmed.id}") do
          find("input", id: "company_name") { |input| expect(input.value).to eq(company_confirmed.name) }
          find("textarea", id: "company_description") { |input| expect(input.value).to eq(company_confirmed.description) }
          find("select", id: "company_company_type_id") { |input| expect(input.value).to eq(company_confirmed.company_type_id.to_s) }
          find("input", id: "company_city") { |input| expect(input.value).to eq(company_confirmed.city) }
          find("input", id: "company_zip_code") { |input| expect(input.value).to eq(company_confirmed.zip_code) }
          find("input", id: "company_referent_phone_number") { |input| expect(input.value).to eq(company_confirmed.referent_phone_number) }
        end
      end
    end

    context "if user are voluntary" do
      it "should not access this page" do
        sign_in user_voluntary

        visit edit_company_admin_panel_company_path(company_pending)
        expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

        visit edit_company_admin_panel_company_path(company_confirmed)
        expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")
      end
    end

    context "if user are voluntary and company admin but company pending" do
      it "should not access this page" do
        sign_in user_voluntary_company_admin

        visit edit_company_admin_panel_company_path(company_pending)
        expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")
      end
    end

    context "if user are voluntary and company admin but company confirmed" do
      it "should see company details" do
        sign_in user_voluntary_company_admin

        visit edit_company_admin_panel_company_path(company_confirmed)
        expect(page).to have_content("Informations générales")
        within("#edit_company_#{company_confirmed.id}") do
          find("input", id: "company_name") { |input| expect(input.value).to eq(company_confirmed.name) }
          find("textarea", id: "company_description") { |input| expect(input.value).to eq(company_confirmed.description) }
          find("select", id: "company_company_type_id") { |input| expect(input.value).to eq(company_confirmed.company_type_id.to_s) }
          find("input", id: "company_city") { |input| expect(input.value).to eq(company_confirmed.city) }
          find("input", id: "company_zip_code") { |input| expect(input.value).to eq(company_confirmed.zip_code) }
          find("input", id: "company_referent_phone_number") { |input| expect(input.value).to eq(company_confirmed.referent_phone_number) }
        end
      end
    end
  end
end
