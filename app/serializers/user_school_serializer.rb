# UserSchool serializer for API responses
# Handles school membership with roles from Change #3
class UserSchoolSerializer < ActiveModel::Serializer
  attributes :id, :role, :status, :created_at, :confirmed_at
  
  # Avoid circular reference (UserSchool → User → UserSchool / School → UserSchool)
  # belongs_to :user, :school - Omitted to prevent infinite loop
  # Use user_id and school_id instead
  has_many :school_levels, serializer: SchoolLevelSerializer
  
  # Permissions from Change #3: Member roles
  attribute :permissions
  
  def permissions
    {
      superadmin: object.superadmin?,
      admin: object.admin? || object.superadmin?,
      referent: object.referent?,
      intervenant: object.intervenant?,
      can_manage_members: object.can_manage_members?,
      can_manage_projects: object.can_manage_projects?,
      can_assign_badges: object.can_assign_badges?,
      can_manage_partnerships: object.can_manage_partnerships?,
      can_manage_branches: object.can_manage_branches?
    }
  end
end

