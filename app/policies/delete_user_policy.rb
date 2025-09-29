class DeleteUserPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all.distinct
    end
  end

  def generate_delete_token?
    user == record
  end

  def delete_account?
    user == record
  end
end
