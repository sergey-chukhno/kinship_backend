class AssignBadgePolicy < ApplicationPolicy
  def show?
    user.can_give_badges?
  end

  def new?
    create?
  end

  def create?
    user.can_give_badges?
  end
end
