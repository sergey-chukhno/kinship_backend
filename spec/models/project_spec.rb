require "rails_helper"

RSpec.describe Project, type: :model do
  # do me the test for project model
  it { is_expected.to have_a_valid_factory }

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should validate_presence_of(:owner) }
  end

  describe "associations" do
    it { should belong_to(:owner) }
    it { should have_many(:project_school_levels) }
    it { should have_many(:school_levels).through(:project_school_levels) }
    it { should have_many(:project_tags) }
    it { should have_many(:tags).through(:project_tags) }
    it { should have_many(:project_skills) }
    it { should have_many(:skills).through(:project_skills) }
    it { should have_many(:keywords) }
    it { should have_many(:links) }
    it { should have_many(:teams) }
    it { should have_many(:project_members) }
    it { should have_many(:co_owner_members) }
    it { should have_many(:co_owners).through(:co_owner_members) }
    it { should have_many(:admin_members) }
    it { should have_many(:admins).through(:admin_members) }
    it { should have_many_attached(:pictures) }
    it { should have_one_attached(:main_picture) }
    it { should have_many_attached(:documents) }
    it { should accept_nested_attributes_for(:project_tags).allow_destroy(true) }
    it { should accept_nested_attributes_for(:links).allow_destroy(true) }
    it { should accept_nested_attributes_for(:project_skills).allow_destroy(true) }
    it { should accept_nested_attributes_for(:teams).allow_destroy(true) }
  end

  describe "#start_date_before_end_date" do
    it "should not be valid if start_date is after end_date" do
      project = build(:project, start_date: DateTime.parse("2023-07-10 10:02:14"), end_date: DateTime.parse("2023-07-07 10:02:14"))
      expect(project).not_to be_valid
    end

    it "should be valid if start_date is before end_date" do
      project = build(:project, start_date: DateTime.parse("2023-07-07 10:02:14"), end_date: DateTime.parse("2023-07-10 10:02:14"))
      expect(project).to be_valid
    end
  end

  describe "#formatted_date_start" do
    it "should return a formatted date" do
      project = build(:project, start_date: DateTime.parse("2023-07-07 10:02:14"))
      expect(project.formatted_date_start).to eq("07/07/2023 10:02")
    end
  end

  describe "#formatted_date_end" do
    it "should return a formatted date" do
      project = build(:project, end_date: DateTime.parse("2023-07-07 10:02:14"))
      expect(project.formatted_date_end).to eq("07/07/2023 10:02")
    end
  end

  describe "co-owner functionality" do
    let(:school) { create(:school, :confirmed, school_type: :college) }
    let(:company) { create(:company, :confirmed) }
    let(:school_level) { create(:school_level, school: school, level: :sixieme) }
    let(:project) do
      create(:project, 
             project_school_levels_attributes: [{school_level_id: school_level.id}],
             project_companies_attributes: [{company_id: company.id}])
    end
    let(:org_admin_user) { create(:user, :voluntary, confirmed_at: Time.current) }

    before do
      create(:user_company, user: org_admin_user, company: company, role: :admin, status: :confirmed)
    end

    describe "#add_co_owner" do
      context "when user is eligible (org admin)" do
        it "adds user as co-owner" do
          result = project.add_co_owner(org_admin_user, added_by: project.owner)
          expect(result[:success]).to be true
          expect(project.co_owners).to include(org_admin_user)
        end
      end

      context "when user is not eligible" do
        let(:random_user) { create(:user, :voluntary, confirmed_at: Time.current) }

        it "returns error" do
          result = project.add_co_owner(random_user, added_by: project.owner)
          expect(result[:success]).to be false
          expect(result[:error]).to include("not eligible")
        end
      end

      context "when added_by is not authorized" do
        let(:random_user) { create(:user, :voluntary, confirmed_at: Time.current) }

        it "returns error" do
          result = project.add_co_owner(org_admin_user, added_by: random_user)
          expect(result[:success]).to be false
          expect(result[:error]).to eq("Unauthorized")
        end
      end
    end

    describe "#remove_co_owner" do
      before do
        project.add_co_owner(org_admin_user, added_by: project.owner)
      end

      it "demotes co-owner to member" do
        result = project.remove_co_owner(org_admin_user, removed_by: project.owner)
        expect(result[:success]).to be true
        expect(project.co_owners).not_to include(org_admin_user)
      end

      it "cannot remove primary owner" do
        result = project.remove_co_owner(project.owner, removed_by: project.owner)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Cannot remove primary owner")
      end
    end

    describe "#user_eligible_for_co_ownership?" do
      it "returns true for company admin" do
        expect(project.user_eligible_for_co_ownership?(org_admin_user)).to be true
      end

      it "returns false for regular member" do
        regular_user = create(:user, :voluntary, confirmed_at: Time.current)
        create(:user_company, user: regular_user, company: company, role: :member, status: :confirmed)
        expect(project.user_eligible_for_co_ownership?(regular_user)).to be false
      end
    end
  end

  describe "partner project functionality" do
    let(:school) { create(:school, :confirmed, school_type: :college) }
    let(:company_a) { create(:company, :confirmed) }
    let(:company_b) { create(:company, :confirmed) }
    let!(:partnership) do
      p = create(:partnership, initiator: company_a, status: :confirmed, confirmed_at: Time.current)
      create(:partnership_member, partnership: p, participant: company_a, member_status: :confirmed, role_in_partnership: :partner)
      create(:partnership_member, partnership: p, participant: company_b, member_status: :confirmed, role_in_partnership: :partner)
      create(:partnership_member, partnership: p, participant: school, member_status: :confirmed, role_in_partnership: :partner)
      p.reload  # Reload to ensure associations are fresh
    end
    let(:school_level) { create(:school_level, school: school, level: :sixieme) }
    let(:project) do
      create(:project,
             project_school_levels_attributes: [{school_level_id: school_level.id}],
             project_companies_attributes: [{company_id: company_a.id}])
    end

    describe "#partner_project?" do
      it "returns false for regular project" do
        expect(project.partner_project?).to be false
      end

      it "returns true when assigned to partnership" do
        project.update(partnership: partnership)
        expect(project.partner_project?).to be true
      end
    end

    describe "#assign_to_partnership" do
      context "when partnership includes project orgs" do
        it "assigns project to partnership" do
          result = project.assign_to_partnership(partnership, assigned_by: project.owner)
          expect(result[:success]).to be true
          expect(project.reload.partnership).to eq(partnership)
        end
      end

      context "when partnership doesn't include all project orgs" do
        let(:other_partnership) { create(:partnership, :with_two_companies, :confirmed) }

        it "returns error" do
          result = project.assign_to_partnership(other_partnership, assigned_by: project.owner)
          expect(result[:success]).to be false
          expect(result[:error]).to include("must include all project organizations")
        end
      end

      context "when user not authorized" do
        let(:random_user) { create(:user, :voluntary, confirmed_at: Time.current) }

        it "returns error" do
          result = project.assign_to_partnership(partnership, assigned_by: random_user)
          expect(result[:success]).to be false
          expect(result[:error]).to eq("Unauthorized")
        end
      end
    end

    describe "#eligible_for_partnership?" do
      it "returns true when partnership includes project orgs" do
        expect(project.eligible_for_partnership?(partnership)).to be true
      end

      it "returns false when partnership missing project orgs" do
        other_partnership = create(:partnership, :with_two_companies, :confirmed)
        expect(project.eligible_for_partnership?(other_partnership)).to be false
      end
    end

    describe "#user_eligible_for_co_ownership? with partnership" do
      before do
        project.update(partnership: partnership)
      end

      it "includes users from partner organizations" do
        company_b_admin = create(:user, :voluntary, confirmed_at: Time.current)
        create(:user_company, user: company_b_admin, company: company_b, role: :admin, status: :confirmed)
        
        expect(project.user_eligible_for_co_ownership?(company_b_admin)).to be true
      end
    end

    describe "#all_partner_organizations" do
      before do
        project.update(partnership: partnership)
      end

      it "returns all partnership participants" do
        orgs = project.all_partner_organizations
        expect(orgs).to include(company_a, company_b, school)
        expect(orgs.length).to eq(3)
      end
    end
  end
end
