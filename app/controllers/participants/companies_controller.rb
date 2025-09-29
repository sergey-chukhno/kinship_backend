class Participants::CompaniesController < Participants::BaseController
  def index
    @participants = Filter::ParticipantsFilter.call(collection: @participants, options: filter_params)
    @active_filters = active_filters
    @companies_collection = current_user.user_company.confirmed.map(&:company).flatten.select(&:confirmed?).uniq
  end

  private

  def participants_collection
    @participants = policy_scope User, policy_scope_class: Participants::CompaniesPolicy::Scope
  end

  private

  def filter_params
    return nil unless params[:filters]

    params.require(:filters).permit(
      :company,
      skills: [],
      take_trainee: [],
      propose_workshop: [],
      availabilities: {}
    )
  end

  def active_filters
    {
      company: filters?,
      skills: filters?,
      availabilities: filters?,
      take_trainee: true,
      propose_workshop: filters?
    }
  end

  def filters?
    return false if params[:filters].blank? || params[:filters][:company].blank?

    Company.find(params[:filters][:company]).contracts.any?(&:active)
  end
end
