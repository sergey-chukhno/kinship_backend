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
  end
end
