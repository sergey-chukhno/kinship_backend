# ProjectMember serializer for API responses
# Handles project participation with roles (member, admin, co_owner from Change #6)
class ProjectMemberSerializer < ActiveModel::Serializer
  attributes :id, :status, :role, :created_at, :confirmed_at, :is_co_owner, :is_admin
  
  # Avoid circular references
  # belongs_to :user - Would cause ProjectMember → User → many associations
  # belongs_to :project - Would cause ProjectMember → Project → ProjectMember
  # belongs_to :team - Would cause ProjectMember → Team → ProjectMember
  # Use simple user object instead
  attribute :user
  attribute :team
  
  # Computed attributes
  def is_co_owner
    object.co_owner?
  end
  
  def is_admin
    object.admin?
  end
  
  def has_team
    object.team_id.present?
  end
  
  # Simple user object (avoid circular reference)
  def user
    return nil unless object.user
    
    {
      id: object.user.id,
      first_name: object.user.first_name,
      last_name: object.user.last_name,
      full_name: object.user.full_name,
      email: object.user.email,
      role: object.user.role,
      avatar_url: object.user.avatar.attached? ? 
        Rails.application.routes.url_helpers.rails_blob_url(object.user.avatar, only_path: false) : nil
    }
  end
  
  # Simple team object (avoid circular reference)
  def team
    return nil unless object.team
    
    {
      id: object.team.id,
      title: object.team.title,
      description: object.team.description
    }
  end
end

