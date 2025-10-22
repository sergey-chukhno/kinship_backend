class CompanyAdminPanel::BadgesPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    user_company = UserCompany.find_by(user: user, company: record)
    user_company&.can_assign_badges?
  end
end
