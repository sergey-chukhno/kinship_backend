class PartnershipPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      # Users can only see partnerships their organizations are part of
      return scope.none unless user
      
      # Super admin sees all
      return scope.all if user.super_admin?
      
      # Organization superadmins see their partnerships
      company_ids = user.user_company.superadmin.pluck(:company_id)
      school_ids = user.user_schools.superadmin.pluck(:school_id)
      
      scope.joins(:partnership_members)
        .where(
          partnership_members: {
            participant_type: 'Company',
            participant_id: company_ids
          }
        )
        .or(
          scope.joins(:partnership_members)
            .where(
              partnership_members: {
                participant_type: 'School',
                participant_id: school_ids
              }
            )
        )
        .distinct
    end
  end
  
  def index?
    # Any user can view partnerships (filtered by scope)
    true
  end
  
  def show?
    # Can view if user is part of any organization in the partnership
    user_organizations_in_partnership?
  end
  
  def create?
    # Must be superadmin of initiator organization
    return false unless record.initiator
    
    if record.initiator.is_a?(Company)
      user.company_superadmin?(record.initiator)
    elsif record.initiator.is_a?(School)
      user.school_superadmin?(record.initiator)
    else
      false
    end
  end
  
  def new?
    create?
  end
  
  def update?
    # Only superadmin of initiator can update partnership settings
    return false unless record.initiator
    
    if record.initiator.is_a?(Company)
      user.company_superadmin?(record.initiator)
    elsif record.initiator.is_a?(School)
      user.school_superadmin?(record.initiator)
    else
      false
    end
  end
  
  def edit?
    update?
  end
  
  def destroy?
    # Only superadmin of initiator can destroy partnership
    return false unless record.initiator
    
    if record.initiator.is_a?(Company)
      user.company_superadmin?(record.initiator)
    elsif record.initiator.is_a?(School)
      user.school_superadmin?(record.initiator)
    else
      false
    end
  end
  
  def confirm?
    # Only superadmin of initiator can manually confirm
    update?
  end
  
  def reject?
    # Only superadmin of initiator or any member can reject
    user_organizations_in_partnership?
  end
  
  private
  
  def user_organizations_in_partnership?
    return false unless record.partnership_members.any?
    
    # Check if user is superadmin of any participating organization
    participating_companies = record.companies.pluck(:id)
    participating_schools = record.schools.pluck(:id)
    
    user_company_ids = user.user_company.superadmin.pluck(:company_id)
    user_school_ids = user.user_schools.superadmin.pluck(:school_id)
    
    (participating_companies & user_company_ids).any? || 
    (participating_schools & user_school_ids).any?
  end
end

