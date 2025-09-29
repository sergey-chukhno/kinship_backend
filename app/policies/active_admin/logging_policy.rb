module ActiveAdmin
  class LoggingPolicy < ActiveAdmin::BasePolicy
    class Scope < ApplicationPolicy::Scope
      # NOTE: Be explicit about which records you allow access to!
      def resolve
        scope.all
      end
    end

    def index?
      user_is_super_admin?
    end

    def show?
      user_is_super_admin?
    end

    def edit?
      false
    end

    def update?
      false
    end

    def new?
      false
    end

    def create?
      false
    end

    def destroy?
      false
    end

    def user_is_super_admin?
      user.super_admin?
    end
  end
end
