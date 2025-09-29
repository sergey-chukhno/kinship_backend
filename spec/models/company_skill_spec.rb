require "rails_helper"

RSpec.describe CompanySkill, type: :model do
  describe "factory" do
    it "should have a valid factory" do
      expect(build(:company_skill)).to be_valid
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:skill) }
  end
end
