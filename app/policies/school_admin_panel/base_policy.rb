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
    user.school_admin?(record.school) && !record.superadmin?
  end

  def update_school_level?
    user.school_admin?(record.school) && !record.superadmin? && record.confirmed?
  end

  def update_role?
    current_user_school = user.user_schools.find_by(school: record.school)
    return false unless current_user_school&.can_manage_members?
    return false if record.superadmin? && !current_user_school&.superadmin?
    
    record.confirmed?
  end

  def destroy?
    current_user_school = user.user_schools.find_by(school: record.school)
    return false unless current_user_school&.can_manage_members?
    return false if record.superadmin? && !current_user_school&.superadmin?
    
    true
  end

  def destroy_partnership?
    true
  end
end
