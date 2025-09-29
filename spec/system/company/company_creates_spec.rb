require "rails_helper"

RSpec.describe "Company::Creates", type: :system do
  let(:company_type) { CompanyType.all.sample }
  let(:zip_code) { Faker::Address.zip_code }
  let(:city) { Faker::Address.city }
  let(:name) { Faker::Company.name }
  let(:phone_number) { Faker::PhoneNumber.phone_number }
  let(:description) { Faker::Lorem.paragraph }
  let(:skills) { Skill.all.sample(5) }
  let(:sub_skills) { skills.map { |skill| skill.sub_skills.sample(2) }.flatten }
  let(:website) { Faker::Internet.url }
  let(:job) { Faker::Job.title }
  let(:take_trainee) { [true, false].sample }
  let(:propose_workshop) { [true, false].sample }
  let(:propose_summer_job) { [true, false].sample }

  before do
    driven_by(:selenium_chrome_headless)

    10.times do
      create(:company_type)
      create(:sub_skill, skill: create(:skill, :official))
    end
  end

  context "only Tutors and Voluntarys can create a company" do
    it "Tutor can create a company" do
      tutor = create(:user, :tutor)
      tutor.confirm
      sign_in tutor

      visit new_company_path
      expect(page).to have_content I18n.t("views.company.new.title")

      within("#new_company") do
        select company_type.name, from: "company_company_type_id"
        fill_in "company_zip_code", with: zip_code
        fill_in "company_city", with: city
        fill_in "company_name", with: name
        fill_in "company_referent_phone_number", with: phone_number
        fill_in "company_description", with: description
        fill_in "company_website", with: website
        click_on "Continuer"
        sleep 0.1
        skills.each do |skill|
          find("label[for=company_skill_ids_#{skill.id}]").click
        end
        sub_skills.each do |sub_skill|
          find("label[for=company_sub_skill_ids_#{sub_skill.id}]").click
        end
        click_on "Continuer"
        sleep 0.1
        fill_in "company_job", with: job
        select take_trainee ? "Oui" : "Non", from: "company_take_trainee"
        select propose_workshop ? "Oui" : "Non", from: "company_propose_workshop"
        select propose_summer_job ? "Oui" : "Non", from: "company_propose_summer_job"
        click_on "Enregistrer"
      end
      sleep 0.1

      expect(Company.last).to have_attributes(
        company_type_id: company_type.id,
        zip_code: zip_code,
        city: city,
        name: name,
        referent_phone_number: phone_number,
        description: description,
        website: website,
        job: job,
        take_trainee: take_trainee,
        propose_workshop: propose_workshop,
        propose_summer_job: propose_summer_job
      )
      expect(Company.last.skills).to match_array skills
      expect(Company.last.sub_skills).to match_array sub_skills
      expect(UserCompany.last).to have_attributes(user_id: tutor.id, company_id: Company.last.id, admin: true, owner: true)
    end

    it "Voluntary can create a company" do
      voluntary = create(:user, :voluntary)
      voluntary.confirm
      sign_in voluntary

      visit new_company_path
      expect(page).to have_content I18n.t("views.company.new.title")

      within("#new_company") do
        select company_type.name, from: "company_company_type_id"
        fill_in "company_zip_code", with: zip_code
        fill_in "company_city", with: city
        fill_in "company_name", with: name
        fill_in "company_referent_phone_number", with: phone_number
        fill_in "company_description", with: description
        fill_in "company_website", with: website
        click_on "Continuer"
        sleep 0.1
        skills.each do |skill|
          find("label[for=company_skill_ids_#{skill.id}]").click
        end
        sub_skills.each do |sub_skill|
          find("label[for=company_sub_skill_ids_#{sub_skill.id}]").click
        end
        click_on "Continuer"
        sleep 0.1
        fill_in "company_job", with: job
        select take_trainee ? "Oui" : "Non", from: "company_take_trainee"
        select propose_workshop ? "Oui" : "Non", from: "company_propose_workshop"
        select propose_summer_job ? "Oui" : "Non", from: "company_propose_summer_job"
        click_on "Enregistrer"
      end
      sleep 0.1

      expect(Company.last).to have_attributes(company_type_id: company_type.id, zip_code: zip_code, city: city, name: name, referent_phone_number: phone_number, description: description)
      expect(Company.last.skills).to match_array skills
      expect(Company.last.sub_skills).to match_array sub_skills
      expect(UserCompany.last).to have_attributes(user_id: voluntary.id, company_id: Company.last.id, admin: true, owner: true)
    end

    it "Teacher can't create a company" do
      teacher = create(:user, :teacher)
      teacher.confirm
      sign_in teacher

      visit new_company_path
      expect(page).to have_current_path(root_path)  # user est redirigé vers la page d'accueil
      # expect(page).to have_content "Vous n'êtes pas autorisé.e à effectuer cette action."
    end
  end
end
