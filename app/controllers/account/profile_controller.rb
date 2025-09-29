class Account::ProfileController < ApplicationController
  layout "account"
  before_action :set_profile, only: [:edit, :update, :destroy]
  before_action :set_role_additional_information_collection, only: [:edit, :update]

  def edit
  end

  def update
    if @user.update(profile_params)
      redirect_to edit_account_profile_path(@user), notice: "Votre profil a été mis à jour"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    set_role_additional_information_params

    params.require(:user).permit(:first_name, :last_name, :contact_email, :role_additional_information, :accept_marketing)
  end

  def set_profile
    authorize @user = User.find(params[:id]), policy_class: Account::ProfilePolicy
  end

  def set_role_additional_information_collection
    @role_additional_information_collection = User::PARENTS_ADDITIONAL_ROLES if @user.tutor?
    @role_additional_information_collection = User::VOLUNTARYS_ADDITIONAL_ROLES if @user.voluntary?
    @role_additional_information_collection = User::TEACHERS_ADDITIONAL_ROLES if @user.teacher?
  end

  def set_role_additional_information_params
    if params[:user][:role_additional_information] == "Autres" && params[:user][:role_additional_information_custom].present?
      params[:user][:role_additional_information] = params[:user][:role_additional_information_custom]
    end
  end
end
