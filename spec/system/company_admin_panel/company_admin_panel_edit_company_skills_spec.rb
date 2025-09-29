require "rails_helper"

RSpec.describe "CompanyAdminPanel::EditCompanySkills", type: :system do
  let(:company_pending) { create(:company, :pending) }
  let(:company_confirmed) { create(:company, :confirmed) }
  let(:user_teacher) { create(:user, :teacher, :confirmed) }
  let(:user_tutor) { create(:user, :tutor, :confirmed) }
  let(:user_tutor_company_admin) { create(:user, :tutor, :confirmed) }
  let(:user_voluntary) { create(:user, :voluntary, :confirmed) }
  let(:user_voluntary_company_admin) { create(:user, :voluntary, :confirmed) }

  before do
    driven_by(:selenium_chrome_headless)

    create(:user_company, user: user_tutor_company_admin, company: company_pending, admin: true)
    create(:user_company, user: user_tutor_company_admin, company: company_confirmed, admin: true)
    create(:user_company, user: user_voluntary_company_admin, company: company_pending, admin: true)
    create(:user_company, user: user_voluntary_company_admin, company: company_confirmed, admin: true)
  end

  context "In company admin panel Skills tab, users can :" do
    context "if user is teacher" do
      it "should not access this page" do
        sign_in user_teacher

        visit edit_company_admin_panel_company_skill_path(company_pending)
        expect(page).to have_current_path(root_path) # user est redirigé vers la page d'accueil car il n'est pas autorisé à effectuer cette action

        visit edit_company_admin_panel_company_skill_path(company_confirmed)
        expect(page).to have_current_path(root_path) # user est redirigé vers la page d'accueil car il n'est pas autorisé à effectuer cette action
      end
    end

    context "if user is tutor" do
      it "should not access this page" do
        sign_in user_tutor

        visit edit_company_admin_panel_company_skill_path(company_pending)
        expect(page).to have_current_path(root_path) # user est redirigé vers la page d'accueil car il n'est pas autorisé à effectuer cette action

        visit edit_company_admin_panel_company_skill_path(company_confirmed)
        expect(page).to have_current_path(root_path) # user est redirigé vers la page d'accueil car il n'est pas autorisé à effectuer cette action
      end
    end

    context "if user is tutor and company admin but company pending" do
      it "should not access this page" do
        sign_in user_tutor_company_admin

        visit edit_company_admin_panel_company_skill_path(company_pending)
        expect(page).to have_current_path(root_path) # user est redirigé vers la page d'accueil car il n'est pas autorisé à effectuer cette action
      end
    end

    context "if user is tutor and company admin but company confirmed" do
      let(:skills) { Skill.all.sample(5) }
      let(:sub_skills) { skills.map { |skill| skill.sub_skills.sample(2) }.flatten }

      before do
        10.times do
          create(:sub_skill, skill: create(:skill, :official))
        end
      end

      it "should edit company skills" do
        sign_in user_tutor_company_admin

        visit edit_company_admin_panel_company_skill_path(company_confirmed)
        sleep(0.01)
        expect(page).to have_content("Compétence(s) de l'organisation")

        sleep(0.01)
        within("#edit_company_#{company_confirmed.id}") do
          skills.each do |skill|
            find("label[for=company_skill_ids_#{skill.id}]").click
          end
          sub_skills.each do |sub_skill|
            find("label[for=company_sub_skill_ids_#{sub_skill.id}]").click
          end
          click_on "Enregistrer"
        end
        sleep(0.01)
        expect(company_confirmed.skills).to match_array skills
        expect(company_confirmed.sub_skills).to match_array sub_skills
      end
    end

    context "if user is voluntary" do
      it "should not access this page" do
        sign_in user_voluntary

        visit edit_company_admin_panel_company_skill_path(company_pending)
        expect(page).to have_current_path(root_path) # user est redirigé vers la page d'accueil car il n'est pas autorisé à effectuer cette action

        visit edit_company_admin_panel_company_skill_path(company_confirmed)
        expect(page).to have_current_path(root_path) # user est redirigé vers la page d'accueil car il n'est pas autorisé à effectuer cette action
      end
    end

    context "if user is voluntary and company admin but company pending" do
      it "should not access this page" do
        sign_in user_voluntary_company_admin

        visit edit_company_admin_panel_company_skill_path(company_pending)
        expect(page).to have_current_path(root_path) # user est redirigé vers la page d'accueil car il n'est pas autorisé à effectuer cette action
      end
    end

    context "if user is voluntary and company admin but company confirmed" do
      let(:skills) { Skill.all.sample(5) }
      let(:sub_skills) { skills.map { |skill| skill.sub_skills.sample(2) }.flatten }

      before do
        10.times do
          create(:sub_skill, skill: create(:skill, :official))
        end
      end
      # user_voluntary_company_admin.update(company: company_confirmed)

      it "should edit company skills" do
        sign_in user_voluntary_company_admin

        visit edit_company_admin_panel_company_skill_path(company_confirmed)
        expect(page).to have_content("Compétence(s) de l'organisation")

        within("#edit_company_#{company_confirmed.id}") do
          skills.each do |skill|
            find("label[for=company_skill_ids_#{skill.id}]").click
          end
          sub_skills.each do |sub_skill|
            find("label[for=company_sub_skill_ids_#{sub_skill.id}]").click
          end
          click_on "Enregistrer"
        end
        sleep(0.01)

        expect(company_confirmed.skills).to match_array skills
        expect(company_confirmed.sub_skills).to match_array sub_skills
      end
    end
  end
end
