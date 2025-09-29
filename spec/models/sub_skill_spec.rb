require "rails_helper"

RSpec.describe SubSkill, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "validations" do
    subject { create(:sub_skill) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:skill_id) }
  end

  describe "associations" do
    it { should belong_to(:skill) }
    it { should have_many(:user_sub_skills) }
    it { should have_many(:users).through(:user_sub_skills) }
    it { should have_many(:company_sub_skills).dependent(:destroy) }
  end
end
