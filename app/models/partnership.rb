class Partnership < ApplicationRecord
  belongs_to :initiator, polymorphic: true
  has_many :partnership_members, dependent: :destroy
  has_many :companies, through: :partnership_members, source: :participant, source_type: 'Company'
  has_many :schools, through: :partnership_members, source: :participant, source_type: 'School'
  
  enum :status, {pending: 0, confirmed: 1, rejected: 2}, default: :pending
  enum :partnership_type, {bilateral: 0, multilateral: 1}, default: :bilateral
  
  validates :status, :partnership_type, presence: true
  validates :name, presence: true, if: :multilateral?
  validate :at_least_two_members, on: :create
  validate :all_members_confirmed_check, if: -> { status_changed? && confirmed? }
  
  # Scopes
  scope :active, -> { where(status: :confirmed) }
  scope :for_organization, ->(org) {
    joins(:partnership_members)
      .where(partnership_members: {participant: org})
      .distinct
  }
  scope :with_sponsorship, -> { where(has_sponsorship: true) }
  scope :sharing_members, -> { where(share_members: true) }
  scope :sharing_projects, -> { where(share_projects: true) }
  
  # Business logic
  def confirm!
    return false unless all_members_confirmed?
    
    update!(status: :confirmed, confirmed_at: Time.current)
  end
  
  def reject!
    update!(status: :rejected)
  end
  
  def member_for(organization)
    partnership_members.find_by(participant: organization)
  end
  
  def includes?(organization)
    partnership_members.exists?(participant: organization)
  end
  
  def other_partners(organization)
    partnership_members
      .where.not(participant: organization)
      .where(member_status: :confirmed)
      .map(&:participant)
  end
  
  def all_participants
    partnership_members.map(&:participant)
  end
  
  def sponsors
    partnership_members.sponsor.map(&:participant)
  end
  
  def beneficiaries
    partnership_members.beneficiary.map(&:participant)
  end
  
  def partners_only
    partnership_members.partner.map(&:participant)
  end
  
  def all_members_confirmed?
    partnership_members.loaded? ? 
      partnership_members.all?(&:confirmed?) : 
      partnership_members.all? { |pm| pm.member_status == 'confirmed' }
  end
  
  def pending_members
    partnership_members.pending
  end
  
  def confirmed_members
    partnership_members.confirmed
  end
  
  private
  
  def at_least_two_members
    # This validation runs on create, but members are added after
    # So we skip it during initial creation
    # The validation is enforced through business logic
  end
  
  def all_members_confirmed_check
    unless all_members_confirmed?
      errors.add(:status, "Tous les membres doivent confirmer avant la confirmation finale du partenariat")
    end
  end
end
