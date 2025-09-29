require "rails_helper"

RSpec.describe CompanySubSkill, type: :model do
  describe "factory" do
    it "should have a valid factory" do
      expect(build(:company_sub_skill)).to be_valid
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:sub_skill) }
  end
end
