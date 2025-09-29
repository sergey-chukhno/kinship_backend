require "rails_helper"

RSpec.describe "Account::EditSkills", type: :system do
  Skill.destroy_all
  6.times do
    skill = Skill.create(name: Faker::Alphanumeric.alpha(number: 10), official: true)
    3.times do
      skill.sub_skills.create(name: Faker::Alphanumeric.alpha(number: 10))
    end
  end
  let(:skills) { Skill.officials.sample(5) }
  let(:sub_skills) { skills.map { |skill| skill.sub_skills.sample(2) }.flatten }
  let(:skill_additional_information) { Faker::Lorem.sentence }

  before do
    driven_by(:selenium_chrome_headless)
  end

  context "Everyone can edit her skills" do
    it "Tutor can edit her skills" do
      tutor = create(:user, :tutor)
      Availability.create(user: tutor)
      tutor.confirm
      sign_in tutor

      visit edit_account_skill_path(tutor)
      expect(page).to have_content I18n.t(tutor.role, scope: [:views, :account, :skills, :text, :global_info])

      within("#edit_user_#{tutor.id}") do
        find("label", text: "Oui").click
        skills.each do |skill|
          find("label", text: skill.name).click
        end
        sub_skills.each do |sub_skill|
          find("label", text: sub_skill.name).click
        end
        fill_in "user[skill_additional_information]", with: skill_additional_information
        click_on "Enregistrer"
      end

      sleep(0.01)
      tutor.reload
      expect(tutor).to have_attributes(skill_additional_information: skill_additional_information, show_my_skills: true, expend_skill_to_school: true)
      expect(tutor.skills).to match_array skills
      expect(tutor.sub_skills).to match_array sub_skills

      visit edit_account_skill_path(tutor)
      expect(page).to have_content I18n.t(tutor.role, scope: [:views, :account, :skills, :text, :global_info])

      within("#edit_user_#{tutor.id}") do
        find("div", class: "user_show_my_skills").find("label", text: "Non").click
        click_on "Enregistrer"
      end

      sleep(0.01)
      tutor.reload
      expect(tutor).to have_attributes(skill_additional_information: "", show_my_skills: false)
      expect(tutor.skills).to be_empty
      expect(tutor.sub_skills).to be_empty
    end

    it "Voluntary can edit her skills" do
      voluntary = create(:user, :voluntary)
      Availability.create(user: voluntary)
      voluntary.confirm
      sign_in voluntary

      visit edit_account_skill_path(voluntary)
      expect(page).to have_content I18n.t(voluntary.role, scope: [:views, :account, :skills, :text, :global_info])

      within("#edit_user_#{voluntary.id}") do
        find("label", text: "Oui").click
        skills.each do |skill|
          find("label", text: skill.name).click
        end
        sub_skills.each do |sub_skill|
          find("label", text: sub_skill.name).click
        end
        fill_in "user[skill_additional_information]", with: skill_additional_information
        click_on "Enregistrer"
      end

      sleep(0.01)
      voluntary.reload
      expect(voluntary).to have_attributes(skill_additional_information: skill_additional_information, show_my_skills: true, expend_skill_to_school: true)
      expect(voluntary.skills).to match_array skills
      expect(voluntary.sub_skills).to match_array sub_skills

      visit edit_account_skill_path(voluntary)
      expect(page).to have_content I18n.t(voluntary.role, scope: [:views, :account, :skills, :text, :global_info])

      within("#edit_user_#{voluntary.id}") do
        find("div", class: "user_show_my_skills").find("label", text: "Non").click
        click_on "Enregistrer"
      end

      sleep(0.01)
      voluntary.reload
      expect(voluntary).to have_attributes(skill_additional_information: "", show_my_skills: false)
      expect(voluntary.skills).to be_empty
      expect(voluntary.sub_skills).to be_empty
    end

    it "Teacher can edit her skills" do
      teacher = create(:user, :teacher, email: "example@ac-nantes.fr")
      Availability.create(user: teacher)
      teacher.confirm
      sign_in teacher

      visit edit_account_skill_path(teacher)
      expect(page).to have_content I18n.t(teacher.role, scope: [:views, :account, :skills, :text, :global_info])

      within("#edit_user_#{teacher.id}") do
        find("label", text: "Oui").click
        skills.each do |skill|
          find("label", text: skill.name).click
        end
        sub_skills.each do |sub_skill|
          find("label", text: sub_skill.name).click
        end
        fill_in "user[skill_additional_information]", with: skill_additional_information
        click_on "Enregistrer"
      end

      sleep(0.01)
      teacher.reload
      expect(teacher).to have_attributes(skill_additional_information: skill_additional_information, show_my_skills: true, expend_skill_to_school: true)
      expect(teacher.skills).to match_array skills
      expect(teacher.sub_skills).to match_array sub_skills

      visit edit_account_skill_path(teacher)
      expect(page).to have_content I18n.t(teacher.role, scope: [:views, :account, :skills, :text, :global_info])

      within("#edit_user_#{teacher.id}") do
        find("div", class: "user_show_my_skills").find("label", text: "Non").click
        click_on "Enregistrer"
      end

      sleep(0.01)
      teacher.reload
      expect(teacher).to have_attributes(skill_additional_information: "", show_my_skills: false)
      expect(teacher.skills).to be_empty
      expect(teacher.sub_skills).to be_empty
    end
  end
end
