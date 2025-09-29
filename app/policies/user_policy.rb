class UserPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end

  def index?
    true
  end

  def new?
    true
  end

  def create?
    record.parent == user
  end

  def edit?
    record.parent == user || record == user
  end

  def update?
    record.parent == user || record == user
  end

  def update_certify?
    user.admin? || (user.teacher? && user.certify?)
  end
end
