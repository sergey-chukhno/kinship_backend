require 'rails_helper'

RSpec.describe PartnershipMember, type: :model do
  describe "associations" do
    it { should belong_to(:partnership) }
    it { should belong_to(:participant) }
  end
  
  describe "enums" do
    it { should define_enum_for(:member_status).with_values({pending: 0, confirmed: 1, declined: 2}) }
    it { should define_enum_for(:role_in_partnership).with_values({partner: 0, sponsor: 1, beneficiary: 2}) }
  end
  
  describe "validations" do
    subject { build(:partnership_member) }
    
    it { should validate_presence_of(:member_status) }
    it { should validate_presence_of(:role_in_partnership) }
    it { should validate_uniqueness_of(:participant_id).scoped_to([:participant_type, :partnership_id]) }
  end
  
  describe "callbacks" do
    describe "before_create :set_joined_at" do
      it "sets joined_at timestamp" do
        member = build(:partnership_member, joined_at: nil)
        member.save
        expect(member.joined_at).to be_present
      end
    end
    
    describe "after_update :check_partnership_full_confirmation" do
      let(:partnership) { create(:partnership, :with_two_companies) }
      
      it "auto-confirms partnership when all members confirmed" do
        # Confirm all members
        partnership.partnership_members.each(&:confirm!)
        
        expect(partnership.reload.status).to eq("confirmed")
        expect(partnership.confirmed_at).to be_present
      end
    end
  end
  
  describe "#confirm!" do
    let(:member) { create(:partnership_member) }
    
    it "confirms the member" do
      member.confirm!
      expect(member.reload.member_status).to eq("confirmed")
      expect(member.confirmed_at).to be_present
    end
  end
  
  describe "#decline!" do
    let(:member) { create(:partnership_member) }
    
    it "declines the member" do
      member.decline!
      expect(member.reload.member_status).to eq("declined")
    end
    
    it "rejects the partnership if pending" do
      expect(member.partnership.status).to eq("pending")
      member.decline!
      expect(member.partnership.reload.status).to eq("rejected")
    end
  end
  
  describe "scopes" do
    let!(:confirmed_member) { create(:partnership_member, :confirmed) }
    let!(:pending_member) { create(:partnership_member) }
    let!(:declined_member) { create(:partnership_member, :declined) }
    
    describe ".confirmed" do
      it "returns only confirmed members" do
        expect(PartnershipMember.confirmed).to include(confirmed_member)
        expect(PartnershipMember.confirmed).not_to include(pending_member)
      end
    end
    
    describe ".pending" do
      it "returns only pending members" do
        expect(PartnershipMember.pending).to include(pending_member)
        expect(PartnershipMember.pending).not_to include(confirmed_member)
      end
    end
  end
end
