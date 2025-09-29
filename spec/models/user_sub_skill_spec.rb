require "rails_helper"

RSpec.describe UserSubSkill, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "validations" do
    subject { create(:user_sub_skill) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:sub_skill_id) }
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:sub_skill) }
  end
end
