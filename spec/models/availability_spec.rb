require "rails_helper"

RSpec.describe Availability, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "associations" do
    it { should belong_to(:user) }
  end
end
