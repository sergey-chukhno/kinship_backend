module RegistrationStepper
  class ThirdStepsController < ApplicationController
    skip_before_action :authenticate_user!
    skip_after_action :verify_authorized
    layout "auth"

    def new
      redirect_to root_path if session[:user_profile].blank? || session[:user_role].blank? || current_user

      @user_password = UserPassword.new
      @user_profile = UserProfile.new(session[:user_profile])
    end

    def create
      @user_password = UserPassword.new(user_password_params)
      @user_profile = UserProfile.new(session[:user_profile])
      @is_company_form = @user_profile.company_form == "true"

      if @user_password.valid?
        @user = create_user
        create_school_levels if @user
        create_custom_school_level_request_mailer if @user

        sign_in(@user) if @user
        delete_session_data

        redirect_to_next_step
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def user_password_params
      params.require(:registration_stepper_user_password).permit(
        :password,
        :password_confirmation
      )
    end

    def create_user
      user = User.new(user_full_params_data)
      user.save ? user : nil
    end

    def user_full_params_data
      {
        first_name: @user_profile.first_name,
        last_name: @user_profile.last_name,
        email: @user_profile.email,
        contact_email: @user_profile.contact_email,
        role: @user_profile.role,
        role_additional_information: @user_profile.role_additional_information,
        birthday: @user_profile.birthday,
        password: @user_password.password,
        password_confirmation: @user_password.password_confirmation,
        accept_privacy_policy: @user_profile.accept_privacy_policy,
        user_schools_attributes: @user_profile.user_schools_attributes || {},
        user_company_attributes: @user_profile.user_company_attributes || {},
        school_level_ids: @user_profile.school_level_ids
      }
    end

    def create_school_levels
      session[:create_school_level].each do |school_level|
        new_school_level = SchoolLevel.create(school_level)
        @user.school_levels << new_school_level if new_school_level.persisted?
      end
    end

    def create_custom_school_level_request_mailer
      session[:create_custom_school_level].each do |school_level|
        SchoolLevelMailer.school_level_creation_request(
          user_requestor_full_name: @user.full_name,
          user_requestor_email: @user.email,
          school: School.find(school_level["school_id"]),
          school_level_wanted: school_level["level"] + " " + school_level["name"]
        ).deliver_later
      end
    end

    def redirect_to_next_step
      return redirect_to edit_registration_stepper_fifth_step_path(@user) if @user.teacher?
      return redirect_to new_registration_stepper_fourth_step_path(id: @user) if @is_company_form

      redirect_to edit_registration_stepper_fourth_step_path(@user)
    end

    def delete_session_data
      session.delete("user_profile")
      session.delete("user_role")
      session.delete("user_password")
      session.delete("create_school_level")
      session.delete("create_custom_school_level")
    end
  end
end
