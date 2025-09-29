class RegistrationStepper::PupilSkillsController < ApplicationController
  layout "registration_stepper"

  def edit
    @child = authorize User.find(params[:id])
  end
end
