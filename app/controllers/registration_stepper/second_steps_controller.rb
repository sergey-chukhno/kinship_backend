module RegistrationStepper
  class SecondStepsController < ApplicationController
    skip_before_action :authenticate_user!
    skip_after_action :verify_authorized
    layout "auth"

    def new
      return redirect_to root_path if current_user

      @user_profile = UserProfile.new(
        first_name: session[:user_profile]&.dig("first_name"),
        last_name: session[:user_profile]&.dig("last_name"),
        email: session[:user_profile]&.dig("email"),
        contact_email: session[:user_profile]&.dig("contact_email"),
        role: session[:user_role]["role"],
        role_additional_information: session[:user_role]["role_additional_information"],
        birthday: parse_date_birthday(session[:user_profile]&.dig("birthday")),
        accept_privacy_policy: session[:user_profile]&.dig("accept_privacy_policy"),
        accept_marketing: session[:user_profile]&.dig("accept_marketing"),
        user_schools_attributes: session[:user_profile]&.dig("user_schools_attributes"),
        school_level_ids: session[:user_profile]&.dig("school_level_ids"),
        user_company_attributes: session[:user_profile]&.dig("user_company_attributes"),
        company_form: session[:user_role]["company_form"]
      )
    end

    def create
      remove_empty_school
      remove_empty_company
      @user_profile = UserProfile.new(user_profile_params)
      @user_profile.role = session[:user_role]["role"]
      @user_profile.role_additional_information = session[:user_role]["role_additional_information"]
      @user_profile.birthday = parse_date_birthday(params[:registration_stepper_user_profile][:birthday])
      @user_profile.company_form = session[:user_role]["company_form"]

      session_user_profile_data
      session_create_school_level_data
      session_create_custom_school_level_data

      if @user_profile.valid?
        redirect_to new_registration_stepper_third_step_path, notice: "Informations enregistrées"
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def user_profile_params
      params.require(:registration_stepper_user_profile).permit(
        :first_name,
        :last_name,
        :email,
        :contact_email,
        :birthday,
        :accept_privacy_policy,
        :accept_marketing,
        user_schools_attributes: [:school_id],
        user_company_attributes: [:company_id],
        school_level_ids: []
      )
    end

    def session_user_profile_data
      session[:user_profile] = {
        first_name: @user_profile.first_name,
        last_name: @user_profile.last_name,
        email: @user_profile.email,
        contact_email: @user_profile.contact_email,
        role: @user_profile.role,
        role_additional_information: @user_profile.role_additional_information,
        birthday: @user_profile.birthday,
        accept_privacy_policy: @user_profile.accept_privacy_policy,
        accept_marketing: @user_profile.accept_marketing,
        user_schools_attributes: @user_profile.user_schools_attributes,
        user_company_attributes: @user_profile.user_company_attributes,
        school_level_ids: @user_profile.school_level_ids,
        company_form: @user_profile.company_form
      }
    end

    def remove_empty_school
      params[:registration_stepper_user_profile][:user_schools_attributes]&.reject! { |_, user_schools_attribute| user_schools_attribute["school_id"].blank? }
    end

    def remove_empty_company
      params[:registration_stepper_user_profile][:user_company_attributes]&.reject! { |_, user_company_attribute| user_company_attribute["company_id"].blank? }
    end

    def session_create_school_level_data
      create_school_level = permit_create_school_level_params[:create_school_level].to_h

      create_school_level.each do |key, value|
        create_school_level.delete(key) if value["name"].blank? || value["level"].blank?
      end

      session[:create_school_level] = create_school_level.map { |key, value| value.to_h }
    end

    def permit_create_school_level_params
      params.permit(create_school_level: [:school_id, :level, :name])
    end

    def session_create_custom_school_level_data
      create_custom_school_level = permit_create_custom_school_level_params[:create_custom_school_level].to_h

      create_custom_school_level.each do |key, value|
        create_custom_school_level.delete(key) if value["name"].blank? || value["level"].blank?
      end

      session[:create_custom_school_level] = create_custom_school_level.map { |key, value| value.to_h }
    end

    def permit_create_custom_school_level_params
      params.permit(create_custom_school_level: [:school_id, :level, :name])
    end

    def parse_date_birthday(string_date)
      return nil if string_date.blank?

      Date.parse(string_date)
    rescue ArgumentError
      string_date
    end
  end
end
