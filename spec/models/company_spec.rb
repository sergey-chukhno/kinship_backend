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

  # ========================================
  # BRANCH SYSTEM SPECS (Change #4)
  # ========================================
  
  describe "branch associations" do
    it { should belong_to(:parent_company).class_name('Company').optional }
    it { should have_many(:branch_companies).class_name('Company').with_foreign_key(:parent_company_id).dependent(:nullify) }
    it { should have_many(:sent_branch_requests_as_parent).class_name('BranchRequest').dependent(:destroy) }
    it { should have_many(:received_branch_requests_as_child).class_name('BranchRequest').dependent(:destroy) }
  end
  
  describe "branch validations" do
    describe "cannot_be_own_branch" do
      it "prevents company from being its own branch" do
        company = create(:company)
        company.parent_company_id = company.id
        
        expect(company).not_to be_valid
        expect(company.errors[:parent_company]).to include("ne peut pas être elle-même")
      end
    end
    
    describe "cannot_have_circular_branch_reference" do
      it "prevents circular branch references" do
        parent = create(:company)
        child = create(:company, parent_company: parent)
        
        parent.parent_company_id = child.id
        
        expect(parent).not_to be_valid
        expect(parent.errors[:parent_company]).to include("créerait une référence circulaire")
      end
    end
    
    describe "branch_cannot_have_branches" do
      it "prevents branches from having sub-branches (1-level depth)" do
        parent = create(:company)
        branch = create(:company, parent_company: parent)
        
        # Try to create a sub-branch
        sub_branch = build(:company, parent_company: branch)
        
        expect(sub_branch).not_to be_valid
        expect(sub_branch.errors[:base]).to include("Une filiale ne peut pas avoir de sous-filiales (profondeur max: 1 niveau)")
      end
    end
  end
  
  describe "branch scopes" do
    let!(:main_company1) { create(:company) }
    let!(:main_company2) { create(:company) }
    let!(:branch1) { create(:company, parent_company: main_company1) }
    let!(:branch2) { create(:company, parent_company: main_company1) }
    
    describe ".main_companies" do
      it "returns only main companies (no parent)" do
        expect(Company.main_companies).to contain_exactly(main_company1, main_company2)
      end
    end
    
    describe ".branch_companies" do
      it "returns only branch companies (with parent)" do
        expect(Company.branch_companies).to contain_exactly(branch1, branch2)
      end
    end
  end
  
  describe "branch status methods" do
    let(:main_company) { create(:company) }
    let(:branch_company) { create(:company, parent_company: main_company) }
    
    describe "#main_company?" do
      it "returns true for main company" do
        expect(main_company.main_company?).to be true
      end
      
      it "returns false for branch" do
        expect(branch_company.main_company?).to be false
      end
    end
    
    describe "#branch?" do
      it "returns false for main company" do
        expect(main_company.branch?).to be false
      end
      
      it "returns true for branch" do
        expect(branch_company.branch?).to be true
      end
    end
  end
  
  describe "branch management methods" do
    let(:main_company) { create(:company, :confirmed) }
    let!(:branch1) { create(:company, :confirmed, parent_company: main_company) }
    let!(:branch2) { create(:company, :confirmed, parent_company: main_company) }
    
    describe "#all_branch_companies" do
      it "returns all branches" do
        expect(main_company.all_branch_companies).to contain_exactly(branch1, branch2)
      end
    end
    
    describe "#all_members_including_branches" do
      let(:main_member) { create(:user, :confirmed) }
      let(:branch_member) { create(:user, :confirmed) }
      
      before do
        create(:user_company, user: main_member, company: main_company, status: :confirmed)
        create(:user_company, user: branch_member, company: branch1, status: :confirmed)
      end
      
      it "returns members from main company and all branches" do
        expect(main_company.all_members_including_branches).to contain_exactly(main_member, branch_member)
      end
      
      it "branch only returns its own members" do
        expect(branch1.all_members_including_branches).to contain_exactly(branch_member)
      end
    end
    
    describe "#members_visible_to_branch?" do
      context "when share_members_with_branches is true" do
        before { main_company.update(share_members_with_branches: true) }
        
        it "returns true for own branch" do
          expect(main_company.members_visible_to_branch?(branch1)).to be true
        end
      end
      
      context "when share_members_with_branches is false" do
        before { main_company.update(share_members_with_branches: false) }
        
        it "returns false for own branch" do
          expect(main_company.members_visible_to_branch?(branch1)).to be false
        end
      end
    end
    
    describe "#projects_visible_to_branch?" do
      it "parent can always see branch projects" do
        expect(main_company.projects_visible_to_branch?(branch1)).to be true
      end
    end
  end
  
  describe "branch request methods" do
    let(:company1) { create(:company) }
    let(:company2) { create(:company) }
    
    describe "#request_to_become_branch_of" do
      it "creates a branch request with company1 as child" do
        request = company1.request_to_become_branch_of(company2)
        
        expect(request).to be_persisted
        expect(request.parent).to eq(company2)
        expect(request.child).to eq(company1)
        expect(request.initiator).to eq(company1)
        expect(request.status).to eq('pending')
      end
    end
    
    describe "#invite_as_branch" do
      it "creates a branch request with company2 as child" do
        request = company1.invite_as_branch(company2)
        
        expect(request).to be_persisted
        expect(request.parent).to eq(company1)
        expect(request.child).to eq(company2)
        expect(request.initiator).to eq(company1)
        expect(request.status).to eq('pending')
      end
    end
    
    describe "#detach_branch" do
      let(:branch) { create(:company, parent_company: company1) }
      
      it "removes parent-child relationship" do
        expect(company1.detach_branch(branch)).to be true
        expect(branch.reload.parent_company).to be_nil
      end
      
      it "returns false if not the parent" do
        expect(company2.detach_branch(branch)).to be false
      end
    end
    
    describe "#detach_from_parent" do
      let(:branch) { create(:company, parent_company: company1) }
      
      it "removes parent-child relationship" do
        expect(branch.detach_from_parent).to be true
        expect(branch.reload.parent_company).to be_nil
      end
    end
  end
end
