class TeamMembersController < ApplicationController
  before_action :set_project_and_users, only: %i[edit update]

  def edit
    @team = authorize Team.find(params[:id])
  end

  def update
    @team = authorize Team.find(params[:id])

    if @team.update(team_member_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to project_path(@project) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_project_and_users
    @project = authorize Project.find(params[:project_id])
    @users = @project.project_members.confirmed.map(&:user)
  end

  def team_member_params
    params.require(:team).permit(user_ids: [])
  end
end
