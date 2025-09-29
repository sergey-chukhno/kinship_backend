require "rails_helper"

RSpec.describe SchoolLevel, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "validations" do
    it { should validate_presence_of(:level) }
    it { should validate_presence_of(:name) }
  end

  describe "associations" do
    it { should belong_to(:school) }
    it { should have_many(:project_school_levels) }
    it { should have_many(:projects).through(:project_school_levels) }
  end

  describe "#level_name" do
    it "should return a formatted level name" do
      school_level = build(:school_level, level: "cap", name: "Paquerette")
      expect(school_level.level_name).to eq("CAP")
    end
  end

  describe "#full_name" do
    it "should return a formatted full name" do
      school = create(:school, name: "Ecole du test", city: "Paris", zip_code: "75000", school_type: "lycee")
      school_level = build(:school_level, level: "cap", name: "Paquerette", school: school)
      expect(school_level.full_name).to eq("CAP Paquerette - Ecole du test, Paris (75000)")
    end
  end
end
