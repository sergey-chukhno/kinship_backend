class SchoolAdminPanel::BasePolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  def show?
    user.school_admin?(record) && record.confirmed?
  end

  def new?
    create?
  end

  def create?
    user.school_admin?(record)
  end

  def edit?
    update?
  end

  def update?
    user.school_admin?(record)
  end

  def update_confirmation?
    user.school_admin?(record.school) && !record.owner?
  end

  def update_school_level?
    user.school_admin?(record.school) && !record.owner? && record.confirmed?
  end

  def update_admin?
    user.school_admin?(record.school) && !record.owner? && record.confirmed?
  end

  def update_can_access_badges?
    user.school_admin?(record.school) && !record.owner? && record.confirmed? && !record.admin?
  end

  def destroy?
    user.school_admin?(record.school) && !record.owner?
  end

  def destroy_partnership?
    true
  end
end
