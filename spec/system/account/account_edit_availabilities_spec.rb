require "rails_helper"

RSpec.describe "Account::EditAvailabilities", type: :system do
  let(:monday) { Faker::Boolean.boolean }
  let(:tuesday) { Faker::Boolean.boolean }
  let(:wednesday) { Faker::Boolean.boolean }
  let(:thursday) { Faker::Boolean.boolean }
  let(:friday) { Faker::Boolean.boolean }
  let(:other) { Faker::Boolean.boolean }

  before do
    driven_by(:selenium_chrome_headless)
  end

  context "only Tutors and Voluntarys can edit her availabilities" do
    it "Tutor can edit her availabilities" do
      tutor = create(:user, :tutor)
      tutor.confirm
      sign_in tutor

      visit edit_account_availability_path(tutor)
      expect(page).to have_content "Je suis disponible pour accompagner une sortie scolaire avec la classe de mon(mes) enfant(s)"

      within("#edit_user_#{tutor.id}") do
        find("label", text: "Oui").click
        find("label", text: "Lundi").click if monday
        find("label", text: "Mardi").click if tuesday
        find("label", text: "Mercredi").click if wednesday
        find("label", text: "Jeudi").click if thursday
        find("label", text: "Vendredi").click if friday
        find("label", text: "Au cas par cas").click if other
        click_on "Enregistrer"
      end
      sleep(0.01)
      tutor.reload
      expect(tutor.availability).to have_attributes(monday: monday, tuesday: tuesday, wednesday: wednesday, thursday: thursday, friday: friday, other: other)

      within("#edit_user_#{tutor.id}") do
        find("label", text: "Non").click
        click_on "Enregistrer"
      end

      sleep(0.01)
      tutor.reload
      expect(tutor.availability).to have_attributes(monday: false, tuesday: false, wednesday: false, thursday: false, friday: false, other: false)
    end

    # it "Voluntary can edit her availabilities" do
    #   voluntary = create(:user, :voluntary)
    #   voluntary.confirm
    #   sign_in voluntary

    #   visit edit_account_availability_path(voluntary)
    #   sleep(0.01)
    #   expect(page).to have_content "Je suis disponible pour réaliser un atelier, aider un projet, accompagner une sortie"

    #   sleep(0.01)
    #   within("#edit_user_#{voluntary.id}") do
    #     find("label", text: "Oui").click
    #     find("label", text: "Lundi").click if monday
    #     find("label", text: "Mardi").click if tuesday
    #     find("label", text: "Mercredi").click if wednesday
    #     find("label", text: "Jeudi").click if thursday
    #     find("label", text: "Vendredi").click if friday
    #     find("label", text: "Au cas par cas").click if other
    #     click_on "Enregistrer"
    #   end

    #   sleep(0.01)
    #   voluntary.reload
    #   expect(voluntary.availability).to have_attributes(monday: monday, tuesday: tuesday, wednesday: wednesday, thursday: thursday, friday: friday, other: other)

    #   within("#edit_user_#{voluntary.id}") do
    #     find("label", text: "Non").click
    #     click_on "Enregistrer"
    #   end

    #   sleep(0.01)
    #   voluntary.reload
    #   expect(voluntary.availability).to have_attributes(monday: false, tuesday: false, wednesday: false, thursday: false, friday: false, other: false)
    # end

    it "Teacher can't edit her availabilities" do
      teacher = create(:user, :teacher, email: "example@ac-nantes.fr")
      teacher.confirm
      sign_in teacher

      visit edit_account_availability_path(teacher)
      expect(page).to have_content "Vous n'êtes pas autorisé.e à effectuer cette action."
    end
  end
end
