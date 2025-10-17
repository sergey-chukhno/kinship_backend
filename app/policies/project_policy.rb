class ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope
        .includes(:project_companies, :companies, :school_levels)
        .where(private: false)
        .or(
          scope
            .includes(:project_companies, :companies, :school_levels)
            .where(private: true, companies: user.user_company.confirmed.pluck(:company_id))
        )
        .or(
          scope
            .includes(:school_levels, :project_companies, :companies)
            .where(private: true, school_levels: {school_id: user.user_schools.confirmed.pluck(:school_id)})
        )
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  def new?
    create?
  end

  def create?
    # available user [Admin user, Teacher user, Basic user if is attached to a contracted company and he is admin of this company]
    user.can_create_project?
  end

  def edit?
    update?
  end

  def update?
    record.owner == user || record.user_is_co_owner?(user)
  end
  
  def destroy?
    # Only primary owner can delete
    record.owner == user
  end
  
  def manage_members?
    record.owner == user || record.user_is_admin_or_co_owner?(user)
  end
  
  def add_co_owner?
    record.owner == user || record.user_is_co_owner?(user)
  end
  
  def remove_co_owner?
    record.owner == user || record.user_is_co_owner?(user)
  end
  
  def close_project?
    record.owner == user || record.user_is_co_owner?(user)
  end
end
