class Account::DeleteAccountController < ApplicationController
  before_action :set_user, only: %i[show new destroy]
  layout "auth", only: %i[show]

  def show
  end

  def new
    generate_delete_token
    redirect_to edit_account_profile_path(@user), notice: "Un email vous a été envoyé pour confirmer la suppression de votre compte.", status: :see_other
  end

  def destroy
    local_user = @user
    token = params[:delete_token]

    return redirect_to root_path, alert: "Votre lien est invalide" if token != @user.delete_token
    return redirect_to root_path, alert: "Votre lien a expiré, veuillez recommencer la procédure" if @user.delete_token_sent_at < 1.hour.ago

    @user.destroy
    AdminMailer.account_deleted(local_user).deliver_later
    redirect_to new_user_session_path, notice: "Votre compte a été supprimé.", status: :see_other
  end

  private

  def generate_delete_token
    @user.generate_delete_token
    UserMailer.delete_account_instruction(@user).deliver_later
  end

  def set_user
    authorize @user = User.find(params[:id]), policy_class: Account::DeleteAccountPolicy
  end
end
