require 'rails_helper'

RSpec.describe TeacherSchoolLevel, type: :model do
  describe "factory" do
    it "has a valid factory" do
      expect(build(:teacher_school_level)).to be_valid
    end
    
    it "has valid :creator trait" do
      assignment = build(:teacher_school_level, :creator)
      expect(assignment).to be_valid
      expect(assignment.is_creator).to be true
    end
    
    it "has valid :assigned trait" do
      assignment = build(:teacher_school_level, :assigned)
      expect(assignment).to be_valid
      expect(assignment.is_creator).to be false
    end
  end
  
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:school_level) }
  end
  
  describe "validations" do
    let(:teacher) { create(:user, :teacher, :confirmed) }
    let(:school_level) { create(:school_level) }
    
    describe "uniqueness" do
      before do
        create(:teacher_school_level, user: teacher, school_level: school_level)
      end
      
      it "prevents duplicate assignments" do
        duplicate = build(:teacher_school_level, user: teacher, school_level: school_level)
        
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to be_present
      end
    end
    
    describe "user_must_be_teacher" do
      it "rejects non-teacher users" do
        student = create(:user, :confirmed, role: :tutor)
        assignment = build(:teacher_school_level, user: student, school_level: school_level)
        
        expect(assignment).not_to be_valid
        expect(assignment.errors[:user]).to include("doit être un enseignant")
      end
      
      it "accepts teacher users" do
        assignment = build(:teacher_school_level, user: teacher, school_level: school_level)
        
        expect(assignment).to be_valid
      end
    end
  end
  
  describe "scopes" do
    let(:school_level) { create(:school_level) }
    let!(:creator_assignment) { create(:teacher_school_level, :creator, school_level: school_level) }
    let!(:assigned_teacher) { create(:teacher_school_level, :assigned, school_level: school_level) }
    
    describe ".creators" do
      it "returns only creator assignments" do
        expect(TeacherSchoolLevel.creators).to contain_exactly(creator_assignment)
      end
    end
    
    describe ".assigned" do
      it "returns only non-creator assignments" do
        expect(TeacherSchoolLevel.assigned).to contain_exactly(assigned_teacher)
      end
    end
  end
  
  describe "callbacks" do
    describe "set_assigned_at" do
      it "sets assigned_at on creation if not provided" do
        assignment = create(:teacher_school_level, assigned_at: nil)
        
        expect(assignment.assigned_at).to be_present
        expect(assignment.assigned_at).to be_within(1.second).of(Time.current)
      end
      
      it "preserves assigned_at if provided" do
        custom_time = 1.week.ago
        assignment = create(:teacher_school_level, assigned_at: custom_time)
        
        expect(assignment.assigned_at).to be_within(1.second).of(custom_time)
      end
    end
  end
end
