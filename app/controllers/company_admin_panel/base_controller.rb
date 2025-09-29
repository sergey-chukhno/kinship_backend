class CompanyAdminPanel::BaseController < ApplicationController
  before_action :set_company, only: [:show, :new, :create, :edit, :update, :destroy, :destroy_sponsor, :update_sponsor_confirmation]

  private

  def set_company
    authorize @company = Company.find(params[:id]), policy_class: CompanyAdminPanel::BasePolicy
  end
end
