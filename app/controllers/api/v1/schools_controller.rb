# Main Schools API controller
# Handles school profile and dashboard stats
class Api::V1::SchoolsController < Api::V1::Schools::BaseController
  skip_before_action :set_school, only: []
  skip_before_action :ensure_school_member, only: []
  
  # GET /api/v1/schools/:id
  # View school profile
  def show
    render json: {
      data: serialize_school(@school, @current_user_school)
    }
  end
  
  # PATCH /api/v1/schools/:id
  # Update school profile (admin/superadmin only)
  def update
    if @school.update(school_params)
      render json: {
        message: 'School updated successfully',
        data: serialize_school(@school, @current_user_school)
      }
    else
      render json: {
        error: 'Validation Failed',
        details: @school.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # GET /api/v1/schools/:id/stats
  # Dashboard statistics
  def stats
    # Base stats
    stats_data = {
      overview: {
        total_members: @school.users.count,
        total_teachers: @school.users.where(role: :teacher).count,
        total_students: @school.school_levels.joins(:students).distinct.count('users.id'),
        total_levels: @school.school_levels.count,
        total_projects: Project.joins(:project_school_levels)
                              .joins('JOIN school_levels ON project_school_levels.school_level_id = school_levels.id')
                              .where('school_levels.school_id = ?', @school.id)
                              .distinct.count,
        active_contract: @school.active_contract?,
        is_branch: @school.branch?,
        is_main_school: @school.main_school?
      },
      members_by_role: {
        superadmin: @school.user_schools.where(role: :superadmin, status: :confirmed).count,
        admin: @school.user_schools.where(role: :admin, status: :confirmed).count,
        referent: @school.user_schools.where(role: :referent, status: :confirmed).count,
        intervenant: @school.user_schools.where(role: :intervenant, status: :confirmed).count,
        member: @school.user_schools.where(role: :member, status: :confirmed).count
      },
      pending_approvals: {
        members: @school.user_schools.where(status: :pending).count,
        partnerships: @school.partnerships.where(status: :pending).count,
        branch_requests: BranchRequest.for_organization(@school).where(status: :pending).count
      }
    }
    
    # Add branch stats if main school
    if @school.main_school?
      # Calculate branch projects manually
      branch_school_ids = @school.branch_schools.pluck(:id)
      total_branch_projects = Project.joins(:project_school_levels)
                                    .joins('JOIN school_levels ON project_school_levels.school_level_id = school_levels.id')
                                    .where('school_levels.school_id IN (?)', [@school.id] + branch_school_ids)
                                    .distinct.count
      
      stats_data[:branches] = {
        total_branches: @school.branch_schools.count,
        branch_members: @school.all_members_including_branches.count,
        branch_projects: total_branch_projects
      }
    end
    
    # Add parent school info if branch
    if @school.branch?
      stats_data[:parent_school] = {
        id: @school.parent_school.id,
        name: @school.parent_school.name
      }
    end
    
    render json: stats_data
  end
  
  private
  
  def school_params
    params.require(:school).permit(
      :name, :city, :zip_code, :school_type, :referent_phone_number
    )
  end
  
  def serialize_school(school, user_school)
    {
      id: school.id,
      name: school.name,
      city: school.city,
      zip_code: school.zip_code,
      school_type: school.school_type,
      referent_phone_number: school.referent_phone_number,
      status: school.status,
      logo_url: school.logo.attached? ? 
        Rails.application.routes.url_helpers.rails_blob_url(school.logo, only_path: false) : nil,
      my_role: user_school.role,
      my_permissions: {
        can_manage_members: user_school.can_manage_members?,
        can_manage_levels: user_school.admin? || user_school.superadmin?,
        can_manage_projects: user_school.can_manage_projects?,
        can_assign_badges: user_school.can_assign_badges?,
        can_manage_partnerships: user_school.can_manage_partnerships?,
        can_manage_branches: user_school.can_manage_branches?
      },
      branch_info: {
        is_branch: school.branch?,
        is_main_school: school.main_school?,
        parent_school_id: school.parent_school_id,
        branches_count: school.branch_schools.count,
        share_members_with_branches: school.share_members_with_branches
      },
      created_at: school.created_at,
      updated_at: school.updated_at
    }
  end
end
