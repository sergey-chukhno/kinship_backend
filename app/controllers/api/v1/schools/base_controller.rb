# Base controller for all school-scoped endpoints
# Handles authorization and school context
# CRITICAL: Only admin/superadmin can access School Dashboard
class Api::V1::Schools::BaseController < Api::V1::BaseController
  before_action :set_school
  before_action :ensure_school_member
  
  private
  
  def set_school
    @school = School.find(params[:school_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: 'Not Found',
      message: 'School not found'
    }, status: :not_found
  end
  
  def ensure_school_member
    # CRITICAL: Only admin/superadmin can access School Dashboard
    user_school = current_user.user_schools.find_by(
      school: @school, 
      status: :confirmed,
      role: [:admin, :superadmin]
    )
    
    unless user_school
      return render json: {
        error: 'Forbidden',
        message: 'School Dashboard access requires Admin or Superadmin role'
      }, status: :forbidden
    end
    
    @current_user_school = user_school
  end
  
  def ensure_admin_or_superadmin
    unless @current_user_school.admin? || @current_user_school.superadmin?
      render json: {
        error: 'Forbidden',
        message: 'Admin or Superadmin role required'
      }, status: :forbidden
    end
  end
  
  def ensure_superadmin
    unless @current_user_school.superadmin?
      render json: {
        error: 'Forbidden',
        message: 'Superadmin role required'
      }, status: :forbidden
    end
  end
  
  def ensure_can_manage_projects
    unless @current_user_school.can_manage_projects?
      render json: {
        error: 'Forbidden',
        message: 'Referent, Admin, or Superadmin role required'
      }, status: :forbidden
    end
  end
  
  def ensure_can_assign_badges
    unless @current_user_school.can_assign_badges?
      render json: {
        error: 'Forbidden',
        message: 'Insufficient permissions to assign badges'
      }, status: :forbidden
    end
  end
end

