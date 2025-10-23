require "rails_helper"

describe "Users can see projects", type: :feature, javascript: true do
  let(:user) { create(:user, :tutor, last_name: "TOTO") }
  let(:school) { create(:school, name: "Lycée du test", zip_code: "44000", city: "Nantes", school_type: "primaire") }
  let(:school_level) { create(:school_level, name: "Paquerette", level: "cm1", school: school) }
  let(:tag_1) { create(:tag, name: "Tag") }
  let(:tag_2) { create(:tag, name: "Tag 2") }
  let(:project_1) { create(:project, title: "Projet 1") }
  let(:project_2) { create(:project, title: "Projet 2") }
  let(:project_3) { create(:project, title: "Projet 3") }

  before do
    user.confirm
    create(:availability, user: user)
    create(:user_school, user: user, school: school)
    create(:user_school_level, user: user, school_level: school_level)
    create(:project_school_level, project: project_1, school_level: school_level)
    create(:project_school_level, project: project_2, school_level: school_level)
    create(:project_school_level, project: project_3, school_level: school_level)
    create(:project_tag, project: project_1, tag: tag_1)
    login_as(user)
  end

  context "When user go on project index page" do
    it "should see projects filter by his school" do
      visit projects_path
      expect(page).to have_content "Projets"
      expect(page).to have_content "Projet 1"
      expect(page).to have_content "Projet 2"
      expect(page).to have_content "Projet 3"
    end

    it "should not see projects in my project tab if user dont have project" do
      visit projects_path
      click_on "Mes projets"
      expect(page).to have_content "Aucun projet ne correspond à votre recherche"
    end

    it "should see projects in my project tab if user have project" do
      school_level = SchoolLevel.find_by(name: "Paquerette")
      own_project = create(:project, title: "my own project", owner_id: user.id)
      create(:project_school_level, project: own_project, school_level: school_level)

      visit projects_path
      click_on "Mes projets"
      expect(page).to have_content "my own project"
    end

    it "should see projects filter by tag" do
      visit projects_path(by_tags: {tag_ids: [tag_1.id]})
      expect(page).to have_content "Projet 1"
      expect(page).not_to have_content "Projet 2"
      expect(page).not_to have_content "Projet 3"
    end

    it "should not see projects filter by tag if project ton have tag" do
      visit projects_path(by_tags: {tag_ids: [tag_2.id]})
      expect(page).not_to have_content "Projet 1"
      expect(page).not_to have_content "Projet 2"
      expect(page).not_to have_content "Projet 3"
    end

    it "should see kinship project any where if a project don't have a school" do
      create(:project, title: "Projet 4")
      visit projects_path
      expect(page).to have_content "Projets"
      expect(page).to have_content "Projet 1"
      expect(page).to have_content "Projet 2"
      expect(page).to have_content "Projet 3"
      expect(page).to have_content "Projet 4"
      expect(page).to have_content "Projet Kinship"
    end

    it "should see kinship project with tag filter any where if a project don't have a school" do
      kinship_project = create(:project, title: "Projet 4")
      create(:project_tag, project: kinship_project, tag: tag_2)

      visit projects_path(by_tags: {tag_ids: [tag_2.id]})
      expect(page).not_to have_content "Projet 1"
      expect(page).not_to have_content "Projet 2"
      expect(page).not_to have_content "Projet 3"
      expect(page).to have_content "Projet 4"
      expect(page).to have_content "Projet Kinship"
    end

    it "should not see kinship project with tag filter if we don't have the right tag" do
      kinship_project = create(:project, title: "Projet 4")
      create(:project_tag, project: kinship_project, tag: tag_2)

      visit projects_path(by_tags: {tag_ids: [tag_1.id]})
      expect(page).to have_content "Projet 1"
      expect(page).not_to have_content "Projet 2"
      expect(page).not_to have_content "Projet 3"
      expect(page).not_to have_content "Projet 4"
      expect(page).not_to have_content "Projet Kinship"
    end
  end
end
