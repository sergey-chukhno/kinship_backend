class CompanyAdminPanel::BasePolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  def show?
    user.company_admin?(record) && record.confirmed?
  end

  def new?
    create?
  end

  def create?
    user.company_admin?(record) && record.confirmed?
  end

  def edit?
    update?
  end

  def update?
    user.company_admin?(record) && record.confirmed?
  end

  def update_confirmation?
    user.company_admin?(record.company) && !record.superadmin?
  end

  def update_role?
    current_user_company = user.user_company.find_by(company: record.company)
    return false unless current_user_company&.can_manage_members?
    return false if record.superadmin? && !current_user_company&.superadmin?
    
    record.confirmed?
  end

  def destroy?
    current_user_company = user.user_company.find_by(company: record.company)
    return false unless current_user_company&.can_manage_members?
    return false if record.superadmin? && !current_user_company&.superadmin?
    
    true
  end

  def destroy_sponsor?
    true
  end

  def update_sponsor_confirmation?
    true
  end
end
