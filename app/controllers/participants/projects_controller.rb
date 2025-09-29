class Participants::ProjectsController < Participants::BaseController
  def index
    @participants = Filter::ParticipantsFilter.call(collection: @participants, options: filter_params)
    @active_filters = active_filters
    @projects_collection = user_projects_collection
  end

  private

  def participants_collection
    @participants = policy_scope(User, policy_scope_class: Participants::ProjectsPolicy::Scope)
  end

  def user_projects_collection
    collection = current_user.projects
    collection += current_user.project_members.select(&:confirmed?).map(&:project)
    collection.sort_by { |project| -project.id }.uniq
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
      project: filters?,
      skills: filters?,
      availabilities: filters?,
      take_trainee: true,
      propose_workshop: filters?
    }
  end

  def filters?
    return false if params[:filters].blank? || params[:filters][:project].blank?

    Project.find(params[:filters][:project]).companies.any? { |company| company.active_contract? }
  end
end
