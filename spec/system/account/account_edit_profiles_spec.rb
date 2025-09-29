require "rails_helper"

RSpec.describe "Account::EditProfiles", type: :system do
  let(:role_custom) { Faker::Lorem.word }
  let(:first_name) { Faker::Name.first_name }
  let(:last_name) { Faker::Name.last_name }
  let(:accept_marketing) { Faker::Boolean.boolean }

  before do
    driven_by(:selenium_chrome_headless)
  end

  context "Everyone can edit her profiles" do
    it "Tutor can edit her profiles" do
      role = User::PARENTS_ADDITIONAL_ROLES.sample
      tutor = create(:user, :tutor)
      Availability.create(user: tutor)
      tutor.confirm
      sign_in tutor

      visit edit_account_profile_path(tutor)
      expect(page).to have_content I18n.t(tutor.role, scope: [:views, :account, :profile, :text, :global_info])

      within("#edit_user_#{tutor.id}") do
        find("label", text: role.capitalize).click
        if role == "Autres"
          fill_in "user[role_additional_information_custom]", with: role_custom
        end
        fill_in "user[first_name]", with: first_name
        fill_in "user[last_name]", with: last_name
        find("label", text: I18n.t(tutor.role, scope: [:views, :account, :profile, :form, :accept_marketing])).click if accept_marketing
        click_on "Enregistrer"
      end

      sleep(0.01)
      tutor.reload
      expect(tutor).to have_attributes(role_additional_information: (role == "Autres") ? role_custom : role, first_name: first_name, last_name: last_name, accept_marketing: accept_marketing)
    end

    it "Voluntary can edit her profiles" do
      role = User::VOLUNTARYS_ADDITIONAL_ROLES.sample
      voluntary = create(:user, :voluntary)
      Availability.create(user: voluntary)
      voluntary.confirm
      sign_in voluntary

      visit edit_account_profile_path(voluntary)
      expect(page).to have_content I18n.t(voluntary.role, scope: [:views, :account, :profile, :text, :global_info])

      within("#edit_user_#{voluntary.id}") do
        find("label", text: role.capitalize).click
        if role == "Autres"
          fill_in "user[role_additional_information_custom]", with: role_custom
        end
        fill_in "user[first_name]", with: first_name
        fill_in "user[last_name]", with: last_name
        find("label", text: I18n.t(voluntary.role, scope: [:views, :account, :profile, :form, :accept_marketing])).click if accept_marketing
        click_on "Enregistrer"
      end

      sleep(0.01)
      voluntary.reload
      expect(voluntary).to have_attributes(role_additional_information: (role == "Autres") ? role_custom : role, first_name: first_name, last_name: last_name, accept_marketing: accept_marketing)
    end

    it "Teacher can edit her profiles" do
      role = User::TEACHERS_ADDITIONAL_ROLES.sample
      custom_email = Faker::Internet.email
      teacher = create(:user, :teacher, email: "example@ac-nantes.fr")
      Availability.create(user: teacher)
      teacher.confirm
      sign_in teacher

      visit edit_account_profile_path(teacher)
      expect(page).to have_content I18n.t(teacher.role, scope: [:views, :account, :profile, :text, :global_info])

      within("#edit_user_#{teacher.id}") do
        find("label", text: role.capitalize).click
        if role == "Autres"
          fill_in "user[role_additional_information_custom]", with: role_custom
        end
        fill_in "user[contact_email]", with: custom_email
        fill_in "user[first_name]", with: first_name
        fill_in "user[last_name]", with: last_name
        find("label", text: I18n.t(teacher.role, scope: [:views, :account, :profile, :form, :accept_marketing])).click if accept_marketing
        click_on "Enregistrer"
      end

      sleep(0.01)
      teacher.reload
      expect(teacher).to have_attributes(role_additional_information: (role == "Autres") ? role_custom : role, first_name: first_name, last_name: last_name, contact_email: custom_email, accept_marketing: accept_marketing)
    end
  end
end
