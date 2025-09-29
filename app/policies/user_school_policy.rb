class UserSchoolPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      user.admin? ? scope.all : scope.where(user:)
    end
  end

  def destroy?
    record.user == user || user.admin?
  end
end
