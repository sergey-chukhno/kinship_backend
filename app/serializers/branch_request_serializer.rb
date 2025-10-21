# BranchRequest serializer for API responses
# Handles branch requests from Change #7: Branch System
class BranchRequestSerializer < ActiveModel::Serializer
  attributes :id, :status, :share_members, :created_at, :confirmed_at,
             :parent_initiated, :child_initiated
  
  # Polymorphic associations - simple object format
  attribute :parent
  attribute :child
  attribute :initiator
  
  # Computed attributes
  
  # Parent organization (Company or School)
  def parent
    return nil unless object.parent
    
    {
      id: object.parent_id,
      name: object.parent.name,
      type: object.parent_type,
      city: object.parent.city
    }
  end
  
  # Child organization (Company or School)
  def child
    return nil unless object.child
    
    {
      id: object.child_id,
      name: object.child.name,
      type: object.child_type,
      city: object.child.city
    }
  end
  
  # Initiator (who created the branch request)
  def initiator
    return nil unless object.initiator
    
    {
      id: object.initiator_id,
      type: object.initiator_type
    }
  end
  
  # Check who initiated
  def parent_initiated
    object.parent_initiated?
  end
  
  def child_initiated
    object.child_initiated?
  end
end

