# frozen_string_literal: true

class Participant::Card::CardComponent < ViewComponent::Base
  with_collection_parameter :participant

  def initialize(participant:, current_user:)
    @participant = participant
    @current_user = current_user
    @participant_skills = @participant.skills.map(&:name)
    @participant_availabilities = participant_availabilities
  end

  private

  def participant_availabilities
    return false unless @participant.availability.available?

    days_available = Availability::DAY_OF_WEEK.select { |day| @participant.availability.send(day) }
    days_available.map { |day| I18n.t("activerecord.attributes.availability.short-days.#{day}") }.join(", ")
  end

  def contact?
    return false if @participant.teacher? || @participant.children?
    return true if @participant.take_trainee?
    return false unless @participant.show_my_skills?

    true
  end

  def children_role
    case @participant.parent.role
    when "tutor"
      "Enfant"
    when "voluntary"
      "Adhérent"
    when "teacher"
      "Élève"
    end
  end

  def render_badge_action?
    @current_user.can_give_badges?
  end

  def can_certify?
    (@participant.tutor? || @participant.voluntary?) && (@current_user.teacher? && @current_user.certify?) || @current_user.admin?
  end
end
