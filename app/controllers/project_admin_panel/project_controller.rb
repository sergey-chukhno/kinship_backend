class ProjectAdminPanel::ProjectController < ApplicationController
  before_action :set_project, only: [:edit, :update]

  skip_before_action :authenticate_user!, only: [:badges_tree, :modal_badges_details]

  def edit
    @main_picture_file = generate_one_attachment_json(@project, "main_picture")
    @pictures_files = generate_many_attachments_json(@project, "pictures")
    @documents_files = generate_many_attachments_json(@project, "documents")
  end

  def update
    if @project.update(project_params.except(:keyword_ids))
      create_keyword
      redirect_to project_admin_panel_project_path(@project)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def badges_tree
    @project = authorize Project.find(params[:project_id]), policy_class: ProjectAdminPanel::BasePolicy

    if !params[:public_access] && !(@project.owner == current_user)
      flash[:alert] = "Vous n'êtes pas autorisé.e à accéder à cette page."
      redirect_to(root_path)
    end

    @user_badges = @project.user_badges
    @user_badges_count = @user_badges.count

    @badges_categories = Badge.select(:name).distinct.pluck(:name)

    @user_badges_count_per_category = @user_badges.joins(:badge)
      .select("badges.name")
      .group("badges.name")
      .count
      .sort_by { |_, count| -count }
      .to_h

    @percentage_per_category = @badges_categories.each_with_object({}) do |category, result|
      if @user_badges_count.zero?
        result[category] = 0
      else
        count = @user_badges_count_per_category[category].to_f
        result[category] = ((count / @user_badges_count) * 100).ceil
      end
    end.sort_by { |_, percentage| -percentage }.to_h

    @user_badges_per_level = @user_badges.joins(:badge)
      .group("badges.name, badges.level")
      .select("badges.name, badges.level::text, COUNT(*) as count")
      .order("count DESC")
      .map { |result| [[result.name, "level_#{result.level.to_i + 1}"], result.count] }
      .to_h
  end

  def modal_badges_details
    @project = authorize Project.find(params[:project_id]), policy_class: ProjectAdminPanel::BasePolicy
    @badge = Badge.find_by(name: params[:badge_name])
    @user_badges = UserBadge.where(project_id: @project.id, badge_id: @badge.id)
  end

  private

  def set_project
    @project = authorize Project.find(params[:id]), policy_class: ProjectAdminPanel::BasePolicy
  end

  def project_params
    params.require(:project).permit(
      :title,
      :description,
      :start_date,
      :end_date,
      :main_picture,
      :status,
      :time_spent,
      :participants_number,
      :private,
      :company_id,
      tag_ids: [],
      skill_ids: [],
      keyword_ids: [],
      school_level_ids: [],
      company_ids: [],
      pictures: [],
      documents: [],
      links_attributes: [:id, :name, :url, :_destroy],
      teams_attributes: [:id, :title, :description, :_destroy]
    )
  end

  def generate_one_attachment_json(project, type)
    return unless project.send(type).attached?

    [{
      filename: project.send(type).filename,
      byte_size: project.send(type).byte_size,
      # url: project.send(type).url,
      content_type: project.send(type).content_type,
      signed_id: project.send(type).signed_id
    }].to_json
  end

  def generate_many_attachments_json(project, type)
    return unless project.send(type).attached?

    project.send(type).map do |attachment|
      {
        filename: attachment.filename,
        byte_size: attachment.byte_size,
        # url: attachment.url,
        content_type: attachment.content_type,
        signed_id: attachment.signed_id
      }
    end.to_json
  end

  def create_keyword
    new_keywords = project_params[:keyword_ids].reject!(&:blank?).reject { |element| element =~ /\A\d+\z/ }
    return if new_keywords.blank?

    params[:project][:keyword_ids] -= new_keywords
    new_keywords.each do |keyword|
      params[:project][:keyword_ids] << Keyword.create(
        name: keyword,
        project: @project
      ).id
    end
  end
end
