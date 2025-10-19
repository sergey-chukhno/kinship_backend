class CompaniesPolicy < ApplicationPolicy
  def new?
    create?
  end

  def create?
    user == record && !user.teacher?
  end
  
  # Branch management (Change #4)
  def manage_branches?
    # Must be superadmin of the company
    return false unless record.is_a?(Company)
    user.user_company.exists?(company: record, role: :superadmin)
  end
  
  def detach_branch?
    # Must be superadmin of parent company
    return false unless record.is_a?(Company) && record.parent_company.present?
    user.user_company.exists?(company: record.parent_company, role: :superadmin)
  end
  
  def detach_from_parent?
    # Must be superadmin of the company (child)
    manage_branches?
  end
end
