class AssignBadgeStepper::FirstStepController < ApplicationController
  def new
    @assign_badge = AssignBadgeStepper::FirstStep.new(assign_badge_stepper_first_step_params_new)
    @organizations = set_organizations_collection

    authorize @assign_badge, policy_class: AssignBadgePolicy
  end

  def create
    @assign_badge = AssignBadgeStepper::FirstStep.new(assign_badge_stepper_first_step_params)
    @organizations = set_organizations_collection
    set_organization_values

    authorize @assign_badge, policy_class: AssignBadgePolicy

    if @assign_badge.valid?
      store_assign_badge_stepper_first_step_params
      redirect_to new_assign_badge_stepper_second_step_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_organizations_collection
    schools = UserSchool
      .includes(:school)
      .where(user: current_user, can_access_badges: true)
      .map(&:school)
      .map { |school| [school.full_name, {id: school.id, type: "School"}.to_json] }
    companies = UserCompany
      .includes(:company)
      .where(user: current_user, can_access_badges: true)
      .map(&:company)
      .map { |company| [company.full_name, {id: company.id, type: "Company"}.to_json] }

    schools + companies
  end

  def set_organization_values
    return if @assign_badge.organization.blank?

    organization_value = JSON.parse(@assign_badge.organization)
    @assign_badge.organization_id = organization_value["id"]
    @assign_badge.organization_type = organization_value["type"]
  end

  def assign_badge_stepper_first_step_params_new
    return {sender_id: current_user.id, receiver_id: params[:receiver_id]} if params[:receiver_id].present?

    session[:assign_badge_stepper_first_step_params]
  end

  def assign_badge_stepper_first_step_params
    params.require(:assign_badge_stepper_first_step).permit(:receiver_id, :sender_id, :organization)
  end

  def store_assign_badge_stepper_first_step_params
    session[:assign_badge_stepper_first_step_params] = assign_badge_stepper_first_step_params.to_h
  end
end
