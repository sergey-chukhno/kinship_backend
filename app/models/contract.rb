# Contract Model
# Polymorphic: Can belong to School, Company, or IndependentTeacher
# Enables badge assignment for organizations and independent teachers
class Contract < ApplicationRecord
  # Polymorphic association (NEW)
  belongs_to :contractable, polymorphic: true, optional: true
  
  # Legacy associations (kept for backward compatibility during migration)
  belongs_to :school, optional: true
  belongs_to :company, optional: true
  
  validates :start_date, presence: true
  validates :active, inclusion: {in: [true, false]}
  validate :exactly_one_contractable_present
  validate :start_date_before_end_date
  validate :end_date_not_expired, if: :active?
  validate :contractable_specific_validations
  validate :only_one_active_contract_per_contractable
  
  scope :active_contracts, -> { 
    where(active: true)
      .where('start_date <= ?', Time.current)
      .where('end_date IS NULL OR end_date >= ?', Time.current)
  }
  
  # Get the actual organization (polymorphic or legacy)
  def organization
    contractable || school || company
  end
  
  # Check if contract is currently valid
  def valid_period?
    return false if start_date > Time.current
    return true if end_date.nil?
    end_date >= Time.current
  end
  
  private
  
  def exactly_one_contractable_present
    # Count using polymorphic OR legacy columns
    present = []
    present << :contractable if contractable_id.present?
    present << :school if school_id.present? && contractable_id.blank?
    present << :company if company_id.present? && contractable_id.blank?
    
    unless present.count == 1
      errors.add(:base, "Le contrat doit appartenir à exactement une entité: école, entreprise ou enseignant indépendant")
    end
  end
  
  def start_date_before_end_date
    return unless end_date && start_date
    return if start_date < end_date
    
    errors.add(:start_date, "La date de début doit être avant la date de fin")
  end
  
  def end_date_not_expired
    return unless end_date
    return if end_date > Time.current
    
    errors.add(:active, "La date de fin de contrat a expiré")
  end
  
  def contractable_specific_validations
    case contractable_type
    when 'School'
      validate_school_contract
    when 'Company'
      validate_company_contract
    when 'IndependentTeacher'
      validate_independent_teacher_contract
    when nil
      # Legacy: validate via school_id or company_id
      validate_school_contract if school_id.present?
      validate_company_contract if company_id.present?
    end
  end
  
  def validate_school_contract
    entity = contractable || school
    return unless entity
    
    unless entity.confirmed?
      errors.add(:contractable, "L'établissement doit être confirmé pour pouvoir signer un contrat")
    end
    
    unless entity.owner?
      errors.add(:contractable, "L'établissement doit avoir un superadmin pour pouvoir signer un contrat")
    end
  end
  
  def validate_company_contract
    entity = contractable || company
    return unless entity
    
    unless entity.confirmed?
      errors.add(:contractable, "L'entreprise doit être confirmée pour pouvoir signer un contrat")
    end
    
    unless entity.owner?
      errors.add(:contractable, "L'entreprise doit avoir un superadmin pour pouvoir signer un contrat")
    end
  end
  
  def validate_independent_teacher_contract
    return unless contractable
    
    unless User.is_teacher_role?(contractable.user&.role)
      errors.add(:contractable, "Le contrat d'enseignant indépendant nécessite un utilisateur avec le rôle 'enseignant'")
    end
    
    unless contractable.active?
      errors.add(:contractable, "L'enseignant indépendant doit avoir un statut actif pour signer un contrat")
    end
  end
  
  def only_one_active_contract_per_contractable
    return unless active?
    
    org = organization
    return unless org
    
    # Check for existing active contract for SAME entity (by type and id)
    existing_query = if contractable.present?
      # Polymorphic: check by contractable_type and contractable_id
      Contract.where(contractable_type: contractable_type, contractable_id: contractable_id, active: true)
              .where.not(id: id)
    elsif school_id.present?
      # Legacy: check by school_id
      Contract.where(school_id: school_id, active: true).where.not(id: id)
    elsif company_id.present?
      # Legacy: check by company_id
      Contract.where(company_id: company_id, active: true).where.not(id: id)
    end
    
    if existing_query&.exists?
      errors.add(:active, "Il ne peut y avoir qu'un seul contrat actif par entité (école/entreprise/enseignant)")
    end
  end
end
