class ProjectMembersController < ApplicationController
  before_action :set_project_and_user, only: %i[new create]

  def new
    @project_member = authorize ProjectMember.new(project: @project, user: @user)
  end

  def create
    @project_member = authorize ProjectMember.new(project: @project, user: @user)
    @message = params[:project_member][:message]

    if @project_member.save
      ProjectMailer.participate_request(project: @project, message: @message, user: @user).deliver_later

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to project_path(@project), notice: "Votre demande de participation a bien été envoyée." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_project_and_user
    @project = Project.find(params[:project_id])
    @user = current_user
  end
end
