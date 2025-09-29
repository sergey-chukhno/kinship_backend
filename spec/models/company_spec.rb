require "rails_helper"

RSpec.describe Company, type: :model do
  describe "factory" do
    it "should have valid factory" do
      expect(build(:company)).to be_valid
    end

    it "should have valid factory with :pending trait" do
      expect(build(:company, :pending)).to be_valid
      expect(build(:company, :pending).status).to eq("pending")
    end

    it "should have valid factory with :confirmed trait" do
      expect(build(:company, :confirmed)).to be_valid
      expect(build(:company, :confirmed).status).to eq("confirmed")
    end
  end

  describe "associations" do
    it { should have_many(:user_companies).dependent(:destroy) }
    it { should have_many(:contracts).dependent(:destroy) }
    it { should have_many(:company_skills).dependent(:destroy) }
    it { should have_many(:company_sub_skills).dependent(:destroy) }
    it { should belong_to(:company_type) }
    it { should have_many(:school_companies).dependent(:destroy) }
  end

  describe "enum" do
    it { should define_enum_for(:status).with_values({pending: 0, confirmed: 1}) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:zip_code) }
    it { should validate_presence_of(:city) }
    it { should validate_presence_of(:referent_phone_number) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:company_type_id) }
  end

  describe "nested attributes" do
    it { should accept_nested_attributes_for(:company_skills).allow_destroy(true) }
    it { should accept_nested_attributes_for(:company_sub_skills).allow_destroy(true) }
  end

  describe "methods" do
    describe "#full_name" do
      it "should return full name" do
        company = create(:company)
        expect(company.full_name).to eq("#{company.name}, #{company.city} (#{company.zip_code})")
      end
    end

    describe "#owner?" do
      it "should return true if company has owner" do
        company = create(:company)
        create(:user_company, :owner, company: company)
        expect(company.owner?).to eq(true)
      end

      it "should return false if company has no owner" do
        company = create(:company)
        expect(company.owner?).to eq(false)
      end
    end

    describe "#owner" do
      it "should return owner" do
        company = create(:company)
        user_company = create(:user_company, :owner, company: company)
        expect(company.owner).to eq(user_company)
      end
    end

    describe "#admins?" do
      it "should return true if company has admins" do
        company = create(:company)
        create(:user_company, :admin, company: company)
        expect(company.admins?).to eq(true)
      end

      it "should return false if company has no admins" do
        company = create(:company)
        expect(company.admins?).to eq(false)
      end
    end

    describe "#admins" do
      it "should return admins" do
        company = create(:company)
        user_company = create(:user_company, :admin, company: company)
        expect(company.admins).to eq([user_company])
      end
    end

    describe "#users_waiting_for_confirmation?" do
      it "should return true if company has users waiting for confirmation" do
        company = create(:company)
        create(:user_company, :pending, company: company)
        expect(company.users_waiting_for_confirmation?).to eq(true)
      end

      it "should return false if company has no users waiting for confirmation" do
        company = create(:company)
        expect(company.users_waiting_for_confirmation?).to eq(false)
      end
    end

    describe "#users_waiting_for_confirmation" do
      it "should return users waiting for confirmation" do
        company = create(:company)
        user_company = create(:user_company, :pending, company: company)
        expect(company.users_waiting_for_confirmation).to eq([user_company])
      end
    end
  end
end
