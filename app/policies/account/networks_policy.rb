class Account::NetworksPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
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

  def destroy?
    user == record.user
  end
end
