require "rails_helper"

RSpec.describe Tag, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
  end

  describe "associations" do
    it { should have_many(:project_tags).dependent(:destroy) }
    it { should have_many(:projects).through(:project_tags) }
  end
end
