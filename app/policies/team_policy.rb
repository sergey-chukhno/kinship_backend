class TeamPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end

  def edit?
    user == record.project.owner
  end

  def update?
    user == record.project.owner
  end
end
