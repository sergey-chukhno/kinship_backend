class Api::V1::Teachers::BaseController < Api::V1::BaseController
  before_action :verify_teacher_role!
  
  private
  
  def verify_teacher_role!
    unless User.is_teacher_role?(current_user.role)
      render json: { 
        error: 'Forbidden',
        message: 'Teacher dashboard access requires teacher role'
      }, status: :forbidden
    end
  end
  
  def teacher_can_manage_class?(school_level)
    # Teacher is creator OR assigned to class
    school_level.created_by?(current_user) ||
    current_user.teacher_school_levels.exists?(school_level: school_level)
  end
  
  def student_in_teacher_classes?(student)
    teacher_class_ids = current_user.assigned_classes.pluck(:id)
    student.school_levels.where(id: teacher_class_ids).exists?
  end
  
  def claim_url(token)
    "#{Rails.application.routes.url_helpers.root_url}claim-account/#{token}"
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
