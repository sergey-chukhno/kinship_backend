require "rails_helper"

RSpec.describe ProjectMember, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:project) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_values({pending: 0, confirmed: 1}) }
    it { should define_enum_for(:role).with_values({member: 0, admin: 1, co_owner: 2}) }
  end

  describe "validations" do
    subject { build(:project_member) }
    
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:role) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:project_id) }
  end

  describe "callbacks" do
    describe "#set_co_owner_if_project_owner" do
      let(:project) { create(:project) }
      let(:owner) { project.owner }

      it "automatically sets project owner as co_owner" do
        member = create(:project_member, user: owner, project: project, role: :member)
        expect(member.reload.role).to eq("co_owner")
      end

      it "does not change role for non-owners" do
        user = create(:user, :confirmed)
        member = create(:project_member, user: user, project: project, role: :member)
        expect(member.reload.role).to eq("member")
      end
    end
  end

  describe "permission methods" do
    let(:project) { create(:project) }
    
    context "co_owner" do
      let(:member) { create(:project_member, :co_owner, project: project) }
      
      it { expect(member.can_edit_project?).to be true }
      it { expect(member.can_manage_members?).to be true }
      it { expect(member.can_create_teams?).to be true }
      it { expect(member.can_close_project?).to be true }
    end

    context "admin" do
      let(:member) { create(:project_member, :admin, project: project) }
      
      it { expect(member.can_edit_project?).to be true }
      it { expect(member.can_manage_members?).to be true }
      it { expect(member.can_create_teams?).to be true }
      it { expect(member.can_close_project?).to be false }
    end

    context "member" do
      let(:member) { create(:project_member, :member, :confirmed, project: project) }
      
      it { expect(member.can_edit_project?).to be false }
      it { expect(member.can_manage_members?).to be false }
      it { expect(member.can_create_teams?).to be false }
      it { expect(member.can_close_project?).to be false }
    end
  end
end
