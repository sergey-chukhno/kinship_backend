module RegistrationStepper
  class FifthStepsController < ApplicationController
    before_action :set_user, only: %i[edit update]
    skip_after_action :verify_authorized
    layout "auth"

    def edit
    end

    def update
      if update_user_or_company
        confirm_user(@user) if Rails.env.development?
        redirect_to registration_stepper_pending_confirmation_path
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def registration_complete
    end

    def pending_confirmation
      redirect_to root_path if current_user.confirmed?
    end

    private

    def user_params
      params.require(:user).permit(
        :show_my_skills,
        :skill_additional_information,
        :expend_skill_to_school,
        :propose_workshop,
        :company_name,
        :take_trainee,
        :job,
        skill_ids: [],
        sub_skill_ids: []
      )
    end

    def company_params
      params.require(:company).permit(
        :skill_additional_information,
        :job,
        :take_trainee,
        :propose_workshop,
        :propose_summer_job,
        skill_ids: [],
        sub_skill_ids: []
      )
    end

    def set_user
      authorize @user = User.find(params[:id])
      @skills = Skill.officials
      if params[:company_form] == "true"
        @company = @user.companies.last
      end
    end

    def update_user_or_company
      if params[:company_form] == "true"
        @company.update(company_params)
      else
        @user.update(user_params)
      end
    end

    def confirm_user(user)
      user.confirm
      user.save
    end
  end
end
