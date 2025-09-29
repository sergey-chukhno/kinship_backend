class Account::Schools::SchoolLevelsController < ApplicationController
  before_action :set_user_and_school, only: %i[edit update]

  def edit
  end

  def update
    if @current_user.update(school_level_params)
      redirect_to edit_account_school_path(@current_user), notice: "Classes mises à jour"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def school_level_params
    params.require(:user).permit(user_school_levels_attributes: [:id, :school_level_id, :_destroy])
  end

  def set_user_and_school
    authorize @current_user = current_user, policy_class: Account::Schools::SchoolLevelsPolicy
    authorize @school = School.find(params[:id]), policy_class: Account::Schools::SchoolLevelsPolicy
  end
end
