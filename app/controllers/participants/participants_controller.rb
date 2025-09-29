class Participants::ParticipantsController < Participants::BaseController
  before_action :set_participant, only: [:update_certificate]

  def index
  end

  private

  def participants_collection
    @participants = policy_scope User, policy_scope_class: Participants::SchoolsPolicy::Scope
    @participants += policy_scope(User, policy_scope_class: Participants::CompaniesPolicy::Scope) if current_user.companies.any?
    @participants += policy_scope(User, policy_scope_class: Participants::ProjectsPolicy::Scope) if current_user.project_members.any? || current_user.projects.any?
    @participants = @participants.uniq.sort_by! { |participant| [participant.certify ? 0 : 1, participant.first_name, participant.last_name] } if @participants.any?
  end
end
