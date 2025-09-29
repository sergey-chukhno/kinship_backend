class Account::NetworksController < ApplicationController
  layout "account"
  before_action :set_user, only: %i[edit update]

  def edit
  end

  def update
    if @user.update(networks_params)
      redirect_to edit_account_network_path(@user), notice: t(@user.role, scope: [:views, :account, :networks, :form, :submit, :sucess])
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user_company = UserCompany.find(params[:id]), policy_class: Account::NetworksPolicy
    @user = @user_company.user

    if @user_company.destroy
      redirect_to edit_account_network_path(@user), notice: "Organisation supprimée"
    else
      redirect_to edit_account_network_path(@user), alert: "Une erreur est survenue"
    end
  end

  private

  def set_user
    authorize @user = User.find(params[:id]), policy_class: Account::NetworksPolicy
  end

  def networks_params
    params.require(:user).permit(:job, :company_name, :take_trainee, :propose_workshop, user_company_attributes: [:id, :company_id, :_destroy])
  end
end
