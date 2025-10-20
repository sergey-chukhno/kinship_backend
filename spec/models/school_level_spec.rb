require "rails_helper"

RSpec.describe SchoolLevel, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "validations" do
    it { should validate_presence_of(:level) }
    it { should validate_presence_of(:name) }
  end

  describe "associations" do
    it { should belong_to(:school).optional }
    it { should have_many(:project_school_levels) }
    it { should have_many(:projects).through(:project_school_levels) }
    
    # Teacher assignment associations (Change #8)
    it { should have_many(:teacher_school_levels).dependent(:destroy) }
    it { should have_many(:teachers).through(:teacher_school_levels).source(:user) }
    it { should have_many(:students).through(:user_school_levels).source(:user) }
  end

  describe "#level_name" do
    it "should return a formatted level name" do
      school_level = build(:school_level, level: "cap", name: "Paquerette")
      expect(school_level.level_name).to eq("CAP")
    end
  end

  describe "#full_name" do
    it "should return a formatted full name" do
      school = create(:school, name: "Ecole du test", city: "Paris", zip_code: "75000", school_type: "lycee")
      school_level = build(:school_level, level: "cap", name: "Paquerette", school: school)
      expect(school_level.full_name).to eq("CAP Paquerette - Ecole du test, Paris (75000)")
    end
  end
  
  # ========================================
  # TEACHER ASSIGNMENT SPECS (Change #8)
  # ========================================
  
  describe "independent class validations" do
    describe "must_have_school_or_creator" do
      it "allows school-owned class without creator" do
        school = create(:school, school_type: :college)
        school_level = build(:school_level, school: school)
        
        expect(school_level).to be_valid
      end
      
      it "allows independent class with creator" do
        school_level = create(:school_level, :independent)
        
        expect(school_level).to be_valid
        expect(school_level.school).to be_nil
        expect(school_level.creator).to be_present
      end
      
      it "rejects independent class without creator on update" do
        # Create with school, then try to remove school without adding creator
        school_level = create(:school_level)
        school_level.school = nil
        
        expect(school_level).not_to be_valid
        expect(school_level.errors[:base]).to include("La classe doit appartenir à une école ou avoir un enseignant créateur")
      end
    end
  end
  
  describe "scopes" do
    let!(:independent_class) { create(:school_level, :independent) }
    let!(:school_class) { create(:school_level) }
    
    describe ".independent" do
      it "returns only classes without school" do
        expect(SchoolLevel.independent).to contain_exactly(independent_class)
      end
    end
    
    describe ".school_owned" do
      it "returns only classes with school" do
        expect(SchoolLevel.school_owned).to contain_exactly(school_class)
      end
    end
    
    describe ".for_teacher" do
      let(:teacher) { create(:user, :teacher, :confirmed) }
      let(:other_teacher) { create(:user, :teacher, :confirmed) }
      let!(:teacher_class) { create(:school_level, :independent) }
      
      before do
        teacher_class.teacher_school_levels.first.update!(user: teacher)
      end
      
      it "returns classes assigned to specific teacher" do
        expect(SchoolLevel.for_teacher(teacher)).to contain_exactly(teacher_class)
      end
      
      it "does not return classes for other teachers" do
        expect(SchoolLevel.for_teacher(other_teacher)).to be_empty
      end
    end
  end
  
  describe "status methods" do
    let(:independent_class) { create(:school_level, :independent) }
    let(:school_class) { create(:school_level) }
    
    describe "#independent?" do
      it "returns true for classes without school" do
        expect(independent_class.independent?).to be true
      end
      
      it "returns false for classes with school" do
        expect(school_class.independent?).to be false
      end
    end
    
    describe "#school_owned?" do
      it "returns false for independent classes" do
        expect(independent_class.school_owned?).to be false
      end
      
      it "returns true for school classes" do
        expect(school_class.school_owned?).to be true
      end
    end
  end
  
  describe "creator tracking" do
    let(:teacher) { create(:user, :teacher, :confirmed) }
    let(:school_level) { create(:school_level, :independent) }
    
    before do
      school_level.teacher_school_levels.first.update!(user: teacher, is_creator: true)
    end
    
    describe "#creator" do
      it "returns the teacher who created the class" do
        expect(school_level.creator).to eq(teacher)
      end
      
      it "returns nil if no creator" do
        school_class = create(:school_level)
        expect(school_class.creator).to be_nil
      end
    end
    
    describe "#created_by?" do
      it "returns true for creator" do
        expect(school_level.created_by?(teacher)).to be true
      end
      
      it "returns false for non-creator" do
        other_teacher = create(:user, :teacher, :confirmed)
        expect(school_level.created_by?(other_teacher)).to be false
      end
    end
  end
  
  describe "teacher management" do
    let(:teacher) { create(:user, :teacher, :confirmed) }
    let(:school_level) { create(:school_level) }
    
    describe "#assign_teacher" do
      it "assigns teacher to class" do
        expect {
          school_level.assign_teacher(teacher, is_creator: false)
        }.to change { school_level.teachers.count }.by(1)
        
        expect(school_level.teachers).to include(teacher)
      end
      
      it "marks teacher as creator when specified" do
        school_level.assign_teacher(teacher, is_creator: true)
        
        assignment = school_level.teacher_school_levels.find_by(user: teacher)
        expect(assignment.is_creator).to be true
      end
    end
    
    describe "#remove_teacher" do
      before do
        school_level.assign_teacher(teacher)
      end
      
      it "removes teacher from class" do
        expect {
          school_level.remove_teacher(teacher)
        }.to change { school_level.teachers.count }.by(-1)
        
        expect(school_level.teachers).not_to include(teacher)
      end
    end
    
    describe "#teacher_assigned?" do
      before do
        school_level.assign_teacher(teacher)
      end
      
      it "returns true if teacher is assigned" do
        expect(school_level.teacher_assigned?(teacher)).to be true
      end
      
      it "returns false if teacher is not assigned" do
        other_teacher = create(:user, :teacher, :confirmed)
        expect(school_level.teacher_assigned?(other_teacher)).to be false
      end
    end
  end
  
  describe "#transfer_to_school" do
    let(:teacher) { create(:user, :teacher, :confirmed) }
    let(:school) { create(:school, school_type: :college) }
    let(:independent_class) do
      # Create independent class manually to control the teacher
      school_level = SchoolLevel.create!(name: "3ème A", level: :troisieme, school: nil)
      school_level.assign_teacher(teacher, is_creator: true)
      school_level
    end
    
    context "when teacher is member of target school" do
      before do
        user_school = create(:user_school, user: teacher, school: school)
        user_school.update!(status: :confirmed)  # Manually confirm after create callback
      end
      
      it "transfers class to school" do
        expect(independent_class.transfer_to_school(school, transferred_by: teacher)).to be true
        
        expect(independent_class.reload.school).to eq(school)
        expect(independent_class.independent?).to be false
      end
      
      it "keeps teacher assignment" do
        independent_class.transfer_to_school(school, transferred_by: teacher)
        
        expect(independent_class.reload.teachers).to include(teacher)
      end
    end
    
    context "when teacher is not member of target school" do
      it "fails to transfer" do
        expect(independent_class.transfer_to_school(school, transferred_by: teacher)).to be false
        
        expect(independent_class.reload.school).to be_nil
      end
    end
    
    context "when class already belongs to a school" do
      let(:school_class) { create(:school_level, school: school) }
      
      it "fails to transfer" do
        other_school = create(:school, school_type: :lycee)
        expect(school_class.transfer_to_school(other_school, transferred_by: teacher)).to be false
      end
    end
  end
end
