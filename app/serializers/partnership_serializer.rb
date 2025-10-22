# Partnership serializer for API responses
# Handles multi-party partnerships from Change #5
class PartnershipSerializer < ActiveModel::Serializer
  attributes :id, :status, :partnership_type, :name, :description,
             :share_members, :share_projects, :has_sponsorship,
             :confirmed_at, :created_at,
             :is_bilateral, :is_multilateral
  
  # Polymorphic initiator (Company or School)
  attribute :initiator
  
  # Partnership members with roles
  has_many :partnership_members, serializer: PartnershipMemberSerializer
  
  # Computed attributes
  
  def is_bilateral
    object.bilateral?
  end
  
  def is_multilateral
    object.multilateral?
  end
  
  # Polymorphic initiator - simple object format
  def initiator
    return nil unless object.initiator
    
    {
      id: object.initiator_id,
      name: object.initiator.name,
      type: object.initiator_type,
      city: object.initiator.city
    }
  end
  
  # Get sponsors (organizations with sponsor role)
  def sponsors
    object.sponsors.map do |org|
      serialize_organization(org)
    end
  end
  
  # Get beneficiaries (organizations with beneficiary role)
  def beneficiaries
    object.beneficiaries.map do |org|
      serialize_organization(org)
    end
  end
  
  # Get partners (organizations with partner role)
  def partners_only
    object.partners_only.map do |org|
      serialize_organization(org)
    end
  end
  
  private
  
  # Helper to serialize organization (Company or School) consistently
  def serialize_organization(org)
    {
      id: org.id,
      name: org.name,
      type: org.class.name,
      city: org.city
    }
  end
end

