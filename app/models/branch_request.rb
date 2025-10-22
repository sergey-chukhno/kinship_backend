class BranchRequest < ApplicationRecord
  # Polymorphic associations
  belongs_to :parent, polymorphic: true
  belongs_to :child, polymorphic: true
  belongs_to :initiator, polymorphic: true
  
  # Enums
  enum :status, {pending: 0, confirmed: 1, rejected: 2}, default: :pending
  
  # Validations
  validates :status, presence: true
  validates :parent_id, uniqueness: {scope: [:parent_type, :child_id, :child_type], 
                                      message: "Une demande existe déjà pour cette relation"}
  validate :parent_and_child_must_differ
  validate :child_not_already_a_branch
  validate :parent_is_not_a_branch
  validate :same_type_only  # Companies branch companies, schools branch schools
  
  # Callbacks
  after_update :apply_branch_relationship, if: :saved_change_to_status?
  
  # Scopes
  scope :for_organization, ->(org) {
    where("(parent_type = ? AND parent_id = ?) OR (child_type = ? AND child_id = ?)", 
          org.class.name, org.id, org.class.name, org.id)
  }
  
  # Instance methods
  def confirm!
    update!(status: :confirmed, confirmed_at: Time.current)
  end
  
  def reject!
    update!(status: :rejected)
  end
  
  def recipient
    initiator == parent ? child : parent
  end
  
  def initiated_by_parent?
    initiator == parent
  end
  
  def initiated_by_child?
    initiator == child
  end
  
  private
  
  def apply_branch_relationship
    return unless confirmed?
    
    # Set the parent-child relationship
    if child_type == 'Company'
      child.update!(parent_company: parent)
    elsif child_type == 'School'
      child.update!(parent_school: parent)
    end
    
    # TODO: Send notification email when BranchMailer is created
    # BranchMailer.notify_branch_confirmed(self).deliver_later
  end
  
  def parent_and_child_must_differ
    return unless parent_id.present? && child_id.present?
    
    if parent_type == child_type && parent_id == child_id
      errors.add(:base, "L'organisation ne peut pas devenir sa propre filiale")
    end
  end
  
  def child_not_already_a_branch
    return unless child.present?
    
    if child_type == 'Company' && child.parent_company_id.present?
      errors.add(:child, "est déjà une filiale d'une autre entreprise")
    elsif child_type == 'School' && child.parent_school_id.present?
      errors.add(:child, "est déjà une annexe d'un autre établissement")
    end
  end
  
  def parent_is_not_a_branch
    return unless parent.present?
    
    if parent_type == 'Company' && parent.parent_company_id.present?
      errors.add(:parent, "ne peut pas avoir de filiales car c'est déjà une filiale")
    elsif parent_type == 'School' && parent.parent_school_id.present?
      errors.add(:parent, "ne peut pas avoir d'annexes car c'est déjà une annexe")
    end
  end
  
  def same_type_only
    return unless parent_type.present? && child_type.present?
    
    if parent_type != child_type
      errors.add(:base, "Le parent et l'enfant doivent être du même type (Company-Company ou School-School)")
    end
  end
end
