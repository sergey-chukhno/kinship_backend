class BranchRequestPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      # Users can see branch requests for organizations they're superadmin of
      user_company_ids = user.user_company.where(role: :superadmin).pluck(:company_id)
      user_school_ids = user.user_schools.where(role: :superadmin).pluck(:school_id)
      
      scope.where(
        "(parent_type = 'Company' AND parent_id IN (?)) OR " \
        "(child_type = 'Company' AND child_id IN (?)) OR " \
        "(parent_type = 'School' AND parent_id IN (?)) OR " \
        "(child_type = 'School' AND child_id IN (?))",
        user_company_ids, user_company_ids, user_school_ids, user_school_ids
      )
    end
  end
  
  def create?
    # Must be superadmin of either parent or child
    user_is_superadmin_of_parent? || user_is_superadmin_of_child?
  end
  
  def show?
    # Must be superadmin of parent or child
    user_is_superadmin_of_parent? || user_is_superadmin_of_child?
  end
  
  def confirm?
    # Must be superadmin of the recipient organization (not the initiator)
    record.pending? && user_is_superadmin_of_recipient?
  end
  
  def reject?
    # Must be superadmin of the recipient organization (not the initiator)
    record.pending? && user_is_superadmin_of_recipient?
  end
  
  def destroy?
    # Can cancel if superadmin of initiator and still pending
    record.pending? && user_is_superadmin_of_initiator?
  end
  
  private
  
  def user_is_superadmin_of_parent?
    if record.parent_type == 'Company'
      user.user_company.exists?(company: record.parent, role: :superadmin)
    elsif record.parent_type == 'School'
      user.user_schools.exists?(school: record.parent, role: :superadmin)
    else
      false
    end
  end
  
  def user_is_superadmin_of_child?
    if record.child_type == 'Company'
      user.user_company.exists?(company: record.child, role: :superadmin)
    elsif record.child_type == 'School'
      user.user_schools.exists?(school: record.child, role: :superadmin)
    else
      false
    end
  end
  
  def user_is_superadmin_of_recipient?
    recipient = record.recipient
    
    if recipient.class.name == 'Company'
      user.user_company.exists?(company: recipient, role: :superadmin)
    elsif recipient.class.name == 'School'
      user.user_schools.exists?(school: recipient, role: :superadmin)
    else
      false
    end
  end
  
  def user_is_superadmin_of_initiator?
    if record.initiator.class.name == 'Company'
      user.user_company.exists?(company: record.initiator, role: :superadmin)
    elsif record.initiator.class.name == 'School'
      user.user_schools.exists?(school: record.initiator, role: :superadmin)
    else
      false
    end
  end
end

