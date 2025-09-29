class Account::AvailabilitiesController < ApplicationController
  layout "account"
  before_action :set_user, only: %i[edit update]

  def edit
  end

  def update
    if @user.update(availabilities_params)
      redirect_to edit_account_availability_path(@user), notice: t(@user.role, scope: [:views, :account, :availabilities, :form, :submit, :sucess])
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    authorize @user = User.find(params[:id]), policy_class: Account::AvailabilitiesPolicy
  end

  def availabilities_params
    params.require(:user).permit(availability_attributes: [:id, :monday, :tuesday, :wednesday, :thursday, :friday, :other])
  end
end
