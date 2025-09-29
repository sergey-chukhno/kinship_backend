require "rails_helper"

RSpec.describe "School::Creates", type: :system do
  let(:type) { School.school_types.keys.sample }
  let(:zip_code) { Faker::Address.zip_code }
  let(:city) { Faker::Address.city }
  let(:name) { Faker::Company.name }
  let(:phone_number) { Faker::PhoneNumber.phone_number }

  before do
    driven_by(:rack_test)
  end

  context "only Teachers can create a school" do
    it "Tutor can't create a school" do
      tutor = create(:user, :tutor)
      tutor.confirm
      sign_in tutor

      visit new_school_path
      expect(page).to have_content "Vous n'êtes pas autorisé.e à effectuer cette action."
    end

    it "Voluntary can't create a school" do
      voluntary = create(:user, :voluntary)
      voluntary.confirm
      sign_in voluntary

      visit new_school_path
      expect(page).to have_content "Vous n'êtes pas autorisé.e à effectuer cette action."
    end

    it "Teacher can create a school" do
      teacher = create(:user, :teacher)
      teacher.confirm
      sign_in teacher

      visit new_school_path
      expect(page).to have_content "Demande d'ajout d'un établissement"

      within("#new_school") do
        select type, from: "school_school_type"
        fill_in "school_zip_code", with: zip_code
        fill_in "school_city", with: city
        fill_in "school_name", with: name
        fill_in "school_referent_phone_number", with: phone_number
        click_on "Enregistrer"
      end
      sleep 0.1

      expect(School.last).to have_attributes(school_type: type, zip_code: zip_code, city: city, name: name, referent_phone_number: phone_number, status: "pending")
    end
  end
end
