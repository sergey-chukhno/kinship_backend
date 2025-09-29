require "rails_helper"

RSpec.describe Contract, type: :model do
  describe "factory" do
    it "should have a valid factory with :school trait" do
      expect(build(:contract, :school)).to be_valid
    end

    it "should have a valid factory with :company trait" do
      expect(build(:contract, :company)).to be_valid
    end

    it "should have a valid factory with :active trait" do
      expect(build(:contract, :active, :school)).to be_valid
    end
    it "should have a valid factory with :expired trait" do
      expect(build(:contract, :expired, :company)).to be_valid
    end
  end

  describe "associations" do
    it { should belong_to(:school).optional }
    it { should belong_to(:company).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:start_date) }
    it "should have school or company but not both" do
      expect(build(:contract)).not_to be_valid
      expect(build(:contract, :school)).to be_valid
      expect(build(:contract, :company)).to be_valid
      expect(build(:contract, :school, :company)).not_to be_valid
    end

    it "should have start_date before end_date" do
      expect(build(:contract, start_date: Time.now, end_date: Time.now - 1.year)).not_to be_valid
    end

    it "should not have active contract if end date expired" do
      expect(build(:contract, :school, :active, start_date: Time.now - 2.year, end_date: Time.now - 1.year)).not_to be_valid
    end

    it "should have only one contract active per school" do
      school = create(:school, :confirmed)
      create(:contract, :school, :active, school: school)
      expect(build(:contract, :active, school: school)).not_to be_valid
    end

    it "should have only one contract active per company" do
      company = create(:company, :confirmed)
      create(:contract, :company, :active, company: company)
      expect(build(:contract, :active, company: company)).not_to be_valid
    end

    it "should not being able to have contract if school is not confirmed" do
      pending_school = create(:school, :pending)
      expect(build(:contract, :school, school: pending_school)).not_to be_valid

      confirmed_school = create(:school, :confirmed)
      expect(build(:contract, :school, school: confirmed_school)).to be_valid
    end

    it "should not being able to have contract if company is not confirmed" do
      pending_company = create(:company, :pending)
      expect(build(:contract, :company, company: pending_company)).not_to be_valid

      confirmed_company = create(:company, :confirmed)
      expect(build(:contract, :company, company: confirmed_company)).to be_valid
    end

    it "should not being able to have contract if school don't have owner" do
      school = create(:school, :confirmed)
      contract = build(:contract, :school, school: school)
      expect(contract).to be_valid

      school.user_schools.destroy_all
      expect(contract).not_to be_valid
    end

    it "should not being able to have contract if company don't have owner" do
      company = create(:company, :confirmed)
      contract = build(:contract, :company, company: company)
      expect(contract).to be_valid

      company.user_companies.destroy_all
      expect(contract).not_to be_valid
    end
  end
end
