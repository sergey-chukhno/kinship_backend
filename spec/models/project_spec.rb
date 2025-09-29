require "rails_helper"

RSpec.describe Project, type: :model do
  # do me the test for project model
  it { is_expected.to have_a_valid_factory }

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should validate_presence_of(:owner) }
  end

  describe "associations" do
    it { should belong_to(:owner) }
    it { should have_many(:project_school_levels) }
    it { should have_many(:school_levels).through(:project_school_levels) }
    it { should have_many(:project_tags) }
    it { should have_many(:tags).through(:project_tags) }
    it { should have_many(:project_skills) }
    it { should have_many(:skills).through(:project_skills) }
    it { should have_many(:keywords) }
    it { should have_many(:links) }
    it { should have_many(:teams) }
    it { should have_many_attached(:pictures) }
    it { should have_one_attached(:main_picture) }
    it { should have_many_attached(:documents) }
    it { should accept_nested_attributes_for(:project_tags).allow_destroy(true) }
    it { should accept_nested_attributes_for(:links).allow_destroy(true) }
    it { should accept_nested_attributes_for(:project_skills).allow_destroy(true) }
    it { should accept_nested_attributes_for(:teams).allow_destroy(true) }
  end

  describe "#start_date_before_end_date" do
    it "should not be valid if start_date is after end_date" do
      project = build(:project, start_date: DateTime.parse("2023-07-10 10:02:14"), end_date: DateTime.parse("2023-07-07 10:02:14"))
      expect(project).not_to be_valid
    end

    it "should be valid if start_date is before end_date" do
      project = build(:project, start_date: DateTime.parse("2023-07-07 10:02:14"), end_date: DateTime.parse("2023-07-10 10:02:14"))
      expect(project).to be_valid
    end
  end

  describe "#formatted_date_start" do
    it "should return a formatted date" do
      project = build(:project, start_date: DateTime.parse("2023-07-07 10:02:14"))
      expect(project.formatted_date_start).to eq("07/07/2023 10:02")
    end
  end

  describe "#formatted_date_end" do
    it "should return a formatted date" do
      project = build(:project, end_date: DateTime.parse("2023-07-07 10:02:14"))
      expect(project.formatted_date_end).to eq("07/07/2023 10:02")
    end
  end
end
