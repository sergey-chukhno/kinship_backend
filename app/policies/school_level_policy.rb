class SchoolLevelPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      # Users see classes they're assigned to OR classes from their schools
      teacher_classes = User.is_teacher_role?(user.role) ? SchoolLevel.for_teacher(user) : SchoolLevel.none
      school_classes = SchoolLevel.joins(:school).merge(user.schools.where(user_schools: {status: :confirmed}))
      
      teacher_classes.or(school_classes).distinct
    end
  end
  
  # Teacher permissions
  def teacher_can_view?
    # Teacher can view if assigned OR if member of the school
    record.teacher_assigned?(user) || 
      (record.school.present? && user.user_schools.exists?(school: record.school, status: :confirmed))
  end
  
  def teacher_can_manage?
    # Teacher can manage if they're assigned to the class
    record.teacher_assigned?(user)
  end
  
  def transfer?
    # Only creator can transfer AND must be member of target school
    return false unless record.created_by?(user)
    return false unless record.independent?
    
    # User must have at least one confirmed school membership to transfer to
    user.user_schools.exists?(status: :confirmed)
  end
  
  # School permissions
  def school_can_view?
    # Must be member of the school (any role)
    record.school.present? && 
      user.user_schools.exists?(school: record.school, status: :confirmed)
  end
  
  def school_can_manage?
    # Must be admin/superadmin of the school
    record.school.present? && 
      user.user_schools.exists?(
        school: record.school, 
        role: [:admin, :superadmin],
        status: :confirmed
      )
  end
  
  def assign_teacher?
    # Must be admin/superadmin of the school
    school_can_manage?
  end
  
  def remove_teacher?
    # Must be admin/superadmin of the school
    # Cannot remove creator
    school_can_manage?
  end
  
  def create?
    # Teachers can create independent classes
    # School admins can create school classes
    User.is_teacher_role?(user.role) || school_can_manage?
  end
  
  def update?
    # Teacher can update if assigned OR school admin can update
    teacher_can_manage? || school_can_manage?
  end
  
  def destroy?
    # Only school admin can delete school classes
    # Only creator can delete independent classes
    if record.independent?
      record.created_by?(user)
    else
      school_can_manage?
    end
  end
end
