class SchoolAdminPanel::BadgesPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    user_school = UserSchool.find_by(user: user, school: record)
    user_school&.can_assign_badges?
  end
end
