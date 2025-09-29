class SchoolAdminPanel::BadgesController < ApplicationController
  def index
    @school = authorize School.find(params[:id]), policy_class: SchoolAdminPanel::BadgesPolicy
    @badges = policy_scope(Badge, policy_scope_class: SchoolAdminPanel::BadgesPolicy::Scope)
  end
end
