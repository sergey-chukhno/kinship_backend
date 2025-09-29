require "rails_helper"

RSpec.describe ProjectSchoolLevel, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:school_level) }
  end
end
