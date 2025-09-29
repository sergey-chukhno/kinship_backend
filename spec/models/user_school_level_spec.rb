require "rails_helper"

RSpec.describe UserSchoolLevel, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "associations" do
    it { should belong_to(:school_level) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    subject { create(:user_school_level) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:school_level_id) }
  end
end
