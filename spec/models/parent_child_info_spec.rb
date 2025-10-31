require "rails_helper"

RSpec.describe ParentChildInfo, type: :model do
  let(:parent_user) { create(:user, role: "parent") }
  let(:school) { create(:school) }
  let(:school_level) { create(:school_level, school: school) }

  describe "associations" do
    it { should belong_to(:parent_user).class_name("User") }
    it { should belong_to(:school).optional }
    it { should belong_to(:school_level).optional.with_foreign_key(:class_id) }
    it { should belong_to(:linked_user).class_name("User").optional }
  end

  describe "validations" do
    it { should validate_presence_of(:parent_user_id) }
  end

  describe "scopes" do
    let!(:linked_child) { create(:parent_child_info, parent_user: parent_user, linked_user: create(:user)) }
    let!(:unlinked_child) { create(:parent_child_info, parent_user: parent_user, linked_user: nil) }

    describe ".unlinked" do
      it "returns only unlinked children" do
        expect(ParentChildInfo.unlinked).to include(unlinked_child)
        expect(ParentChildInfo.unlinked).not_to include(linked_child)
      end
    end

    describe ".linked" do
      it "returns only linked children" do
        expect(ParentChildInfo.linked).to include(linked_child)
        expect(ParentChildInfo.linked).not_to include(unlinked_child)
      end
    end
  end

  describe "#full_name" do
    it "returns first_name and last_name combined" do
      child = ParentChildInfo.new(first_name: "John", last_name: "Doe")
      expect(child.full_name).to eq("John Doe")
    end

    it "handles missing names gracefully" do
      child = ParentChildInfo.new(first_name: "John")
      expect(child.full_name).to eq("John")
    end
  end

  describe "#linked?" do
    it "returns true when linked_user_id is present" do
      child = ParentChildInfo.new(linked_user_id: 1)
      expect(child.linked?).to be true
    end

    it "returns false when linked_user_id is nil" do
      child = ParentChildInfo.new(linked_user_id: nil)
      expect(child.linked?).to be false
    end
  end
end

