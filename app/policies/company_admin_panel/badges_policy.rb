class CompanyAdminPanel::BadgesPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    UserCompany.find_by(user: user, company: record).can_access_badges?
  end
end
