# Team serializer for API responses
class TeamSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :created_at, :members_count
  
  # Avoid circular references
  # belongs_to :project - Would cause Team → Project → Team
  # has_many :project_members - Would cause Team → ProjectMember → User → many associations
  # Use members_count instead
  
  # Computed attribute
  def members_count
    object.team_members.count
  end
end

