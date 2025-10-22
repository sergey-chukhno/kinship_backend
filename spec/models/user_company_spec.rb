require "rails_helper"

RSpec.describe UserCompany, type: :model do
  describe "factory" do
    it "should have valid factory" do
      expect(build(:user_company)).to be_valid
    end

    it "should have valid factory with :pending trait" do
      expect(build(:user_company, :pending)).to be_valid
      expect(build(:user_company, :pending).status).to eq("pending")
    end

    it "should have valid factory with :confirmed trait" do
      expect(build(:user_company, :confirmed)).to be_valid
      expect(build(:user_company, :confirmed).status).to eq("confirmed")
    end

    it "should have valid factory with :admin trait" do
      expect(build(:user_company, :admin)).to be_valid
      expect(build(:user_company, :admin).role).to eq("admin")
      expect(build(:user_company, :admin).admin?).to eq(true)
    end

    it "should have valid factory with :owner trait" do
      expect(build(:user_company, :owner)).to be_valid
      expect(build(:user_company, :owner).role).to eq("superadmin")
      expect(build(:user_company, :owner).superadmin?).to eq(true)
      expect(build(:user_company, :owner).owner?).to eq(true)
    end

    it "should have valid factory with :pending_company trait" do
      expect(build(:user_company, :pending_company)).to be_valid
      expect(build(:user_company, :pending_company).company.status).to eq("pending")
    end

    it "should have valid factory with :confirmed_company trait" do
      expect(build(:user_company, :confirmed_company)).to be_valid
      expect(build(:user_company, :confirmed_company).company.status).to eq("confirmed")
    end

    it "should have valid factory with :tutor_user trait" do
      expect(build(:user_company, :tutor_user)).to be_valid
      expect(build(:user_company, :tutor_user).user.role).to eq("tutor")
    end

    it "should have valid factory with :voluntary_user trait" do
      expect(build(:user_company, :voluntary_user)).to be_valid
      expect(build(:user_company, :voluntary_user).user.role).to eq("voluntary")
    end
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:company) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_values({pending: 0, confirmed: 1}) }
    it { should define_enum_for(:role).with_values({member: 0, intervenant: 1, referent: 2, admin: 3, superadmin: 4}) }
  end

  describe "validations" do
    subject { build(:user_company) }

    it { should validate_presence_of(:status) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:company_id) }
    # it "should not being valid if user is teacher" do
    #   subject.user = create(:user, :teacher)
    #   expect(subject).not_to be_valid
    #   expect(subject.errors.messages[:user]).to include("Un enseignant ne peut pas être associé à une association")
    # end
    it "should not being valid if company have two superadmin" do
      subject.role = :superadmin
      create(:user_company, :confirmed, :superadmin, company: subject.company)
      expect(subject).not_to be_valid
      expect(subject.errors.messages[:role]).to include("Il ne peut y avoir qu'un seul superadmin par entreprise")
    end
  end
end
