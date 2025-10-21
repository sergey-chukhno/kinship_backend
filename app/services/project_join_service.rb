# Service to handle project join requests with organization membership logic
# Handles both public and private projects, respecting visibility rules
class ProjectJoinService < ApplicationService
  attr_reader :project, :user
  
  def initialize(project:, user:)
    @project = project
    @user = user
  end
  
  def call
    # For PRIVATE projects: User can see it = already org member
    # For PUBLIC projects: Check org membership if required
    
    if project.private?
      # User can see this private project, so they're already org member
      # Just create project member request
      create_project_member
    else
      # Public project - check if org membership required
      handle_public_project
    end
  end
  
  private
  
  def handle_public_project
    required_orgs = project_organizations
    
    if required_orgs.empty?
      # No org requirement - pure public project
      return create_project_member
    end
    
    # Check if user is member of any required organization
    membership_status = check_membership_status(required_orgs)
    
    case membership_status
    when :confirmed
      # User is confirmed member - create project member
      create_project_member
      
    when :pending
      # User has pending membership - wait for approval
      {
        status: :pending_org_approval,
        detail: 'Please wait for your organization membership to be approved before joining this project'
      }
      
    when :not_member
      # User is not member - must join organization first
      {
        status: :org_membership_required,
        detail: 'This project requires membership in one of the following organizations',
        available_organizations: required_orgs.map { |org| 
          {
            id: org.id, 
            name: org.name, 
            type: org.class.name,
            city: org.city
          }
        }
      }
    end
  end
  
  # Get organizations associated with project
  def project_organizations
    orgs = []
    
    # Projects with school levels require school membership
    if project.school_levels.any?
      orgs += project.school_levels.map(&:school).compact.uniq
    end
    
    # Projects with companies require company membership
    if project.companies.any?
      orgs += project.companies
    end
    
    orgs.uniq
  end
  
  # Check user's membership status in required organizations
  def check_membership_status(organizations)
    confirmed_memberships = []
    pending_memberships = []
    
    organizations.each do |org|
      membership = find_membership(org)
      
      if membership
        if membership.confirmed?
          confirmed_memberships << membership
        elsif membership.pending?
          pending_memberships << membership
        end
      end
    end
    
    # Return status based on memberships
    return :confirmed if confirmed_memberships.any?
    return :pending if pending_memberships.any?
    :not_member
  end
  
  # Find user's membership in organization
  def find_membership(organization)
    case organization
    when School
      user.user_schools.find_by(school: organization)
    when Company
      user.user_company.find_by(company: organization)
    end
  end
  
  # Create project member request
  def create_project_member
    project_member = project.project_members.create!(
      user: user,
      status: :pending,  # Requires owner approval
      role: :member      # Default role
    )
    
    # Notify project owner (background job)
    NotifyProjectOwnerForNewParticipationsRequestJob.perform_later(project, user) if defined?(NotifyProjectOwnerForNewParticipationsRequestJob)
    
    {
      status: :success,
      project_member: {
        id: project_member.id,
        status: project_member.status,
        role: project_member.role,
        project_id: project.id,
        user_id: user.id
      }
    }
  end
end

