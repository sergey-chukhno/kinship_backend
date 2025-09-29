module RegistrationStepper
  class FirstStepsController < ApplicationController
    skip_before_action :authenticate_user!, only: [:new, :create]
    skip_after_action :verify_authorized, only: [:new, :create]
    layout "auth"

    def new
      return redirect_to root_path if current_user || !["tutor", "teacher", "voluntary"].include?(params[:role])

      @user_role = UserRole.new(role: params[:role], company_form: params[:company_form])
    end

    def create
      @user_role = UserRole.new(user_role_params)

      if @user_role.valid?
        session_user_role_data
        redirect_to new_registration_stepper_second_step_path
      else
        redirect_to new_registration_stepper_first_step_path(role: @user_role.role), alert: "Veuillez préciser votre fonction"
        destroy_session_user_role
      end
    end

    private

    def user_role_params
      define_role_additional_information

      params.require(:registration_stepper_user_role).permit(:role, :role_additional_information, :company_form)
    end

    def define_role_additional_information
      return unless params[:registration_stepper_user_role][:role_additional_information] == "autres"
      return if params[:registration_stepper_user_role][:role_additional_information_other].blank?

      params[:registration_stepper_user_role][:role_additional_information] = params[:registration_stepper_user_role][:role_additional_information_other]
    end

    def session_user_role_data
      session[:user_role] = {
        role: @user_role.role,
        role_additional_information: @user_role.role_additional_information,
        company_form: @user_role.company_form
      }
    end

    def destroy_session_user_role
      session.delete("user_role")
    end
  end
end
