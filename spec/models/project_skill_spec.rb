require "rails_helper"

RSpec.describe ProjectSkill, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "validations" do
    subject { create(:project_skill) }
    it { should validate_uniqueness_of(:project_id).scoped_to(:skill_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:skill) }
  end
end
