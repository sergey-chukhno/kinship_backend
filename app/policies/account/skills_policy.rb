class Account::SkillsPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def edit?
    user == record
  end

  def update?
    user == record
  end
end
