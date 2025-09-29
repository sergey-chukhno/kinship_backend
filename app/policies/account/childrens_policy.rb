module Account
  class ChildrensPolicy < ApplicationPolicy
    class Scope < Scope
      def resolve
        scope.find(user.id).childrens
      end
    end

    def index?
      user.tutor?
    end

    def new?
      create?
    end

    def create?
      true
    end

    def edit?
      update?
    end

    def update?
      record.parent_id == user.id
    end

    def destroy?
      record.parent_id == user.id
    end

    def school_levels?
      true
    end
  end
end
