class SchoolAdminPanel::BadgesPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    UserSchool.find_by(user: user, school: record).can_access_badges?
  end
end
