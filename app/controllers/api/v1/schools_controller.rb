class Api::V1::SchoolsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index]

  def index
    @schools = in_admin? ? schools_filtered : schools_filtered.confirmed

    render json: @schools.map { |school| {id: school.id, full_name: school.full_name, zip_code: school.zip_code, school_type: school.school_type} }
  end

  private

  def schools_filtered
    @schools = policy_scope(School)
    @schools = @schools.by_full_name(params_full_name) if params_full_name_present?
    @schools = @schools.by_zip_code(params[:zip_code]) if params[:zip_code].present?
    @schools = @schools.by_school_type(params[:school_type]) if params[:school_type].present?
    @schools.limit(20)
  end

  def params_full_name_present?
    params[:name].present? || params["q"].present?
  end

  def in_admin?
    params[:controller].include?("admin") || params[:admin] == "true"
  end

  def params_full_name
    return params[:name] if params[:name].present?

    params["q"]["groupings"]["0"]["name_cont"] if params["q"].present?
  end
end
