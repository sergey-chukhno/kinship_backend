class Participants::OtherCompaniesController < Participants::BaseController
  def index
    @companies = Filter::ParticipantsFilter.call(collection: @companies, options: filter_params)
    @active_filters = active_filters
    # @projects_collection = user_projects_collection
  end

  private

  def participants_collection
    @companies = policy_scope User, policy_scope_class: Participants::OtherCompaniesPolicy::Scope
  end

  def filter_params
    return nil unless params[:filters]

    params.require(:filters).permit(
      :project,
      skills: [],
      take_trainee: [],
      propose_workshop: [],
      availabilities: {}
    )
  end

  def active_filters
    {
      project: false,
      skills: false,
      availabilities: false,
      take_trainee: true,
      propose_workshop: true
    }
  end
end
