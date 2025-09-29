class SchoolLevelsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @school_levels = school_level_filters

    render json: @school_levels.map { |school_level| {id: school_level.id, full_name: school_level.full_name, full_name_without_school: school_level.full_name_without_school} }
  end

  private

  def school_level_filters
    @school_levels = policy_scope(SchoolLevel)
    @school_levels = @school_levels.by_full_name(params_search_active_admin).limit(50) if params_search_active_admin_present?
    @school_levels = @school_levels.where(school_id: params[:school_id]) if params[:school_id].present?
    @school_levels = User.find(params[:current_user_id]).school_levels.where(school_id: params[:school_id]) if params[:current_user_id].present?
    @school_levels
  end

  def params_search_active_admin
    params["q"]["groupings"]["0"]["name_cont"]
  end

  def params_search_active_admin_present?
    params["q"].present?
  end
end
