require "rails_helper"

RSpec.describe UserBadge, type: :model do
  describe "Associations" do
    it { should belong_to(:sender) }
    it { should belong_to(:receiver) }
    it { should belong_to(:badge) }
    it { should belong_to(:project).optional }
    it { should belong_to(:organization) }
  end

  describe "Attachments" do
    it { should have_many_attached(:documents) }
  end

  describe "Enums" do
    it { should define_enum_for(:status).with_values(%i[pending approved rejected]) }
  end

  describe "Validations" do
    subject { build(:user_badge) }

    it { should validate_presence_of(:project_title) }
    it { should validate_presence_of(:project_description) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:organization_type).in_array(%w[School Company]) }
    it "is expected to have documents if badge is above level 1" do
      expect(build(:user_badge)).to be_valid
      expect(build(:user_badge, badge: build(:badge, :level_2))).to_not be_valid
    end
  end

  describe "Factories" do
    it "should have valid factory" do
      expect(build(:user_badge)).to be_valid
    end

    it "should have valid factory with trait pending" do
      expect(build(:user_badge, :pending)).to be_valid
    end

    it "should set status to pendind if trait pending" do
      expect(build(:user_badge, :pending).status).to eq("pending")
    end

    it "should have valid factory with trait approved" do
      expect(build(:user_badge, :approved)).to be_valid
    end

    it "should set status to approved if trait approved" do
      expect(build(:user_badge, :approved).status).to eq("approved")
    end

    it "should have valid factory with trait rejected" do
      expect(build(:user_badge, :rejected)).to be_valid
    end

    it "should set status to rejected if trait rejected" do
      expect(build(:user_badge, :rejected).status).to eq("rejected")
    end
  end
end
