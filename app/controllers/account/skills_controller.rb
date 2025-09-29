class Account::SkillsController < ApplicationController
  layout "account"
  before_action :set_user_and_skills, only: %i[edit update]

  def edit
  end

  def update
    if @user.update(skills_params)
      redirect_to edit_account_skill_path(@user), notice: t(@user.role, scope: [:views, :account, :skills, :form, :submit, :sucess])
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user_and_skills
    authorize @user = User.find(params[:id]), policy_class: Account::SkillsPolicy
    @skills = Skill.includes([:sub_skills]).officials
  end

  def skills_params
    if params[:user][:show_my_skills] == "false"
      params[:user][:skill_ids] = []
      params[:user][:sub_skill_ids] = []
      params[:user][:skill_additional_information] = ""
      params[:user][:expend_skill_to_school] = false
    end

    params.require(:user).permit(:show_my_skills, :skill_additional_information, :expend_skill_to_school, skill_ids: [], sub_skill_ids: [])
  end
end
