require "rails_helper"

RSpec.describe Link, type: :model do
  describe "associations" do
    it { should belong_to(:project) }
  end

  describe "validations" do
    subject { create(:link) }
    it { should validate_presence_of(:url) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:url).scoped_to(:project_id) }
  end

  describe "#validate_url" do
    it "should not be valid if url is empty" do
      link = build(:link, url: "")
      expect(link).not_to be_valid
    end

    it "shoudl not be valid if url is not valid" do
      link = build(:link, url: "blablabla")
      expect(link).not_to be_valid
    end

    it "should be valid if url is valid" do
      link = build(:link, url: "https://drakkar.io/")
      expect(link).to be_valid
    end
  end
end
