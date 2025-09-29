class ProjectsController < ApplicationController
  include Pagy::Backend

  has_scope :by_search, using: [:query] do |controller, scope|
    scope.search(controller.params[:by_search][:query])
  end

  has_scope :my_projects, type: :boolean do |controller, scope|
    scope.my_projects(controller.current_user)
  end

  has_scope :my_administration_projects, type: :boolean do |controller, scope|
    scope.my_administration_projects(controller.current_user).distinct
  end

  has_scope :my_schools, type: :boolean do |controller, scope|
    scope
      .my_projects(controller.current_user)
      .by_school(controller.school_ids_where_user_is_confirmed_or_admin_or_owner)
  end

  has_scope :my_organizations, type: :boolean do |controller, scope|
    scope
      .default_project(controller.current_user)
      .by_companies(controller.companies_ids_where_user_is_confirmed_or_admin_or_owner)
  end

  has_scope :by_school, using: [:school_id], type: :hash
  has_scope :by_school_level, using: [:school_level_id], type: :hash
  has_scope :by_companies, using: [:company_id], type: :hash
  has_scope :by_tags, using: [:tag_ids], type: :hash

  def index
    @pagy, @projects = pagy(
      apply_scopes(policy_scope(Project.default_project(current_user).order(id: :desc))).all
    )

    @my_projects_count = Project.default_project(current_user).my_projects(current_user).count
    @project_by_companies_count = policy_scope(Project.default_project(current_user).by_companies(companies_ids_where_user_is_confirmed_or_admin_or_owner)).count
    @project_by_schools_count = policy_scope(Project.default_project(current_user).my_projects(current_user).by_school(school_ids_where_user_is_confirmed_or_admin_or_owner)).count
    @project_where_user_is_admin_count = policy_scope(Project.default_project(current_user).my_administration_projects(current_user)).count

    @schools_collection = schools_collection
    @school_levels_collection = school_levels_collection
    @school_level_selected_id = school_level_id_selected

    @companies_collection = current_user.user_company.confirmed.map { |user_company| [user_company.company.full_name, user_company.company.id] }
  end

  def show
    @project = Project.find(params[:id])
    authorize @project
  end

  def new
    @project = authorize Project.new
  end

  def create
    @project = authorize Project.new(project_params_without_keywords)
    @project.owner = current_user

    if @project.save
      create_keyword
      # TEMPORARY DISABLED TO AVOIR SPAMMING PARENTS
      # send_project_notification_mail_to_users(@project)
      redirect_to project_path(@project)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def companies_ids_where_user_is_confirmed_or_admin_or_owner
    current_user.user_company
      .where(status: "confirmed")
      .or(current_user.user_company.where(admin: true))
      .or(current_user.user_company.where(owner: true))
      .pluck(:company_id)
  end

  def school_ids_where_user_is_confirmed_or_admin_or_owner
    current_user.user_schools.where(status: "confirmed")
      .or(current_user.user_schools.where(admin: true))
      .or(current_user.user_schools.where(owner: true))
      .pluck(:school_id)
  end

  private

  def schools_collection
    schools = current_user.schools.map { |school| [school.full_name, school.id] }
    options_all_schools = ["Tous mes établissements", schools.map(&:last)]

    schools.unshift(options_all_schools)
  end

  def school_levels_collection
    return [] unless params[:by_school].present? && params[:by_school][:school_id].present?
    return [] if params[:by_school][:school_id].start_with?("[")

    School.find(params[:by_school][:school_id]).school_levels.map { |school_level| [school_level.full_name_without_school, school_level.id] }
  end

  def school_level_id_selected
    return nil unless params[:by_school_level].present? && params[:by_school_level][:school_level_id].present?

    params[:by_school_level][:school_level_id]
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

  # TEMPORARY DISABLED TO AVOIR SPAMMING PARENTS
  # def send_project_notification_mail_to_users(project)
  # users_to_notify = project.users.uniq.reject { |user| user == current_user }

  # users_to_notify.each do |user|
  #   ProjectMailer.new_project_notification(user: user, project: project).deliver_later
  # end
  # end

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

  def project_params_without_keywords
    project_params.except(:keyword_ids)
  end
end
