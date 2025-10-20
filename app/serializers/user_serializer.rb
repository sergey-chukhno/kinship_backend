# User serializer for API responses
# Handles user data serialization with conditional includes and context switching
class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :first_name, :last_name, :full_name,
             :role, :job, :birthday, :certify, :admin, :avatar_url,
             :take_trainee, :propose_workshop, :show_my_skills,
             :contact_email, :confirmed_at
  
  # Conditional associations
  has_many :skills, if: -> { instance_options[:include_skills] }
  has_many :badges_received, 
           serializer: UserBadgeSerializer, 
           if: -> { instance_options[:include_badges] }
  has_one :availability, if: -> { instance_options[:include_availability] }
  
  # Context information for dashboard switching (React multi-dashboard support)
  attribute :available_contexts, if: -> { instance_options[:include_contexts] }
  
  # Computed full name
  def full_name
    "#{object.first_name} #{object.last_name}"
  end
  
  # Avatar URL from ActiveStorage
  def avatar_url
    return nil unless object.avatar.attached?
    Rails.application.routes.url_helpers.rails_blob_url(object.avatar, only_path: false)
  end
  
  # Available contexts for multi-dashboard support
  # Returns which dashboards user can access (user, teacher, schools, companies)
  def available_contexts
    {
      user_dashboard: has_personal_dashboard?,
      teacher_dashboard: object.teacher?,
      schools: serialize_schools,
      companies: serialize_companies
    }
  end
  
  private
  
  # Check if user has personal dashboard access
  # All users have personal dashboard unless explicitly organization-only
  def has_personal_dashboard?
    # Future: could add `organization_only` flag to User model
    true
  end
  
  # Serialize user's schools with roles and permissions
  def serialize_schools
    object.user_schools.where(status: :confirmed).map do |us|
      {
        id: us.school.id,
        name: us.school.name,
        city: us.school.city,
        school_type: us.school.school_type,
        role: us.role,
        permissions: {
          superadmin: us.superadmin?,
          admin: us.admin? || us.superadmin?,
          referent: us.referent?,
          intervenant: us.intervenant?,
          can_manage_members: us.can_manage_members?,
          can_manage_projects: us.can_manage_projects?,
          can_assign_badges: us.can_assign_badges?,
          can_manage_partnerships: us.can_manage_partnerships?,
          can_manage_branches: us.can_manage_branches?
        }
      }
    end
  end
  
  # Serialize user's companies with roles and permissions
  def serialize_companies
    object.user_company.where(status: :confirmed).map do |uc|
      {
        id: uc.company.id,
        name: uc.company.name,
        city: uc.company.city,
        company_type: uc.company.company_type&.name,
        role: uc.role,
        permissions: {
          superadmin: uc.superadmin?,
          admin: uc.admin? || uc.superadmin?,
          referent: uc.referent?,
          intervenant: uc.intervenant?,
          can_manage_members: uc.can_manage_members?,
          can_manage_projects: uc.can_manage_projects?,
          can_assign_badges: uc.can_assign_badges?,
          can_manage_partnerships: uc.can_manage_partnerships?,
          can_manage_branches: uc.can_manage_branches?
        }
      }
    end
  end
end

