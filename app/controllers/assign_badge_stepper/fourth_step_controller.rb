class AssignBadgeStepper::FourthStepController < ApplicationController
  before_action :set_badge_skills_collection, only: %i[new create]

  def new
    @assign_badge = AssignBadgeStepper::FourthStep.new(assign_badge_stepper_fourth_step_params_new)
    authorize @assign_badge, policy_class: AssignBadgePolicy
  end

  def create
    @assign_badge = AssignBadgeStepper::FourthStep.new(assign_badge_stepper_fourth_step_params)
    authorize @assign_badge, policy_class: AssignBadgePolicy

    if @assign_badge.valid?
      store_assign_badge_stepper_fourth_step_params
      redirect_to new_assign_badge_stepper_fifth_step_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_badge_skills_collection
    badge = Badge.find(session[:assign_badge_stepper_third_step_params]["badge_id"])

    @expertises_collection = badge.expertises
    @domains_collection = badge.domains
  end

  def assign_badge_stepper_fourth_step_params_new
    session[:assign_badge_stepper_fourth_step_params]
  end

  def assign_badge_stepper_fourth_step_params
    params.require(:assign_badge_stepper_fourth_step)&.permit(domain_ids: [], expertise_ids: [])
  end

  def store_assign_badge_stepper_fourth_step_params
    domain_ids = assign_badge_stepper_fourth_step_params["domain_ids"]
    expertise_ids = assign_badge_stepper_fourth_step_params["expertise_ids"]

    session[:assign_badge_stepper_fourth_step_params] = {
      domain_ids: domain_ids,
      expertise_ids: expertise_ids,
      badge_skill_ids: domain_ids + expertise_ids
    }
  end
end
