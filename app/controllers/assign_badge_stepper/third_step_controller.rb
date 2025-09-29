class AssignBadgeStepper::ThirdStepController < ApplicationController
  before_action :set_badges_collection, only: %i[new create]

  def new
    @assign_badge = AssignBadgeStepper::ThirdStep.new(assign_badge_stepper_third_step_params_new)
    authorize @assign_badge, policy_class: AssignBadgePolicy
  end

  def create
    @assign_badge = AssignBadgeStepper::ThirdStep.new(assign_badge_stepper_third_step_params)
    authorize @assign_badge, policy_class: AssignBadgePolicy

    if @assign_badge.valid?
      store_assign_badge_stepper_third_step_params
      redirect_to new_assign_badge_stepper_fourth_step_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_badges_collection
    @badges_collection = Badge
      .includes(icon_attachment: [:blob])
      .all
      .order(:name, :level)
  end

  def assign_badge_stepper_third_step_params_new
    session[:assign_badge_stepper_third_step_params]
  end

  def assign_badge_stepper_third_step_params
    params.require(:assign_badge_stepper_third_step).permit(:badge_id)
  end

  def store_assign_badge_stepper_third_step_params
    session[:assign_badge_stepper_third_step_params] = assign_badge_stepper_third_step_params.to_h
  end
end
