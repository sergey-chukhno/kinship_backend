class ProjectAdminPanel::ProjectMembersController < ApplicationController
  before_action :set_project, only: [:show]

  def show
    @members = @project.project_members
    @project_id = params[:id]

    @teams = @project.teams.select("id, title")
    @teams_collection = @teams.map { |team| [team.title, team.id] }

    @members = if params[:status] == "pending"
      @members.where(status: "pending")
    else
      @members.where(status: "confirmed")
    end
  end

  def update_team
    @project_id = params.dig(:project_member, :project_id)
    @team_id = params.dig(:project_member, :team_id)
    @project = authorize Project.find(@project_id), policy_class: ProjectAdminPanel::BasePolicy
    @user = User.find(params[:id])

    if !@team_id.blank?
      @user_current_team = @user.teams.find_by(project_id: @project_id)
      if @user_current_team
        # If the user is already a member of the team, update the TeamMember
        @team_member = TeamMember.find_by(user: @user, team: @user_current_team)
        @team_member.team_id = @team_id
      else
        # If the user is not a member of the team, create a new TeamMember
        @team_member = TeamMember.new(user: @user, team_id: @team_id)
      end

      if @team_member.save!
        flash[:notice] = "L'équipe de l'utilisateur a été changée avec succès."
      else
        flash[:alert] = "Une erreur est survenue lors du changement de l'équipe."
      end
    else
      @project_teams = Team.where(project: @project)
      TeamMember.where(user: @user, team: @project_teams).destroy_all
      flash[:notice] = "L'équipe de l'utilisateur a été changée avec succès."
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @project_member = ProjectMember.new

    if params[:filter].present?
      @network_type = params.require(:filter)[:network_type]
      @project_id = params.require(:filter)[:project_id]

      @selected_project = params.require(:filter)[:project]
      @selected_company = params.require(:filter)[:company]
      @selected_school = params.require(:filter)[:school]
      @selected_school_level = params.require(:filter)[:school_level]

      @participants = params.require(:filter)[:user_ids] || []
      @participants = @participants.reject(&:blank?).map(&:to_i)

      @available_users = []
      case @network_type
      when "schools"
        @available_users = policy_scope User, policy_scope_class: Participants::SchoolsPolicy::Scope
      when "organizations"
        @available_users = policy_scope User, policy_scope_class: Participants::CompaniesPolicy::Scope
      when "projects"
        @available_users = policy_scope User, policy_scope_class: Participants::ProjectsPolicy::Scope
      end

      if @available_users.any?
        @available_users = Filter::ParticipantsFilter.call(
          collection: @available_users,
          options: filter_params
        )
      end

      @project_member = authorize Project.find(@project_id), policy_class: ProjectAdminPanel::BasePolicy
    else
      @project_id = params[:project_id]
      @project_member = authorize Project.find(params[:project_id]), policy_class: ProjectAdminPanel::BasePolicy
      @network_type = params[:network_type]
      @participants = []

      @available_users = []
      @available_users += policy_scope(User, policy_scope_class: Participants::ProjectsPolicy::Scope)
      @available_users += policy_scope(User, policy_scope_class: Participants::CompaniesPolicy::Scope)
      @available_users += policy_scope(User, policy_scope_class: Participants::SchoolsPolicy::Scope)
      @available_users.uniq!
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    @project = authorize Project.find(params[:project][:project_id]), policy_class: ProjectAdminPanel::BasePolicy
    user_ids = params[:project_member][:user_ids] || []

    created_members = []
    user_ids.each do |user_id|
      project_member = ProjectMember.new(project: @project, user_id: user_id, status: :confirmed)
      created_members << project_member if project_member.save
    end

    if created_members.any?
      flash[:notice] = "Les participants ont été ajoutés avec succès."
    else
      flash[:alert] = "Aucun participant n'a été ajouté."
    end

    redirect_to project_admin_panel_project_member_path(@project.id, status: :confirmed)
  end

  def destroy
    @project_member = authorize ProjectMember.find(params[:id]), policy_class: ProjectAdminPanel::BasePolicy
    @project_member.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to project_admin_panel_project_member_path(@project_member.project_id, status: :pending), notice: "Project member was successfully destroyed." }
    end
  end

  def update_confirmation
    @project_member = authorize ProjectMember.find(params[:id]), policy_class: ProjectAdminPanel::BasePolicy

    if @project_member.pending?
      @project_member.confirmed!
      ProjectMemberMailer.notify_project_member_got_confirmed(@project_member).deliver_later
    else
      @project = Project.find(params.dig(:project_member, :project_id))
      @project_member.admin = false
      @project_member.status = "pending"
      @project_teams = Team.where(project: @project)
      TeamMember.where(team: @project_teams, user: @project_member.user).destroy_all

      @project_member.save!
    end
  end

  def update_admin_status
    @project_member = authorize ProjectMember.find(params[:id]), policy_class: ProjectAdminPanel::BasePolicy
    @project_member.admin = !@project_member.admin?
    @project_member.save!
  end

  private

  def set_project
    @project = authorize Project.find(params[:id]), policy_class: ProjectAdminPanel::BasePolicy
  end

  def filter_params
    return nil unless params[:filter]

    params.require(:filter).permit(:school, :school_level, :company, :project)
  end

  def project_member_params
    params.require(:project_member).permit(user_ids: [])
  end
end
