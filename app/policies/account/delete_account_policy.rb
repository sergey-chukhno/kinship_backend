class Account::DeleteAccountPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  def show?
    user == record
  end

  def new?
    user == record
  end

  def destroy?
    user == record
  end
end
