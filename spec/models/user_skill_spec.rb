require "rails_helper"

RSpec.describe UserSkill, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "validations" do
    subject { create(:user_skill) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:skill_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:skill) }
  end
end
