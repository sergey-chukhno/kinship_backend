class PartnershipMemberPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      # Users can only see partnership members from their partnerships
      return scope.none unless user
      
      # Super admin sees all
      return scope.all if user.super_admin?
      
      # Get partnerships user is part of
      company_ids = user.user_company.superadmin.pluck(:company_id)
      school_ids = user.user_schools.superadmin.pluck(:school_id)
      
      partnership_ids = Partnership.joins(:partnership_members)
        .where(
          partnership_members: {
            participant_type: 'Company',
            participant_id: company_ids
          }
        )
        .or(
          Partnership.joins(:partnership_members)
            .where(
              partnership_members: {
                participant_type: 'School',
                participant_id: school_ids
              }
            )
        )
        .distinct
        .pluck(:id)
      
      scope.where(partnership_id: partnership_ids)
    end
  end
  
  def show?
    # Can view if user is superadmin of any organization in the partnership
    user_in_partnership?
  end
  
  def create?
    # Only initiator superadmin can add new members
    return false unless record.partnership
    
    partnership = record.partnership
    return false unless partnership.initiator
    
    if partnership.initiator.is_a?(Company)
      user.company_superadmin?(partnership.initiator)
    elsif partnership.initiator.is_a?(School)
      user.school_superadmin?(partnership.initiator)
    else
      false
    end
  end
  
  def update?
    # Members can update their own status (confirm/decline)
    # Initiator can update member roles
    user_is_member_organization? || initiator_superadmin?
  end
  
  def destroy?
    # Only initiator superadmin can remove members
    initiator_superadmin?
  end
  
  def confirm?
    # Member organization superadmin can confirm their participation
    user_is_member_organization?
  end
  
  def decline?
    # Member organization superadmin can decline their participation
    user_is_member_organization?
  end
  
  private
  
  def user_in_partnership?
    return false unless record.partnership
    
    participating_companies = record.partnership.companies.pluck(:id)
    participating_schools = record.partnership.schools.pluck(:id)
    
    user_company_ids = user.user_company.superadmin.pluck(:company_id)
    user_school_ids = user.user_schools.superadmin.pluck(:school_id)
    
    (participating_companies & user_company_ids).any? || 
    (participating_schools & user_school_ids).any?
  end
  
  def user_is_member_organization?
    return false unless record.participant
    
    if record.participant.is_a?(Company)
      user.company_superadmin?(record.participant)
    elsif record.participant.is_a?(School)
      user.school_superadmin?(record.participant)
    else
      false
    end
  end
  
  def initiator_superadmin?
    return false unless record.partnership&.initiator
    
    initiator = record.partnership.initiator
    if initiator.is_a?(Company)
      user.company_superadmin?(initiator)
    elsif initiator.is_a?(School)
      user.school_superadmin?(initiator)
    else
      false
    end
  end
end

