class ProjectMemberPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  def new?
    create?
  end

  def create?
    # available user is [User who is not the owner of the project and is not already a member of the project]
    record.project.owner != user && !record.project.project_members.exists?(user: user)
  end
end
