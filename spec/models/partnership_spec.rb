require 'rails_helper'

RSpec.describe Partnership, type: :model do
  describe "associations" do
    it { should belong_to(:initiator) }
    it { should have_many(:partnership_members).dependent(:destroy) }
    it { should have_many(:companies).through(:partnership_members) }
    it { should have_many(:schools).through(:partnership_members) }
  end
  
  describe "enums" do
    it { should define_enum_for(:status).with_values({pending: 0, confirmed: 1, rejected: 2}) }
    it { should define_enum_for(:partnership_type).with_values({bilateral: 0, multilateral: 1}) }
  end
  
  describe "validations" do
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:partnership_type) }
    
    context "when multilateral" do
      subject { build(:partnership, partnership_type: :multilateral) }
      it { should validate_presence_of(:name) }
    end
  end
  
  describe "scopes" do
    let!(:active_partnership) { create(:partnership, :confirmed) }
    let!(:pending_partnership) { create(:partnership, :with_two_companies) }
    let!(:sponsorship) { create(:partnership, :with_sponsorship, :confirmed) }
    
    describe ".active" do
      it "returns only confirmed partnerships" do
        expect(Partnership.active).to include(active_partnership)
        expect(Partnership.active).not_to include(pending_partnership)
      end
    end
    
    describe ".with_sponsorship" do
      it "returns only partnerships with sponsorship" do
        expect(Partnership.with_sponsorship).to include(sponsorship)
        expect(Partnership.with_sponsorship).not_to include(active_partnership)
      end
    end
    
    describe ".sharing_members" do
      let!(:sharing) { create(:partnership, :sharing_members, :confirmed) }
      
      it "returns only partnerships sharing members" do
        expect(Partnership.sharing_members).to include(sharing)
        expect(Partnership.sharing_members).not_to include(active_partnership)
      end
    end
  end
  
  describe "#confirm!" do
    let(:partnership) { create(:partnership, :with_two_companies) }
    
    context "when all members are confirmed" do
      before do
        partnership.partnership_members.update_all(member_status: :confirmed, confirmed_at: Time.current)
      end
      
      it "confirms the partnership" do
        expect(partnership.confirm!).to be_truthy
        expect(partnership.reload.status).to eq("confirmed")
        expect(partnership.confirmed_at).to be_present
      end
    end
    
    context "when not all members are confirmed" do
      it "does not confirm the partnership" do
        expect(partnership.confirm!).to be_falsey
        expect(partnership.reload.status).to eq("pending")
      end
    end
  end
  
  describe "#includes?" do
    let(:company_a) { create(:company, :confirmed) }
    let(:company_b) { create(:company, :confirmed) }
    let(:partnership) do
      p = create(:partnership, initiator: company_a)
      create(:partnership_member, partnership: p, participant: company_a)
      create(:partnership_member, partnership: p, participant: company_b)
      p
    end
    
    it "returns true for participants" do
      expect(partnership.includes?(company_a)).to be true
      expect(partnership.includes?(company_b)).to be true
    end
    
    it "returns false for non-participants" do
      company_c = create(:company, :confirmed)
      expect(partnership.includes?(company_c)).to be false
    end
  end
  
  describe "#other_partners" do
    let(:company_a) { create(:company, :confirmed) }
    let(:company_b) { create(:company, :confirmed) }
    let(:partnership) do
      p = create(:partnership, initiator: company_a)
      create(:partnership_member, partnership: p, participant: company_b, member_status: :confirmed)
      p
    end
    
    it "returns other confirmed partners" do
      partners = partnership.other_partners(company_a)
      expect(partners).to include(company_b)
      expect(partners).not_to include(company_a)
    end
  end
  
  describe "#sponsors and #beneficiaries" do
    let(:partnership) { create(:partnership, :with_sponsorship, :confirmed) }
    
    it "correctly identifies sponsors" do
      expect(partnership.sponsors.size).to eq(1)
      expect(partnership.sponsors.first).to eq(partnership.initiator)
    end
    
    it "correctly identifies beneficiaries" do
      expect(partnership.beneficiaries.size).to eq(1)
      expect(partnership.beneficiaries.first).not_to eq(partnership.initiator)
    end
  end
end
