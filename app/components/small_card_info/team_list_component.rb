# frozen_string_literal: true

module SmallCardInfo
  class TeamListComponent < BaseComponent
    def initialize(team:)
      @team = team
    end

    def render?
      @team.present?
    end
  end
end
