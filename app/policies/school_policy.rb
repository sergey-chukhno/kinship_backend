class SchoolPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    true
  end

  def new?
    create?
  end

  def create?
    user == record && user.teacher?
  end
  
  # Branch management (Change #4)
  def manage_branches?
    # Must be superadmin of the school
    return false unless record.is_a?(School)
    user.user_schools.exists?(school: record, role: :superadmin)
  end
  
  def detach_branch?
    # Must be superadmin of parent school
    return false unless record.is_a?(School) && record.parent_school.present?
    user.user_schools.exists?(school: record.parent_school, role: :superadmin)
  end
  
  def detach_from_parent?
    # Must be superadmin of the school (child)
    manage_branches?
  end
end
