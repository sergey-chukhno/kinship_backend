require "rails_helper"

describe "Users can see participants list", type: :feature, javascript: true do
  let(:user) { create(:user, :teacher, email: "test@ac-nantes.fr") }
  let(:toto_user) { create(:user, :tutor, first_name: "TOTO", expend_skill_to_school: true) }
  let(:tata_user) { create(:user, :tutor, first_name: "TATA", expend_skill_to_school: true) }
  let(:bobo_user) { create(:user, :tutor, first_name: "BOBO", expend_skill_to_school: true) }
  let(:baba_user) { create(:user, :tutor, first_name: "BABA", expend_skill_to_school: true) }
  let(:first_school) { create(:school, name: "Lycée du test", zip_code: "44000", city: "Nantes") }
  let(:second_school) { create(:school, name: "Ecole du test", zip_code: "44000", city: "Nantes") }
  let(:first_skill) { create(:skill, name: "Skill 1") }
  let(:second_skill) { create(:skill, name: "Skill 2") }

  before do
    create(:user_school, user: user, school: first_school)
    create(:user_school, user: toto_user, school: first_school)
    create(:user_school, user: tata_user, school: first_school)
    create(:user_school, user: bobo_user, school: first_school)
    create(:user_school, user: baba_user, school: second_school)
    create(:user_skill, user: toto_user, skill: first_skill)
    create(:availability, user: toto_user, monday: true)
    create(:availability, user: tata_user, monday: true)
    sign_in user
  end

  # TODO : fix this test
  # context "When user go on participants index page" do
  #   it "should see participants list in here school" do
  #     visit participants_path
  #     expect(page).to have_content "Rechercher des participants pour vos projets"
  #     expect(page).to have_content "TOTO"
  #     expect(page).to have_content "TATA"
  #     expect(page).to have_content "BOBO"
  #     expect(page).to_not have_content "BABA"
  #   end

  #   it "should see participants list filter by skill" do
  #     visit participants_path(by_skills: {skill_ids: [first_skill.id]})
  #     expect(page).to have_content "TOTO"
  #     expect(page).to_not have_content "TATA"
  #     expect(page).to_not have_content "BOBO"
  #     expect(page).to_not have_content "BABA"
  #   end

  #   it "should not see participants list filter by skill if user ton have skill" do
  #     visit participants_path(by_skills: {skill_ids: [second_skill.id]})
  #     expect(page).to_not have_content "TOTO"
  #     expect(page).to_not have_content "TATA"
  #     expect(page).to_not have_content "BOBO"
  #     expect(page).to_not have_content "BABA"
  #     expect(page).to have_content "Aucun participant ne correspond à votre recherche"
  #   end

  #   it "should see participants list filter by availability" do
  #     visit participants_path(by_monday: 1)
  #     expect(page).to have_content "TOTO"
  #     expect(page).to have_content "TATA"
  #     expect(page).to_not have_content "BOBO"
  #     expect(page).to_not have_content "BABA"
  #   end

  #   it "should not see participants list filter by availability if user ton have availability" do
  #     visit participants_path(by_thursday: 1)
  #     expect(page).to_not have_content "TOTO"
  #     expect(page).to_not have_content "TATA"
  #     expect(page).to_not have_content "BOBO"
  #     expect(page).to_not have_content "BABA"
  #     expect(page).to have_content "Aucun participant ne correspond à votre recherche"
  #   end
  # end
end
