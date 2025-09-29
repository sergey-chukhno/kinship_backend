require "rails_helper"

RSpec.describe Skill, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "associations" do
    it { should have_many(:user_skills) }
    it { should have_many(:users).through(:user_skills) }
    it { should have_many(:company_skills) }
    it { should have_many(:project_skills) }
    it { should have_many(:projects).through(:project_skills) }
    it { should have_many(:sub_skills) }
    it { should accept_nested_attributes_for(:sub_skills).allow_destroy(true) }
  end

  describe "when created with official" do
    let(:skill) { create(:skill, :official) }
    it "should offical set at true" do
      expect(skill.official).to be_truthy
    end
  end
end
