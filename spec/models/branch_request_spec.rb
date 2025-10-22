require 'rails_helper'

RSpec.describe BranchRequest, type: :model do
  describe "factory" do
    it "has a valid factory" do
      expect(build(:branch_request)).to be_valid
    end
    
    it "has valid factory for schools" do
      expect(build(:branch_request, :for_schools)).to be_valid
    end
  end
  
  describe "associations" do
    it { should belong_to(:parent) }
    it { should belong_to(:child) }
    it { should belong_to(:initiator) }
  end
  
  describe "enums" do
    it { should define_enum_for(:status).with_values(pending: 0, confirmed: 1, rejected: 2) }
  end
  
  describe "validations" do
    let(:parent) { create(:company) }
    let(:child) { create(:company) }
    
    describe "uniqueness" do
      before { create(:branch_request, parent: parent, child: child, initiator: parent) }
      
      it "prevents duplicate requests for same parent-child pair" do
        duplicate = build(:branch_request, parent: parent, child: child, initiator: parent)
        
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:parent_id]).to be_present
      end
    end
    
    describe "parent_and_child_must_differ" do
      it "prevents company from requesting to be its own branch" do
        company = create(:company)
        request = build(:branch_request, parent: company, child: company, initiator: company)
        
        expect(request).not_to be_valid
        expect(request.errors[:base]).to include("L'organisation ne peut pas devenir sa propre filiale")
      end
    end
    
    describe "child_not_already_a_branch" do
      it "prevents child that already has a parent" do
        existing_parent = create(:company)
        child = create(:company, parent_company: existing_parent)
        new_parent = create(:company)
        
        request = build(:branch_request, parent: new_parent, child: child, initiator: new_parent)
        
        expect(request).not_to be_valid
        expect(request.errors[:child]).to include("est déjà une filiale d'une autre entreprise")
      end
    end
    
    describe "parent_is_not_a_branch" do
      it "prevents branches from becoming parents" do
        grandparent = create(:company)
        parent = create(:company, parent_company: grandparent)
        child = create(:company)
        
        request = build(:branch_request, parent: parent, child: child, initiator: parent)
        
        expect(request).not_to be_valid
        expect(request.errors[:parent]).to include("ne peut pas avoir de filiales car c'est déjà une filiale")
      end
    end
    
    describe "same_type_only" do
      it "prevents cross-type branching (Company-School)" do
        company = create(:company)
        school = create(:school)
        
        request = build(:branch_request, parent: company, child: school, initiator: company)
        
        expect(request).not_to be_valid
        expect(request.errors[:base]).to include("Le parent et l'enfant doivent être du même type (Company-Company ou School-School)")
      end
    end
  end
  
  describe "scopes" do
    let(:company1) { create(:company) }
    let(:company2) { create(:company) }
    let(:company3) { create(:company) }
    
    let!(:request1) { create(:branch_request, parent: company1, child: company2, initiator: company1) }
    let!(:request2) { create(:branch_request, parent: company3, child: company1, initiator: company3) }
    
    describe ".for_organization" do
      it "returns requests where organization is parent or child" do
        requests = BranchRequest.for_organization(company1)
        expect(requests).to contain_exactly(request1, request2)
      end
    end
  end
  
  describe "instance methods" do
    let(:parent) { create(:company) }
    let(:child) { create(:company) }
    
    describe "#confirm!" do
      let(:request) { create(:branch_request, parent: parent, child: child, initiator: parent) }
      
      it "updates status to confirmed" do
        request.confirm!
        
        expect(request.reload.status).to eq('confirmed')
        expect(request.confirmed_at).to be_present
      end
      
      it "applies branch relationship via callback" do
        request.confirm!
        
        expect(child.reload.parent_company).to eq(parent)
      end
    end
    
    describe "#reject!" do
      let(:request) { create(:branch_request, parent: parent, child: child, initiator: parent) }
      
      it "updates status to rejected" do
        request.reject!
        
        expect(request.reload.status).to eq('rejected')
      end
      
      it "does not apply branch relationship" do
        request.reject!
        
        expect(child.reload.parent_company).to be_nil
      end
    end
    
    describe "#recipient" do
      context "when initiated by parent" do
        let(:request) { create(:branch_request, parent: parent, child: child, initiator: parent) }
        
        it "returns child as recipient" do
          expect(request.recipient).to eq(child)
        end
      end
      
      context "when initiated by child" do
        let(:request) { create(:branch_request, parent: parent, child: child, initiator: child) }
        
        it "returns parent as recipient" do
          expect(request.recipient).to eq(parent)
        end
      end
    end
    
    describe "#initiated_by_parent?" do
      it "returns true when initiator is parent" do
        request = create(:branch_request, parent: parent, child: child, initiator: parent)
        expect(request.initiated_by_parent?).to be true
      end
      
      it "returns false when initiator is child" do
        request = create(:branch_request, parent: parent, child: child, initiator: child)
        expect(request.initiated_by_parent?).to be false
      end
    end
    
    describe "#initiated_by_child?" do
      it "returns true when initiator is child" do
        request = create(:branch_request, parent: parent, child: child, initiator: child)
        expect(request.initiated_by_child?).to be true
      end
      
      it "returns false when initiator is parent" do
        request = create(:branch_request, parent: parent, child: child, initiator: parent)
        expect(request.initiated_by_child?).to be false
      end
    end
  end
  
  describe "callbacks" do
    describe "apply_branch_relationship" do
      context "for companies" do
        let(:parent) { create(:company) }
        let(:child) { create(:company) }
        let(:request) { create(:branch_request, parent: parent, child: child, initiator: parent) }
        
        it "sets parent_company when confirmed" do
          expect {
            request.update!(status: :confirmed, confirmed_at: Time.current)
          }.to change { child.reload.parent_company }.from(nil).to(parent)
        end
        
        it "does not set parent_company when rejected" do
          expect {
            request.update!(status: :rejected)
          }.not_to change { child.reload.parent_company }
        end
      end
      
      context "for schools" do
        let(:parent) { create(:school) }
        let(:child) { create(:school) }
        let(:request) { create(:branch_request, parent: parent, child: child, initiator: parent) }
        
        it "sets parent_school when confirmed" do
          expect {
            request.update!(status: :confirmed, confirmed_at: Time.current)
          }.to change { child.reload.parent_school }.from(nil).to(parent)
        end
      end
    end
  end
end
