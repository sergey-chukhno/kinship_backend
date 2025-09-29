require "rails_helper"

RSpec.describe TeamMember, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:team) }
  end

  describe "validations" do
    subject { create(:team_member) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:team_id) }
  end
end
