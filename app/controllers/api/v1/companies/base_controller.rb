# Base controller for Company Dashboard API
# Ensures only admin/superadmin users can access company dashboard
class Api::V1::Companies::BaseController < Api::V1::BaseController
  before_action :set_company
  before_action :ensure_admin_or_superadmin
  
  private
  
  def set_company
    @company = Company.find(params[:company_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: 'Not Found',
      message: 'Company not found'
    }, status: :not_found
  end
  
  def ensure_admin_or_superadmin
    user_company = current_user.user_company.find_by(
      company: @company,
      status: :confirmed,
      role: [:admin, :superadmin]
    )
    
    unless user_company
      return render json: {
        error: 'Forbidden',
        message: 'Company Dashboard access requires Admin or Superadmin role'
      }, status: :forbidden
    end
    
    @current_user_company = user_company
  end
  
  def ensure_superadmin
    unless @current_user_company.superadmin?
      return render json: {
        error: 'Forbidden',
        message: 'This action requires Superadmin role'
      }, status: :forbidden
    end
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

