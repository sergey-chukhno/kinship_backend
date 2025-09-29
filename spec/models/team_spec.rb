require "rails_helper"

RSpec.describe Team, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:description) }
  end

  describe "associations" do
    it { should belong_to(:project) }
    it { should have_many(:team_members) }
    it { should have_many(:members).through(:team_members) }
    it { should have_many(:users).through(:team_members) }
    it { should accept_nested_attributes_for(:team_members).allow_destroy(true) }
  end
end
