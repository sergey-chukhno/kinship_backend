require "rails_helper"

RSpec.describe SchoolCompany, type: :model do
  describe "factory" do
    it "should have valid factory" do
      expect(build(:school_company)).to be_valid
    end

    it "should have valid factory with :pending trait" do
      expect(build(:school_company, :pending)).to be_valid
      expect(build(:school_company, :pending).status).to eq("pending")
    end

    it "should have valid factory with :confirmed trait" do
      expect(build(:school_company, :confirmed)).to be_valid
      expect(build(:school_company, :confirmed).status).to eq("confirmed")
    end
  end

  describe "associations" do
    it { should belong_to(:school) }
    it { should belong_to(:company) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_values({pending: 0, confirmed: 1}) }
  end

  describe "validations" do
    subject { build(:school_company) }

    it { should validate_presence_of(:status) }
    it { should validate_uniqueness_of(:company_id).scoped_to(:school_id) }
  end
end
