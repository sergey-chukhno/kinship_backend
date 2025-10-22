require "rails_helper"

RSpec.describe UserSchool, type: :model do
  it { should have_a_valid_factory }

  describe "associations" do
    subject { build(:user_school) }

    it { should belong_to(:school) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    subject { build(:user_school) }

    it { should validate_presence_of(:status) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:school_id) }
    it "should not being able to have more than one superadmin by school" do
      school = create(:school)
      create(:user_school, school: school, role: :superadmin)
      user_school2 = build(:user_school, school: school, role: :superadmin)
      expect(user_school2).to_not be_valid
      expect(user_school2.errors.messages[:role]).to include("Il ne peut y avoir qu'un seul superadmin par établissement")
    end
  end

  describe "callbacks" do
    context "after_create" do
      context "#set_status" do
        it "sets status to confirmed if user is not a teacher" do
          user_school_voluntaryt = create(:user_school, user: create(:user, :voluntary))
          expect(user_school_voluntaryt.status).to eq("confirmed")

          user_school_tutor = create(:user_school, user: create(:user, :tutor))
          expect(user_school_tutor.status).to eq("confirmed")
        end

        it "sets status to confirmed if school has no owner unless user is teacher" do
          user_school_teacher = create(:user_school, user: create(:user, :teacher, email: "example@ac-nantes.fr"))
          expect(user_school_teacher.status).to eq("pending")

          user_school_tutor = create(:user_school, user: create(:user, :tutor))
          expect(user_school_tutor.status).to eq("confirmed")

          user_school_voluntary = create(:user_school, user: create(:user, :voluntary))
          expect(user_school_voluntary.status).to eq("confirmed")
        end

        it "sets status to pending if user is a teacher and school has a superadmin" do
          school = create(:school)
          create(:user_school, user: create(:user, :tutor), school: school, role: :superadmin)

          user_school_teacher = create(:user_school, user: create(:user, :teacher, email: "example@ac-nantes.fr"), school: school)
          expect(user_school_teacher.status).to eq("pending")

          user_school_voluntary = create(:user_school, user: create(:user, :voluntary), school: school)
          expect(user_school_voluntary.status).to eq("confirmed")

          user_school_tutor = create(:user_school, user: create(:user, :tutor), school: school)
          expect(user_school_tutor.status).to eq("confirmed")
        end
      end
    end
    
    # Teacher-class unassignment callback (Change #8)
    context "after_destroy" do
      describe "#unassign_teacher_from_school_classes" do
        let(:school) { create(:school, school_type: :college) }
        let(:teacher) { create(:user, :teacher, :confirmed) }
        let!(:user_school) { create(:user_school, user: teacher, school: school, status: :confirmed) }
        
        context "teacher leaves school with school-owned classes" do
          let!(:created_and_transferred) { create(:school_level, name: "6ème A", level: :sixieme, school: school) }
          let!(:school_assigned) { create(:school_level, name: "5ème B", level: :cinquieme, school: school) }
          
          before do
            created_and_transferred.assign_teacher(teacher, is_creator: true)
            school_assigned.assign_teacher(teacher, is_creator: false)
          end
          
          it "removes teacher from ALL school-owned classes" do
            expect {
              user_school.destroy
            }.to change { teacher.assigned_classes.count }.from(2).to(0)
          end
          
          it "removes both created and assigned classes" do
            user_school.destroy
            
            expect(teacher.reload.assigned_classes).to be_empty
            expect(created_and_transferred.reload.teachers).not_to include(teacher)
            expect(school_assigned.reload.teachers).not_to include(teacher)
          end
        end
        
        context "teacher leaves school with independent classes" do
          let!(:independent_class) { create(:school_level, :independent) }
          
          before do
            independent_class.teacher_school_levels.first.update!(user: teacher, is_creator: true)
          end
          
          it "keeps independent classes" do
            expect {
              user_school.destroy
            }.not_to change { teacher.assigned_classes.count }
            
            expect(teacher.reload.assigned_classes).to include(independent_class)
          end
        end
        
        context "mixed scenario: independent + school classes" do
          let!(:independent_class) { create(:school_level, :independent) }
          let!(:school_class) { create(:school_level, name: "4ème C", level: :quatrieme, school: school) }
          
          before do
            independent_class.teacher_school_levels.first.update!(user: teacher, is_creator: true)
            school_class.assign_teacher(teacher, is_creator: false)
          end
          
          it "removes only school classes, keeps independent" do
            expect {
              user_school.destroy
            }.to change { teacher.assigned_classes.count }.from(2).to(1)
            
            expect(teacher.reload.assigned_classes).to contain_exactly(independent_class)
            expect(teacher.assigned_classes).not_to include(school_class)
          end
        end
        
        context "when user is not a teacher" do
          let(:student) { create(:user, :tutor, :confirmed) }
          let(:user_school_student) { create(:user_school, user: student, school: school, status: :confirmed) }
          
          it "does not raise error" do
            expect {
              user_school_student.destroy
            }.not_to raise_error
          end
        end
      end
    end
  end
end
