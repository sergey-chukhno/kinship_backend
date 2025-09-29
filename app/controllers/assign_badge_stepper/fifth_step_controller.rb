class AssignBadgeStepper::FifthStepController < ApplicationController
  def new
    @assign_badge = UserBadge.new(assign_badge_params_new)
    set_project_title_and_description
    authorize @assign_badge, policy_class: AssignBadgePolicy
  end

  def create
    @assign_badge = UserBadge.new(assign_badge_params)
    authorize @assign_badge, policy_class: AssignBadgePolicy

    if @assign_badge.save
      clear_sessions
      redirect_to assign_badge_stepper_success_step_path(@assign_badge)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_project_title_and_description
    return if session[:assign_badge_stepper_second_step_params]["project_id"].blank?

    @assign_badge.project_title = Project.find(session[:assign_badge_stepper_second_step_params]["project_id"]).title
    @assign_badge.project_description = Project.find(session[:assign_badge_stepper_second_step_params]["project_id"]).description
  end

  def clear_sessions
    session.delete(:assign_badge_stepper_first_step_params)
    session.delete(:assign_badge_stepper_second_step_params)
    session.delete(:assign_badge_stepper_third_step_params)
    session.delete(:assign_badge_stepper_fourth_step_params)
  end

  def assign_badge_params_new
    first_step_params = session[:assign_badge_stepper_first_step_params]
    second_step_params = session[:assign_badge_stepper_second_step_params]
    third_step_params = session[:assign_badge_stepper_third_step_params]
    fourth_step_params = session[:assign_badge_stepper_fourth_step_params]

    params = first_step_params.merge(second_step_params).merge(third_step_params).merge(fourth_step_params)
    user_badge_skills_attributes = {}
    params["badge_skill_ids"].each do |badge_skill_id|
      user_badge_skills_attributes.merge!({
        Time.now => {
          badge_skill_id:
        }
      })
    end

    {
      receiver_id: params["receiver_id"],
      sender_id: params["sender_id"],
      organization_id: JSON.parse(params["organization"])["id"],
      organization_type: JSON.parse(params["organization"])["type"],
      project_id: params["project_id"],
      badge_id: params["badge_id"],
      user_badge_skills_attributes:
    }
  end

  def assign_badge_params
    params.require(:user_badge).permit(
      :project_title,
      :project_description,
      :project_id,
      :badge_id,
      :sender_id,
      :receiver_id,
      :organization_type,
      :organization_id,
      :comment,
      documents: [],
      user_badge_skills_attributes: [:badge_skill_id]
    )
  end
end
