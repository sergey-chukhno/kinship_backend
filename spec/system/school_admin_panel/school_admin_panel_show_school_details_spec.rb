require "rails_helper"

RSpec.describe "SchoolAdminPanel::ShowSchoolDetails", type: :system do
  before do
    driven_by(:rack_test)
  end

  context "In school admin panel, school admin users can" do
    let(:school) { create(:school, referent_phone_number: "020202020202") }
    let(:user) { create(:user) }

    it "see school details if user are school admin" do
      user_school = user.user_schools.create(school: school)
      Availability.create(user: user)
      user.confirm
      sign_in user

      visit edit_school_admin_panel_school_path(school)
      expect(page).to have_content("Vous n'êtes pas autorisé.e à effectuer cette action.")

      user_school.update(admin: true)
      visit edit_school_admin_panel_school_path(school)
      expect(page).to have_content(I18n.t(:title, scope: [:layouts, :school_admin_panel, :school]))
      within("#edit_school_#{school.id}") do
        find("input", id: "school_name") { |input| expect(input.value).to eq(school.name) }
        find("input", id: "school_zip_code") { |input| expect(input.value).to eq(school.zip_code) }
        find("input", id: "school_city") { |input| expect(input.value).to eq(school.city) }
        find("select", id: "school_school_type") { |input| expect(input.value).to eq(school.school_type) }
        find("input", id: "school_referent_phone_number") { |input| expect(input.value).to eq(school.referent_phone_number) }
      end
    end
  end
end
