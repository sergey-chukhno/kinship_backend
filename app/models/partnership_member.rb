class PartnershipMember < ApplicationRecord
  belongs_to :partnership
  belongs_to :participant, polymorphic: true
  
  enum :member_status, {pending: 0, confirmed: 1, declined: 2}, default: :pending
  enum :role_in_partnership, {partner: 0, sponsor: 1, beneficiary: 2}, default: :partner
  
  validates :participant_id, uniqueness: {scope: [:participant_type, :partnership_id]}
  validates :member_status, :role_in_partnership, presence: true
  
  before_create :set_joined_at
  after_update :check_partnership_full_confirmation, if: -> { saved_change_to_member_status? && confirmed? }
  after_update :set_confirmed_at, if: -> { saved_change_to_member_status? && confirmed? }
  
  # Scopes
  scope :confirmed, -> { where(member_status: :confirmed) }
  scope :pending, -> { where(member_status: :pending) }
  scope :declined, -> { where(member_status: :declined) }
  
  # Business logic
  def confirm!
    update!(member_status: :confirmed, confirmed_at: Time.current)
  end
  
  def decline!
    transaction do
      update!(member_status: :declined)
      partnership.update!(status: :rejected) if partnership.pending?
    end
  end
  
  def organization_name
    participant.respond_to?(:name) ? participant.name : participant.to_s
  end
  
  def is_sponsor?
    sponsor?
  end
  
  def is_beneficiary?
    beneficiary?
  end
  
  def is_partner?
    partner?
  end
  
  private
  
  def set_joined_at
    self.joined_at ||= Time.current
  end
  
  def set_confirmed_at
    self.confirmed_at = Time.current
  end
  
  def check_partnership_full_confirmation
    # Auto-confirm partnership if all members confirmed
    return unless partnership.pending?
    return unless partnership.partnership_members.reload.all?(&:confirmed?)
    
    partnership.confirm!
  end
end
