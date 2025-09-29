# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmallCardInfo::TeamListComponent, type: :component do
  let(:project) { create(:project, owner: create(:user, :teacher, email: "example@ac-nice.fr", admin: true)) }
  let(:team) { create(:team, project:) }
  let(:team_member) { create(:team_member, team:, user: create(:user)) }
  let(:team_member_2) { create(:team_member, team:, user: create(:user)) }

  it "inherits from SmallCardInfo::BaseComponent" do
    expect(described_class).to be < SmallCardInfo::BaseComponent
  end

  describe "Team List component card" do
    subject(:rendered) { render_inline(described_class.new(team:)) }

    before do
      project
      team
      team_member
      team_member_2
    end

    it "renders team title" do
      expect(rendered).to have_content(team.title)
    end

    it "renders team description" do
      expect(rendered).to have_content(team.description.truncate(70))
    end

    it "renders each member of the team" do
      team.members.each do |member|
        expect(rendered).to have_content(member.short_name.truncate(30))
      end
    end
  end
end
