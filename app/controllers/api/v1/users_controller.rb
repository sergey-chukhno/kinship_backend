# Users API controller for User Dashboard
# Handles profile management, projects, badges, organizations, network, skills, and availability
class Api::V1::UsersController < Api::V1::BaseController
  include Pagy::Backend
  
  # PATCH /api/v1/users/me
  # Update current user's profile
  def update
    if current_user.update(user_params)
      render json: current_user, serializer: UserSerializer
    else
      render json: { 
        error: 'Validation Failed',
        details: current_user.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  # GET /api/v1/users/me/projects
  # Get user's projects (owned + participating) - NOT all org projects
  def my_projects
    # ONLY projects where user is owner OR participant (NOT all org projects)
    @projects = Project.left_joins(:project_members)
                      .where('projects.owner_id = ? OR (project_members.user_id = ? AND project_members.status = ?)', 
                             current_user.id, current_user.id, ProjectMember.statuses[:confirmed])
                      .distinct
                      .includes(:owner, :skills, :tags, :teams, :school_levels)
    
    # Apply filters
    @projects = @projects.where(status: params[:status]) if params[:status].present?
    @projects = filter_by_company(@projects) if params[:by_company].present?
    @projects = filter_by_school(@projects) if params[:by_school].present?
    @projects = filter_by_role(@projects) if params[:by_role].present?
    @projects = filter_by_dates(@projects) if date_params_present?
    
    @pagy, @projects = pagy(@projects.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: ActiveModelSerializers::SerializableResource.new(@projects, each_serializer: ProjectSerializer).as_json,
      meta: pagination_meta(@pagy)
    }
  end
  
  # GET /api/v1/users/me/badges
  # Get user's received badges with enhanced filtering
  def my_badges
    @badges = current_user.badges_received.includes(:badge, :sender, :organization)
    
    # Enhanced filters
    @badges = @badges.joins(:badge).where(badges: {series: params[:series]}) if params[:series].present?
    @badges = @badges.joins(:badge).where(badges: {level: params[:level]}) if params[:level].present?
    @badges = @badges.where(organization_type: params[:organization_type]) if params[:organization_type].present?
    @badges = @badges.where(organization_id: params[:organization_id]) if params[:organization_id].present?
    
    # Note: project_id filter would require additional badge-project linkage
    # For now, filtering by organization covers most use cases
    
    @pagy, @badges = pagy(@badges.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: ActiveModelSerializers::SerializableResource.new(@badges, each_serializer: UserBadgeSerializer).as_json,
      meta: pagination_meta(@pagy)
    }
  end
  
  # GET /api/v1/users/me/organizations
  # Get user's schools and companies with role/permissions
  def my_organizations
    schools = current_user.user_schools.includes(school: :logo_attachment)
    companies = current_user.user_company.includes(company: [:logo_attachment, :company_type])
    
    # Apply filters
    schools = schools.where(status: params[:status]) if params[:status].present?
    schools = schools.where(role: params[:role]) if params[:role].present?
    companies = companies.where(status: params[:status]) if params[:status].present?
    companies = companies.where(role: params[:role]) if params[:role].present?
    
    # Filter by type
    case params[:type]
    when 'School'
      companies = []
    when 'Company'
      schools = []
    end
    
    render json: {
      data: {
        schools: schools.map { |us| serialize_user_school(us) },
        companies: companies.map { |uc| serialize_user_company(uc) }
      },
      meta: {
        schools_count: schools.count,
        companies_count: companies.count,
        total_organizations: schools.count + companies.count
      }
    }
  end
  
  # GET /api/v1/users/me/network
  # Get network members respecting branch & partnership visibility rules
  def my_network
    # Calculate visible organizations (respects branches & partnerships)
    visible_orgs = calculate_visible_organizations
    
    # Get users from visible organizations
    @users = User.distinct
                .joins("LEFT JOIN user_schools ON users.id = user_schools.user_id")
                .joins("LEFT JOIN user_companies ON users.id = user_companies.user_id")
                .where(
                  "(user_schools.school_id IN (?) AND user_schools.status = ?) OR 
                   (user_companies.company_id IN (?) AND user_companies.status = ?)",
                  visible_orgs[:schools],
                  UserSchool.statuses[:confirmed],
                  visible_orgs[:companies],
                  UserCompany.statuses[:confirmed]
                )
                .where.not(id: current_user.id)
    
    # Apply filters
    @users = @users.where(role: params[:role]) if params[:role].present?
    @users = filter_by_skills(@users) if params[:has_skills].present?
    @users = search_users(@users) if params[:search].present?
    
    # Filter by specific organization
    if params[:organization_id].present? && params[:organization_type].present?
      case params[:organization_type]
      when 'School'
        @users = @users.where(user_schools: {school_id: params[:organization_id]})
      when 'Company'
        @users = @users.where(user_companies: {company_id: params[:organization_id]})
      end
    end
    
    @pagy, @users = pagy(@users, items: params[:per_page] || 12)
    
    render json: {
      data: @users.map { |user| serialize_network_user(user) },
      meta: pagination_meta(@pagy)
    }
  end
  
  # PATCH /api/v1/users/me/skills
  # Update user's skills and sub-skills
  def update_skills
    current_user.skill_ids = params[:skill_ids] if params[:skill_ids]
    current_user.sub_skill_ids = params[:sub_skill_ids] if params[:sub_skill_ids]
    
    if current_user.save
      render json: {
        skills: ActiveModelSerializers::SerializableResource.new(
          current_user.skills.includes(:sub_skills),
          each_serializer: SkillSerializer
        ).as_json
      }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/users/me/availability
  # Update user's availability
  def update_availability
    if current_user.availability
      current_user.availability.update(availability_params)
    else
      current_user.create_availability(availability_params)
    end
    
    if current_user.availability.persisted? && current_user.availability.valid?
      render json: current_user.availability, serializer: AvailabilitySerializer
    else
      render json: { 
        error: 'Validation Failed',
        details: current_user.availability.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :job, :birthday, :contact_email,
      :take_trainee, :propose_workshop, :show_my_skills,
      skill_ids: [], sub_skill_ids: []
    )
  end
  
  def availability_params
    params.require(:availability).permit(
      :monday, :tuesday, :wednesday, :thursday, :friday, :other
    )
  end
  
  # Filter projects by company
  def filter_by_company(projects)
    projects.joins(:project_companies).where(project_companies: {company_id: params[:by_company]})
  end
  
  # Filter projects by school
  def filter_by_school(projects)
    projects.joins(project_school_levels: :school_level)
            .where(school_levels: {school_id: params[:by_school]})
  end
  
  # Filter projects by user's role in project
  def filter_by_role(projects)
    case params[:by_role]
    when 'owner'
      projects.where(owner: current_user)
    when 'co_owner'
      projects.joins(:project_members).where(project_members: {user: current_user, role: :co_owner})
    when 'admin'
      projects.joins(:project_members).where(project_members: {user: current_user, role: :admin})
    when 'member'
      projects.joins(:project_members).where(project_members: {user: current_user, role: :member})
    else
      projects
    end
  end
  
  # Filter projects by dates
  def filter_by_dates(projects)
    projects = projects.where('start_date >= ?', params[:start_date_from]) if params[:start_date_from]
    projects = projects.where('start_date <= ?', params[:start_date_to]) if params[:start_date_to]
    projects = projects.where('end_date >= ?', params[:end_date_from]) if params[:end_date_from]
    projects = projects.where('end_date <= ?', params[:end_date_to]) if params[:end_date_to]
    projects
  end
  
  def date_params_present?
    params[:start_date_from] || params[:start_date_to] || params[:end_date_from] || params[:end_date_to]
  end
  
  # Filter users by skills
  def filter_by_skills(users)
    skill_ids = params[:has_skills].split(',').map(&:to_i)
    users.joins(:user_skills).where(user_skills: {skill_id: skill_ids})
  end
  
  # Search users by name or email
  def search_users(users)
    users.where(
      "first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?", 
      "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"
    )
  end
  
  # Calculate visible organizations respecting branch & partnership rules
  def calculate_visible_organizations
    visible = { schools: [], companies: [] }
    
    # Step 1: Add my direct organizations
    my_schools = current_user.user_schools.confirmed.includes(:school)
    my_companies = current_user.user_company.confirmed.includes(:company)
    
    visible[:schools] += my_schools.pluck(:school_id)
    visible[:companies] += my_companies.pluck(:company_id)
    
    # Step 2: Add branch members (if parent shares)
    my_schools.each do |us|
      school = us.school
      
      # Only if I'm in PARENT school that shares with branches
      if school.parent_school_id.nil? && school.share_members_with_branches?
        visible[:schools] += school.branch_schools.pluck(:id)
      end
      # Note: If I'm in BRANCH, I don't see parent (no upward visibility)
    end
    
    my_companies.each do |uc|
      company = uc.company
      
      # Only if I'm in PARENT company that shares with branches
      if company.parent_company_id.nil? && company.share_members_with_branches?
        visible[:companies] += company.branch_companies.pluck(:id)
      end
    end
    
    # Step 3: Add partner org members (if share_members = true)
    my_schools.each do |us|
      school = us.school
      
      # Get partner companies where share_members = true
      school.partnerships.where(share_members: true, status: :confirmed).each do |partnership|
        partnership.partnership_members.where(participant_type: 'Company').each do |pm|
          visible[:companies] << pm.participant_id unless pm.participant_id == school.id
        end
        
        partnership.partnership_members.where(participant_type: 'School').each do |pm|
          visible[:schools] << pm.participant_id unless pm.participant_id == school.id
        end
      end
    end
    
    my_companies.each do |uc|
      company = uc.company
      
      # Get partner schools/companies where share_members = true
      company.partnerships.where(share_members: true, status: :confirmed).each do |partnership|
        partnership.partnership_members.where(participant_type: 'School').each do |pm|
          visible[:schools] << pm.participant_id unless pm.participant_id == company.id
        end
        
        partnership.partnership_members.where(participant_type: 'Company').each do |pm|
          visible[:companies] << pm.participant_id unless pm.participant_id == company.id
        end
      end
    end
    
    # Return unique IDs
    {
      schools: visible[:schools].uniq,
      companies: visible[:companies].uniq
    }
  end
  
  # Serialize UserSchool with full details
  def serialize_user_school(user_school)
    school = user_school.school
    
    {
      id: school.id,
      name: school.name,
      city: school.city,
      school_type: school.school_type,
      logo_url: school.logo.attached? ? 
        Rails.application.routes.url_helpers.rails_blob_url(school.logo, only_path: false) : nil,
      my_role: user_school.role,
      my_status: user_school.status,
      my_permissions: {
        superadmin: user_school.superadmin?,
        admin: user_school.admin? || user_school.superadmin?,
        referent: user_school.referent?,
        intervenant: user_school.intervenant?,
        can_manage_members: user_school.can_manage_members?,
        can_manage_projects: user_school.can_manage_projects?,
        can_assign_badges: user_school.can_assign_badges?,
        can_manage_partnerships: user_school.can_manage_partnerships?,
        can_manage_branches: user_school.can_manage_branches?
      },
      teachers_count: school.users.where(role: :teacher).count,
      students_count: school.users.where(role: [:tutor, :children]).count,
      levels_count: school.school_levels.count,
      joined_at: user_school.created_at
    }
  end
  
  # Serialize UserCompany with full details
  def serialize_user_company(user_company)
    company = user_company.company
    
    {
      id: company.id,
      name: company.name,
      city: company.city,
      company_type: company.company_type&.name,
      logo_url: company.logo.attached? ? 
        Rails.application.routes.url_helpers.rails_blob_url(company.logo, only_path: false) : nil,
      my_role: user_company.role,
      my_status: user_company.status,
      my_permissions: {
        superadmin: user_company.superadmin?,
        admin: user_company.admin? || user_company.superadmin?,
        referent: user_company.referent?,
        intervenant: user_company.intervenant?,
        can_manage_members: user_company.can_manage_members?,
        can_manage_projects: user_company.can_manage_projects?,
        can_assign_badges: user_company.can_assign_badges?,
        can_manage_partnerships: user_company.can_manage_partnerships?,
        can_manage_branches: user_company.can_manage_branches?
      },
      members_count: company.users.count,
      projects_count: company.projects.count,
      joined_at: user_company.created_at
    }
  end
  
  # Serialize network user with common org info
  def serialize_network_user(user)
    common_schools = current_user.schools.confirmed & user.schools.confirmed
    common_companies = current_user.companies.confirmed & user.companies.confirmed
    
    {
      id: user.id,
      full_name: user.full_name,
      first_name: user.first_name,
      last_name: user.last_name,
      email: user.email,
      role: user.role,
      job: user.job,
      avatar_url: user.avatar.attached? ? 
        Rails.application.routes.url_helpers.rails_blob_url(user.avatar, only_path: false) : nil,
      skills: user.skills.limit(5).map { |s| {id: s.id, name: s.name} },
      common_organizations: (common_schools + common_companies).map { |org| 
        {id: org.id, name: org.name, type: org.class.name}
      }
    }
  end
  
  def pagination_meta(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.items
    }
  end
end

