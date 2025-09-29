class AssignBadgeStepper::SuccessStepController < ApplicationController
  def show
    @assign_badge = UserBadge.find(params[:id])
    authorize @assign_badge, policy_class: AssignBadgePolicy
  end
end
