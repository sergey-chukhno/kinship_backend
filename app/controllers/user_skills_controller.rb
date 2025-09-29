class UserSkillsController < ApplicationController
  def update
    @user = authorize User.find(params[:id])
    @user.update(user_params)

    redirect_to path_to_redirect, notice: message_flash
  end

  private

  def user_params
    params.require(:user).permit(
      :skill_additional_information,
      :expend_skill_to_school,
      skill_ids: [],
      sub_skill_ids: []
    )
  end

  def path_to_redirect
    return registration_stepper_subscription_confirmation_path if request.referer.include?("/registration_stepper/fifth_step")

    edit_user_registration_path(@user, params_for_edit_redirection)
  end

  def params_for_edit_redirection
    return {page: "my-child", child_id: @user.id} if @user.has_parent

    {page: "skills"}
  end

  def message_flash
    return "" if request.referer.include?("/registration_stepper/fifth_step")
    return "Compétences de #{@user.full_name} enregistrées !" if request.referer.include?("/pupil_skill")

    "Vos compétences ont bien été mises à jour"
  end
end
