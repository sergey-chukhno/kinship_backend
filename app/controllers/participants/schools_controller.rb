class Participants::SchoolsController < Participants::BaseController
  def index
    @participants = Filter::ParticipantsFilter.call(collection: @participants, options: filter_params)
    @active_filters = current_user.teacher? ? active_filters_for_teacher : active_filters_for_tutor_and_voluntary
  end

  private

  def participants_collection
    @participants = policy_scope User, policy_scope_class: Participants::SchoolsPolicy::Scope
  end

  def filter_params
    return nil unless params[:filters]

    params.require(:filters).permit(
      :school,
      :school_level,
      skills: [],
      sub_skills: [],
      take_trainee: [],
      propose_workshop: [],
      availabilities: {}
    )
  end

  def active_filters_for_teacher
    {
      school: true,
      skills: teacher_filter?,
      availabilities: teacher_filter?,
      take_trainee: teacher_filter?,
      propose_workshop: teacher_filter?
    }
  end

  def active_filters_for_tutor_and_voluntary
    {
      school: true,
      skills: false,
      availabilities: false,
      take_trainee: current_user.schools.any? && current_user.user_schools.pending.empty?,
      propose_workshop: false
    }
  end

  def teacher_filter?
    return current_user.schools&.map(&:contracts)&.flatten&.any? && (current_user.schools&.map(&:contracts) == current_user.schools&.map(&:contracts)&.flatten) if params[:filters].blank? || params[:filters][:school].blank?

    School.find(params[:filters][:school]).contracts.any?(&:active)
  end
end
