# IndependentTeacher serializer for API responses
# Represents independent teachers with their own contracts
class IndependentTeacherSerializer < ActiveModel::Serializer
  attributes :id, :organization_name, :city, :description, :status,
             :created_at, :has_active_contract, :is_active
  
  attribute :teacher
  attribute :current_contract
  
  def has_active_contract
    object.active_contract?
  end
  
  def is_active
    object.active?
  end
  
  def teacher
    {
      id: object.user.id,
      full_name: object.user.full_name,
      email: object.user.email
    }
  end
  
  def current_contract
    return nil unless object.current_contract
    
    contract = object.current_contract
    {
      id: contract.id,
      active: contract.active,
      start_date: contract.start_date,
      end_date: contract.end_date
    }
  end
end

