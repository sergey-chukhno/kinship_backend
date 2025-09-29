class SchoolAdminPanel::BaseController < ApplicationController
  before_action :set_school, only: [:new, :create, :show, :edit, :update, :destroy, :destroy_partnership]

  private

  def set_school
    authorize @school = School.find(params[:id]), policy_class: SchoolAdminPanel::BasePolicy
  end
end
