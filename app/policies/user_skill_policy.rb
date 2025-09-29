class UserSkillPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def update?
    p record
    p user
    p "-------------------"
    p record.user == user || record.user.parent == user
    record.user == user || record.user.parent == user
  end
end
