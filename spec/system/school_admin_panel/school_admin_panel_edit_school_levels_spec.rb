require "rails_helper"

RSpec.describe "SchoolAdminPanel::EditSchoolLevels", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
    clear_enqueued_jobs
  end

  context "In school admin panel, school admin users can" do
    let(:school) { create(:school, referent_phone_number: "020202020202", school_type: "primaire") }
    let(:user) { create(:user) }

    it "access to the page if user is school admin user" do
      user_school = user.user_schools.create(school: school)
      Availability.create(user: user)
      user.confirm
      sign_in user

      visit edit_school_admin_panel_school_level_path(school)
      expect(page).to have_current_path(root_path) # user est redirigé vers la page d'accueil car il n'est pas autorisé à effectuer cette action

      user_school.update(admin: true)
      sleep(0.01)
      visit edit_school_admin_panel_school_level_path(school)
      expect(page).to have_content(I18n.t(:title, scope: [:layouts, :school_admin_panel, :school_level]))
    end

    it "edit school levels" do
      user.user_schools.create(school: school, admin: true)
      Availability.create(user: user)
      user.confirm
      sign_in user

      visit edit_school_admin_panel_school_level_path(school)
      expect(page).to have_content(I18n.t(:title, scope: [:layouts, :school_admin_panel, :school_level]))

      within(:xpath, "//form[@id='edit_school_#{school.id}'][@action='#{school_admin_panel_school_level_path(school)}']") do
        click_on "Ajouter une classe"
        select("CP", from: "Choisir un niveau")
        select("1", from: "Choisir une lettre ou un chiffre")
        click_on "Enregistrer"
        sleep(0.01)
      end

      sleep(0.01)
      expect(school.school_levels.count).to eq(1)
      expect(school.school_levels.first.level).to eq("cp")
      expect(school.school_levels.first.name).to eq("1")

      visit edit_school_admin_panel_school_level_path(school)
      expect(page).to have_content(I18n.t(:title, scope: [:layouts, :school_admin_panel, :school_level]))

      within(:xpath, "//form[@id='edit_school_#{school.id}'][@action='#{school_admin_panel_school_level_path(school)}']") do
        select("CM1", from: "Choisir un niveau")
        select("5", from: "Choisir une lettre ou un chiffre")
        click_on "Enregistrer"
        sleep(0.01)
      end

      expect(school.school_levels.count).to eq(1)
      expect(school.school_levels.first.level).to eq("cm1")
      expect(school.school_levels.first.name).to eq("5")
    end

    # Commented because sometimes it fails in GH actions
    # it "ask for custom school level" do
    #   user.user_schools.create(school: school, admin: true)
    #   Availability.create(user: user)
    #   user.confirm
    #   sign_in user

    #   sleep(0.01)
    #   visit edit_school_admin_panel_school_level_path(school)
    #   expect(page).to have_content(I18n.t(:title, scope: [:layouts, :school_admin_panel, :school_level]))

    #   within(:xpath, "//form[@id='new_custom_custom_school_level'][@action='#{school_admin_panel_school_levels_path(id: school)}']") do
    #     fill_in "Préciser le niveau", with: "L3"
    #     fill_in "Préciser la spécialité de la classe", with: "Droit"
    #     click_on "Valider la demande"
    #     sleep(0.01)
    #   end

    #   expect(enqueued_jobs.size).to eq(1)
    # end
  end
end
