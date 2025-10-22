# UserBadge serializer for API responses
# Handles polymorphic organization association (Company or School)
class UserBadgeSerializer < ActiveModel::Serializer
  attributes :id, :created_at, :organization_type, :organization_id
  
  belongs_to :badge
  belongs_to :sender, serializer: UserSerializer
  
  # Polymorphic organization (Company or School) with name
  attribute :organization
  
  def organization
    return nil unless object.organization
    
    {
      id: object.organization_id,
      name: object.organization.name,
      type: object.organization_type
    }
  end
end

