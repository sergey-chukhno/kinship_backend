require "rails_helper"

RSpec.describe Keyword, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "validations" do
    context "with a valid project" do
      let!(:project) { create(:project) }
      let!(:keyword) { create(:keyword, project:) }

      it { should validate_presence_of(:name) }
      it { should validate_uniqueness_of(:name).scoped_to(:project_id) }
    end
  end

  describe "associations" do
    it { should belong_to :project }
  end
end
