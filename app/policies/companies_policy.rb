class CompaniesPolicy < ApplicationPolicy
  def new?
    create?
  end

  def create?
    user == record && !user.teacher?
  end
end
