require "rails_helper"

RSpec.describe ProjectTag, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "validations" do
    subject { create(:project_tag) }
    it { should validate_uniqueness_of(:tag_id).scoped_to(:project_id) }
  end

  describe "associations" do
    it { should belong_to(:tag) }
    it { should belong_to(:project) }
  end
end
