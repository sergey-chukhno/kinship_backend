require "rails_helper"

RSpec.describe School, type: :model do
  it { is_expected.to have_a_valid_factory }

  describe "associations" do
    it { should have_many(:school_levels) }
    it { should have_many(:user_schools) }
    it { should have_many(:users).through(:user_schools) }
    it { should have_many(:contracts) }
    it { should have_many(:school_companies).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:zip_code) }
    it { should validate_presence_of(:school_type) }
    it { should validate_presence_of(:city) }
    it { should validate_presence_of(:status) }
    it { should define_enum_for(:school_type).with_values([:primaire, :college, :lycee, :erea, :medico_social, :service_administratif, :information_et_orientation, :autre]) }
    it { should define_enum_for(:status).with_values([:pending, :confirmed]) }
  end

  describe "nested attributes" do
    it { should accept_nested_attributes_for(:school_levels).allow_destroy(true) }
  end

  describe "scopes" do
    context ".by_zip_code" do
      let!(:school) { create(:school) }

      it "returns the school with the given zip code" do
        expect(School.by_zip_code(school.zip_code)).to eq([school])
      end
    end

    context ".by_school_type" do
      let!(:school) { create(:school) }

      it "returns the school with the given school type" do
        expect(School.by_school_type(school.school_type)).to eq([school])
      end
    end
  end

  describe "methods" do
    context "#full_name" do
      let(:school) { create(:school) }

      it "returns the school's full name" do
        expect(school.full_name).to eq("#{school.name}, #{school.city} (#{school.zip_code})")
      end
    end

    context "#owner?" do
      let(:school) { create(:school) }

      it "returns false if the school don't have owner" do
        expect(school.owner?).to eq(false)
      end

      it "returns true if the school have owner" do
        create(:user_school, school: school, owner: true)
        expect(school.owner?).to eq(true)
      end
    end

    context "#owner" do
      let(:school) { create(:school) }

      it "returns the owner of the school" do
        user_school = create(:user_school, school: school, owner: true)
        expect(school.owner).to eq(user_school)
      end
    end
  end
end
