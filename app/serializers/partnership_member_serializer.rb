# PartnershipMember serializer for API responses
# Handles partnership participants with roles (partner, sponsor, beneficiary)
class PartnershipMemberSerializer < ActiveModel::Serializer
  attributes :id, :member_status, :role_in_partnership, 
             :joined_at, :confirmed_at, :created_at
  
  # Avoid circular reference (PartnershipMember → Partnership → PartnershipMember)
  # belongs_to :partnership - Omitted to prevent infinite loop
  
  # Polymorphic participant (Company or School)
  attribute :participant
  
  # Computed attributes
  
  # Polymorphic participant - simple object format
  def participant
    return nil unless object.participant
    
    {
      id: object.participant_id,
      name: object.participant.name,
      type: object.participant_type,
      city: object.participant.city
    }
  end
  
  def is_sponsor
    object.sponsor?
  end
  
  def is_beneficiary
    object.beneficiary?
  end
  
  def is_partner
    object.partner?
  end
end

