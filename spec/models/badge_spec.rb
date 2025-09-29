require "rails_helper"

RSpec.describe Badge, type: :model do
  describe "Associations" do
    it { should have_one_attached(:icon) }
  end

  describe "Validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:level) }
    it { should validate_presence_of(:icon) }
  end

  describe "Factories" do
    it "should have valid factory" do
      expect(build(:badge)).to be_valid
    end

    it "should have valid factory with trait level_1" do
      expect(build(:badge, :level_1)).to be_valid
    end

    it "should have level_1 badge with trait level_1" do
      expect(build(:badge, :level_1)).to be_level_1
    end

    it "should have valid factory with trait level_2" do
      expect(build(:badge, :level_2)).to be_valid
    end

    it "should have level_2 badge with trait level_2" do
      expect(build(:badge, :level_2)).to be_level_2
    end

    it "should have valid factory with trait level_3" do
      expect(build(:badge, :level_3)).to be_valid
    end

    it "should have level_3 badge with trait level_3" do
      expect(build(:badge, :level_3)).to be_level_3
    end

    it "should have valid factory with trait level_4" do
      expect(build(:badge, :level_4)).to be_valid
    end

    it "should have level_4 badge with trait level_4" do
      expect(build(:badge, :level_4)).to be_level_4
    end
  end
end
