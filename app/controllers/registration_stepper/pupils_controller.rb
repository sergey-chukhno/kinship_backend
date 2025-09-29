module RegistrationStepper
  class PupilsController < ApplicationController
    layout "registration_stepper"

    def new
      @child = authorize User.new
    end

    def create
      initialize_child
      render_new_with_errors and return unless @child.errors.empty?

      if @child.save
        after_save_actions
      else
        render_new_with_errors
      end
    end

    private

    def initialize_child
      @child = User.new(user_params)
      @child.assign_attributes(
        parent_id: current_user.id,
        role: "voluntary",
        role_additional_information: "enfant",
        job: "Eleve",
        email: nil
      )
      authorize @child
      check_age
    end

    def render_new_with_errors
      flash[:alert] = @child.errors.full_messages.join(", ")
      render :new
    end

    def after_save_actions
      if create_user_schools
        create_user_school_levels
        redirect_to edit_registration_stepper_pupil_skill_path(id: @child.id), notice: "#{@child.full_name} a bien été créé"
      else
        flash[:alert] = "Vous devez renseigner une école"
        render :new
      end
    end

    def user_params
      params.require(:user).permit(
        :first_name,
        :last_name,
        :birthday,
        :accept_privacy_policy,
        user_schools_attributes: [:id, :school_id, :_destroy],
        user_school_levels_attributes: [:id, :school_level_id, :_destroy]
      )
    end

    def create_user_schools
      user_school = @child.user_schools.new(school_id: params[:user_schools][:school_id])
      user_school.save
    end

    def create_user_school_levels
      return unless params[:user_school_levels] || params[:user_school_levels] & [:school_level_id].blank?

      user_school_level = @child.user_school_levels.new(school_level_id: params[:user_school_levels][:school_level_id])
      user_school_level.save
    end

    def check_age
      return @child.errors.add(:birthday, "L'âge de l'élève doit être renseigné") if @child.birthday.blank?
      return if @child.age < 15

      @child.errors.add(:birthday, "L'âge de l'élève doit être inférieur à 15 ans")
    end

    def render_if_age_not_valid
      render :new and return unless @child.errors.empty?
    end
  end
end
