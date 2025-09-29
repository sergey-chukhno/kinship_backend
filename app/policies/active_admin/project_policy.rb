module ActiveAdmin
  class ProjectPolicy < ActiveAdmin::BasePolicy
    class Scope < ActiveAdmin::BasePolicy::Scope
      def resolve
        scope.all
      end
    end
  end
end
