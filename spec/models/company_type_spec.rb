require "rails_helper"

RSpec.describe CompanyType, type: :model do
  describe "factory" do
    it "should have valid factory" do
      expect(build(:company_type)).to be_valid
    end
  end

  describe "associations" do
    it { should have_one(:company) }
  end

  describe "validations" do
    subject { create(:company_type) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
  end
end
