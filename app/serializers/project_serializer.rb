# Project serializer for API responses
# Integrates with partnerships (Change #7) and co-owners (Change #6)
class ProjectSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :status, :participants_number,
             :start_date, :end_date, :created_at, :updated_at,
             :main_picture_url, :is_partner_project, :partnership_id,
             :members_count, :teams_count, :company_ids, :school_level_ids
  
  # Associations (balanced to prevent excessive circular references)
  belongs_to :owner, serializer: UserSerializer
  has_many :skills, serializer: SkillSerializer
  has_many :tags, serializer: TagSerializer
  has_many :teams, serializer: TeamSerializer
  has_many :school_levels, serializer: SchoolLevelSerializer
  # Avoid deep nesting:
  # has_many :companies - Would nest deeply (Project → Company → Projects)
  # has_many :project_members - Would nest deeply (Project → ProjectMember → User → Projects)
  # belongs_to :partnership - Would nest deeply (Project → Partnership → PartnershipMembers → Companies/Schools)
  # Use computed attributes and counts instead
  
  # Co-owners from Change #6
  attribute :co_owners
  
  # Computed attributes
  def main_picture_url
    return nil unless object.main_picture.attached?
    Rails.application.routes.url_helpers.rails_blob_url(object.main_picture, only_path: false)
  end
  
  def is_partner_project
    object.partnership_id.present?
  end
  
  # Co-owners from Change #6: Project co-owners
  def co_owners
    object.project_members.where(role: :co_owner).map do |pm|
      {
        id: pm.user.id,
        first_name: pm.user.first_name,
        last_name: pm.user.last_name,
        full_name: pm.user.full_name,
        email: pm.user.email,
        avatar_url: pm.user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(pm.user.avatar, only_path: false) : nil
      }
    end
  end
  
  def members_count
    object.project_members.confirmed.count
  end
  
  def teams_count
    object.teams.count
  end
end

