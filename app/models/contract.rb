class Contract < ApplicationRecord
  # == Schema Information
  #
  # Table name: contracts
  #
  # id          :bigint     not null, primary key
  # school_id   :bigint
  # company_id  :bigint
  # active      :boolean    default(FALSE), not null
  # start_date  :datetime   not null
  # end_date    :datetime
  #

  belongs_to :school, optional: true
  belongs_to :company, optional: true

  validates :start_date, presence: true
  validates :school_id, presence: true, unless: :company_id?
  validates :school_id, absence: true, if: :company_id?
  validates :company_id, presence: true, unless: :school_id?
  validates :company_id, absence: true, if: :school_id?
  validate :start_date_before_end_date
  validate :end_date_not_expired, if: :active?
  validate :school_confirmed, if: :school_id?
  validate :company_confirmed, if: :company_id?
  validate :only_one_active_contract_per_school, if: :active? && :school_id?
  validate :only_one_active_contract_per_company, if: :active? && :company_id?
  validate :school_has_owner, if: :school_id?
  validate :company_has_owner, if: :company_id?

  private

  def start_date_before_end_date
    return unless end_date
    return if start_date < end_date

    errors.add(:start_date, "La date de début doit être avant la date de fin")
  end

  def end_date_not_expired
    return unless end_date
    return if end_date > Time.now

    errors.add(:active, "La date de fin de contrat à expiré")
  end

  def school_confirmed
    return if school&.confirmed?

    errors.add(:school, "L'établissement doit être confirmé pour pouvoir signer un contrat")
  end

  def company_confirmed
    return if company&.confirmed?

    errors.add(:company, "L'association doit être confirmé pour pouvoir signer un contrat")
  end

  def only_one_active_contract_per_school
    return unless active
    return if self.class.where(school_id: school_id, active: true).where.not(id: id).count.zero?

    errors.add(:active, "Il ne peut y avoir qu'un seul contrat actif par établissement")
  end

  def only_one_active_contract_per_company
    return unless active
    return if self.class.where(company_id: company_id, active: true).where.not(id: id).count.zero?

    errors.add(:active, "Il ne peut y avoir qu'un seul contrat actif par association ou entreprise")
  end

  def school_has_owner
    return if school&.owner?

    errors.add(:school, "L'établissement doit avoir un propriétaire pour pouvoir signer un contrat")
  end

  def company_has_owner
    return if company&.owner?

    errors.add(:company, "L'association doit avoir un propriétaire pour pouvoir signer un contrat")
  end
end
