require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) { User.new }

  it { is_expected.to have_a_valid_factory }

  describe "associations" do
    it { should have_many(:team_members) }
    it { should have_many(:teams).through(:team_members) }
    it { should have_many(:projects) }
    it { should have_many(:user_skills) }
    it { should have_many(:skills).through(:user_skills) }
    it { should have_many(:user_sub_skills) }
    it { should have_many(:sub_skills).through(:user_sub_skills) }
    it { should have_many(:user_schools) }
    it { should have_many(:schools).through(:user_schools) }
    it { should have_many(:user_school_levels) }
    it { should have_many(:school_levels).through(:user_school_levels) }
    it { should have_one_attached(:avatar) }
    it { should have_one(:availability) }
  end

  describe "validations" do
    it { should define_enum_for(:role).with_values([:teacher, :tutor, :voluntary, :children]) }
    it { should validate_presence_of(:role) }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should accept_nested_attributes_for(:user_skills).allow_destroy(true) }
    it { should accept_nested_attributes_for(:user_sub_skills).allow_destroy(true) }
    it { should accept_nested_attributes_for(:availability).allow_destroy(true) }
    it { should accept_nested_attributes_for(:user_schools).allow_destroy(true) }
    it { should accept_nested_attributes_for(:user_school_levels).allow_destroy(true) }

    context "When privacy policy isn't accepted" do
      it "should not be valid" do
        user = build(:user, accept_privacy_policy: false)
        expect(user).not_to be_valid
        expect(user.errors[:accept_privacy_policy]).to include("doit être accepté")
      end
    end

    context "when user has parent_id nil" do
      it "validates presence of email if parent_id is nil" do
        user = build(:user, email: nil, parent: nil)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("doit être rempli(e)")

        user.email = "john@example.com"
        expect(user).to be_valid
      end

      it "validates presence of password if parent_id is nil" do
        user = build(:user, password: nil, parent: nil)
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("doit être rempli(e)")

        user.password = "password"
        expect(user).to be_valid
      end
    end

    context "when user is a teacher" do
      it "should not be valid if user is a teacher and don't use academic email" do
        user = build(:user, role: "teacher", email: "jean@example.com")
        expect(user).not_to be_valid
      end

      it "should be valid if user is a teacher and use academic email" do
        user = build(:user, role: "teacher", email: "jean@ac-nantes.fr")
        expect(user).to be_valid
      end
    end

    context "when user is a voluntary" do
      it "should be valid if user is a voluntary and don't use academic email" do
        user = build(:user, role: "voluntary", email: "voluntary@example.com")
        expect(user).to be_valid
      end
    end
  end

  describe "when created as a voluntary" do
    let(:user) { create(:user, :voluntary) }
    it "should have the proper role" do
      expect(user.role).to eq("voluntary")
    end
  end

  describe "when created as a tutor" do
    let(:user) { create(:user, :tutor) }
    it "should have the proper role" do
      expect(user.role).to eq("tutor")
    end
  end
end
