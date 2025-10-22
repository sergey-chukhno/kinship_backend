# UserCompany serializer for API responses
# Handles company membership with roles from Change #3
class UserCompanySerializer < ActiveModel::Serializer
  attributes :id, :role, :status, :created_at, :confirmed_at
  
  # Avoid circular reference (UserCompany → User → UserCompany / Company → UserCompany)
  # belongs_to :user, :company - Omitted to prevent infinite loop
  # Use user_id and company_id instead
  
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

