class AssignBadgeStepper::SecondStepController < ApplicationController
  def new
    @assign_badge = AssignBadgeStepper::SecondStep.new(assign_badge_stepper_second_step_params_new)
    @projects = set_projects_collection
    authorize @assign_badge, policy_class: AssignBadgePolicy
  end

  def create
    @assign_badge = AssignBadgeStepper::SecondStep.new(assign_badge_stepper_second_step_params)
    authorize @assign_badge, policy_class: AssignBadgePolicy

    if @assign_badge.valid?
      store_assign_badge_stepper_second_step_params
      redirect_to new_assign_badge_stepper_third_step_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_projects_collection
    owner_projects = current_user.projects
    participant_projects = current_user.project_members.map(&:project)

    projects = owner_projects + participant_projects
    projects.map { |project| [project.title, project.id] }
  end

  def assign_badge_stepper_second_step_params_new
    return {project_id: params[:project_id]} if params[:project_id].present?

    session[:assign_badge_stepper_second_step_params]
  end

  def assign_badge_stepper_second_step_params
    params.require(:assign_badge_stepper_second_step).permit(:project_id)
  end

  def store_assign_badge_stepper_second_step_params
    session[:assign_badge_stepper_second_step_params] = assign_badge_stepper_second_step_params.to_h
  end
end
