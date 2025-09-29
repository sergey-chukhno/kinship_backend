class Availability < ApplicationRecord
  belongs_to :user

  DAY_OF_WEEK = %w[monday tuesday wednesday thursday friday saturday sunday other].freeze
  DAY_OF_WEEK_WITHOUT_WEEKEND = %w[monday tuesday wednesday thursday friday other].freeze

  def available?
    DAY_OF_WEEK.any? { |day| send(day) == true }
  end

  def get_day_available_stringify
    return "Non disponible" unless available?

    day_available = DAY_OF_WEEK.select { |day| send(day) }
    day_available.map { |day| I18n.t("activerecord.attributes.availability.short-days.#{day}") }.join(", ")
  end
end
