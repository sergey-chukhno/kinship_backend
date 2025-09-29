class Participants::BaseController < ApplicationController
  before_action :participants_collection, :filters_collection, only: [:index]

  private

  def participants_collection
  end

  def filters_collection
    @availabilities = Availability::DAY_OF_WEEK_WITHOUT_WEEKEND.map { |day| [I18n.t("activerecord.attributes.availability.days.#{day}"), day] }
    @skills = Skill.officials.includes(:sub_skills)
  end
end
