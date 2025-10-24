# Main Companies API controller
# Handles company profile and dashboard stats
class Api::V1::CompaniesController < Api::V1::Companies::BaseController
  skip_before_action :set_company, only: []
  skip_before_action :ensure_admin_or_superadmin, only: []
  
  # GET /api/v1/companies/:id
  # View company profile
  def show
    render json: {
      data: serialize_company(@company, @current_user_company)
    }
  end
  
  # PATCH /api/v1/companies/:id
  # Update company profile (admin/superadmin only)
  def update
    if @company.update(company_params)
      render json: {
        message: 'Company updated successfully',
        data: serialize_company(@company, @current_user_company)
      }
    else
      render json: {
        error: 'Validation Failed',
        details: @company.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # GET /api/v1/companies/:id/stats
  # Dashboard statistics
  def stats
    # Base stats
    stats_data = {
      overview: {
        total_members: @company.users.where(user_companies: {status: :confirmed}).count,
        total_projects: @company.projects.count,
        active_partnerships: @company.partnerships.where(status: :confirmed).count,
        active_contract: @company.active_contract?,
        is_branch: @company.branch?,
        is_main_company: @company.main_company?
      },
      members_by_role: {
        superadmin: @company.user_companies.where(role: :superadmin, status: :confirmed).count,
        admin: @company.user_companies.where(role: :admin, status: :confirmed).count,
        referent: @company.user_companies.where(role: :referent, status: :confirmed).count,
        intervenant: @company.user_companies.where(role: :intervenant, status: :confirmed).count,
        member: @company.user_companies.where(role: :member, status: :confirmed).count
      },
      projects_by_status: {
        in_progress: @company.projects.where(status: :in_progress).count,
        completed: @company.projects.where(status: :completed).count,
        cancelled: @company.projects.where(status: :cancelled).count
      },
      badges_assigned: {
        total: UserBadge.where(organization: @company).count,
        this_month: UserBadge.where(organization: @company)
                            .where('created_at >= ?', Time.current.beginning_of_month)
                            .count
      },
      pending_approvals: {
        members: @company.user_companies.where(status: :pending).count,
        partnerships: @company.partnerships.where(status: :pending).count,
        branch_requests: BranchRequest.for_organization(@company).where(status: :pending).count
      }
    }
    
    # Add branch stats if main company
    if @company.main_company?
      stats_data[:branches] = {
        total_branches: @company.branch_companies.count,
        branch_members: @company.all_members_including_branches.count,
        branch_projects: @company.all_projects_including_branches.count
      }
    end
    
    # Add parent company info if branch
    if @company.branch?
      stats_data[:parent_company] = {
        id: @company.parent_company.id,
        name: @company.parent_company.name
      }
    end
    
    render json: stats_data
  end
  
  private
  
  def company_params
    params.require(:company).permit(
      :name, :city, :zip_code, :email, :website, 
      :referent_phone_number, :description
    )
  end
  
  def serialize_company(company, user_company)
    {
      id: company.id,
      name: company.name,
      siret_number: company.siret_number,
      city: company.city,
      zip_code: company.zip_code,
      email: company.email,
      website: company.website,
      referent_phone_number: company.referent_phone_number,
      description: company.description,
      company_type: company.company_type&.name,
      status: company.status,
      logo_url: company.logo.attached? ? 
        Rails.application.routes.url_helpers.rails_blob_url(company.logo, only_path: false) : nil,
      my_role: user_company.role,
      my_permissions: {
        can_manage_members: user_company.can_manage_members?,
        can_manage_projects: user_company.can_manage_projects?,
        can_create_project: user_company.can_create_project?,
        can_assign_badges: user_company.can_assign_badges?,
        can_manage_partnerships: user_company.can_manage_partnerships?,
        can_manage_branches: user_company.can_manage_branches?
      },
      branch_info: {
        is_branch: company.branch?,
        is_main_company: company.main_company?,
        parent_company_id: company.parent_company_id,
        branches_count: company.branch_companies.count,
        share_members_with_branches: company.share_members_with_branches
      },
      created_at: company.created_at,
      updated_at: company.updated_at
    }
  end
end
