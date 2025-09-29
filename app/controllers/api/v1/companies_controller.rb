class Api::V1::CompaniesController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @companies = in_admin? ? companies_filtered : companies_filtered.confirmed

    render json: @companies.map { |company| {id: company.id, full_name: company.full_name} }
  end

  private

  def in_admin?
    params[:admin].present? && params[:admin] == "true"
  end

  def companies_filtered
    @companies = policy_scope(Company, policy_scope_class: Api::CompaniesPolicy::Scope)
    @companies = @companies.by_full_name(params_full_name) if params_full_name
    @companies.limit(20)
  end

  def params_full_name
    return false unless params[:full_name].present?

    params[:full_name]
  end
end
