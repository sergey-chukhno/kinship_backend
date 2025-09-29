class ProjectAdminPanel::BasePolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  def show?
    user_is_admin_of_project?
  end

  def new?
    user_is_admin_of_project?
  end

  def create?
    user_is_admin_of_project?
  end

  def update_team?
    user_is_admin_of_project?
  end

  def edit?
    update?
  end

  def badges_tree?
    true
  end

  def modal_badges_details?
    true
  end

  def update?
    record.can_edit?(user)
  end

  def destroy?
    record.project.owner == user
  end

  def update_confirmation?
    record.project.owner == user || record.project.project_members.where(user: user, admin: true).any?
  end

  def update_admin_status?
    record.project.owner == user || record.project.project_members.where(user: user, admin: true).any?
  end

  private

  def user_is_admin_of_project?
    record.owner == user || record.project_members.where(user: user, admin: true).any?
  end
end
