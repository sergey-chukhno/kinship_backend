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
    user.company_admin?(record.company) && !record.owner?
  end

  def update_admin?
    user.company_admin?(record.company) && !record.owner? && record.confirmed?
  end

  def update_can_access_badges?
    user.company_admin?(record.company) && !record.owner? && record.confirmed? && !record.admin?
  end

  def update_create_project?
    user.company_admin?(record.company) && !record.owner? && record.confirmed? && !record.admin?
  end

  def destroy?
    user.company_admin?(record.company) && !record.owner?
  end

  def destroy_sponsor?
    true
  end

  def update_sponsor_confirmation?
    true
  end
end
