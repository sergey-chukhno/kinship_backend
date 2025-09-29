module ActiveAdmin
  class BasePolicy < ApplicationPolicy
    class Scope < ApplicationPolicy::Scope
      # NOTE: Be explicit about which records you allow access to!
      def resolve
        scope.all
      end
    end

    def index?
      is_admin?(user)
    end

    def show?
      is_admin?(user)
    end

    def edit?
      update?
    end

    def update?
      is_admin?(user)
    end

    def new?
      create?
    end

    def create?
      is_admin?(user)
    end

    def destroy?
      is_admin?(user)
    end

    private

    def is_admin?(user)
      user.admin
    end
  end
end
