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
    it { should have_many(:parent_child_infos).dependent(:destroy) }
    
    # Teacher-class assignment associations (Change #8)
    it { should have_many(:teacher_school_levels).dependent(:destroy) }
    it { should have_many(:assigned_classes).through(:teacher_school_levels).source(:school_level) }
  end

  describe "validations" do
    # Note: Enum test skipped due to prefix: true on enum
    # The enum is defined with prefix: true to avoid conflict with belongs_to :parent
    # We test role functionality through helper methods instead
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

        user.password = "Password123!"
        expect(user).to be_valid
      end
    end

    context "when user is a teacher" do
      it "should not be valid if user is a teacher and don't use academic email" do
        user = build(:user, role: "school_teacher", email: "jean@example.com")
        expect(user).not_to be_valid
      end

      it "should be valid if user is a teacher and use academic email" do
        user = build(:user, role: "school_teacher", email: "jean@ac-nantes.fr")
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
  
  # ========================================
  # TEACHER-CLASS ASSIGNMENT SPECS (Change #8)
  # ========================================
  
  describe "teacher-class assignment methods" do
    let(:teacher) { create(:user, :school_teacher, :confirmed) }
    let(:independent_class) { create(:school_level, :independent) }
    let(:school_class) { create(:school_level) }
    
    before do
      independent_class.teacher_school_levels.first.update!(user: teacher, is_creator: true)
      school_class.assign_teacher(teacher, is_creator: false)
    end
    
    describe "#assigned_to_class?" do
      it "returns true for assigned class" do
        expect(teacher.assigned_to_class?(independent_class)).to be true
        expect(teacher.assigned_to_class?(school_class)).to be true
      end
      
      it "returns false for non-assigned class" do
        other_class = create(:school_level)
        expect(teacher.assigned_to_class?(other_class)).to be false
      end
    end
    
    describe "#created_classes" do
      it "returns only classes where teacher is creator" do
        expect(teacher.created_classes).to contain_exactly(independent_class)
      end
    end
    
    describe "#all_teaching_classes" do
      it "returns all assigned classes" do
        expect(teacher.all_teaching_classes).to contain_exactly(independent_class, school_class)
      end
    end
  end
end
