class Account::AvailabilitiesPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def edit?
    user == record && !user.teacher?
  end

  def update?
    user == record && !user.teacher?
  end
end
