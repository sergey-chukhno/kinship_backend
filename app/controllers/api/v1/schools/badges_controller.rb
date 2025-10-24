# School Badges API controller
# Handles badge assignment by school members
class Api::V1::Schools::BadgesController < Api::V1::Schools::BaseController
  include Pagy::Backend
  
  # POST /api/v1/schools/:school_id/badges/assign
  # Assign badge (admin/superadmin only for school dashboard)
  def assign
    # Verify school has active contract
    unless @school.active_contract?
      return render json: {
        error: 'Forbidden',
        message: 'School must have an active contract to assign badges'
      }, status: :forbidden
    end
    
    # Find badge
    badge = Badge.find_by(id: params[:badge_id])
    unless badge
      return render json: {
        error: 'Not Found',
        message: 'Badge not found'
      }, status: :not_found
    end
    
    # Get recipients
    recipient_ids = params[:recipient_ids] || []
    if recipient_ids.empty?
      return render json: {
        error: 'Bad Request',
        message: 'At least one recipient is required'
      }, status: :bad_request
    end
    
    # Assign badges to recipients
    assignments = []
    errors = []
    
    recipient_ids.each do |recipient_id|
      begin
        recipient = User.find(recipient_id)
        
        user_badge = UserBadge.create!(
          receiver: recipient,
          badge: badge,
          sender: current_user,
          organization: @school,
          project_title: params[:project_title] || "Badge assigned via School Dashboard",
          project_description: params[:project_description] || "Badge assigned by #{current_user.full_name}",
          comment: params[:comment]
        )
        
        # Add badge skills if provided
        if params[:badge_skill_ids].present?
          params[:badge_skill_ids].each do |badge_skill_id|
            user_badge.user_badge_skills.create!(badge_skill_id: badge_skill_id)
          end
        end
        
        assignments << {
          user_id: recipient.id,
          user_name: recipient.full_name,
          badge_id: badge.id,
          badge_name: badge.name
        }
        
      rescue ActiveRecord::RecordNotFound
        errors << "User #{recipient_id} not found"
      rescue ActiveRecord::RecordInvalid => e
        errors << "User #{recipient_id}: #{e.message}"
      end
    end
    
    if assignments.any?
      render json: {
        message: 'Badges assigned successfully',
        assigned_count: assignments.count,
        assignments: assignments,
        errors: errors.any? ? errors : nil
      }, status: :created
    else
      render json: {
        error: 'Assignment failed',
        message: 'No badges were assigned',
        details: errors
      }, status: :unprocessable_entity
    end
  end
  
  # GET /api/v1/schools/:school_id/badges/assigned
  # List badges assigned by school members
  def assigned
    # Show all badges assigned by ANY school member (for school admin view)
    @user_badges = UserBadge.where(organization: @school)
                            .includes(:receiver, :badge, :project, :sender)
    
    # Filters
    if params[:sender_id].present?
      @user_badges = @user_badges.where(sender_id: params[:sender_id])
    end
    
    if params[:project_id].present?
      @user_badges = @user_badges.where(project_id: params[:project_id])
    end
    
    if params[:badge_series].present?
      @user_badges = @user_badges.joins(:badge).where(badges: {series: params[:badge_series]})
    end
    
    if params[:badge_level].present?
      @user_badges = @user_badges.joins(:badge).where(badges: {level: params[:badge_level]})
    end
    
    @pagy, @user_badges = pagy(@user_badges.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: @user_badges.map { |user_badge| serialize_user_badge(user_badge) },
      meta: pagination_meta(@pagy)
    }
  end
  
  private
  
  def serialize_user_badge(user_badge)
    {
      id: user_badge.id,
      receiver: {
        id: user_badge.receiver.id,
        full_name: user_badge.receiver.full_name,
        email: user_badge.receiver.email
      },
      sender: {
        id: user_badge.sender.id,
        full_name: user_badge.sender.full_name
      },
      badge: {
        id: user_badge.badge.id,
        name: user_badge.badge.name,
        series: user_badge.badge.series,
        level: user_badge.badge.level
      },
      project: user_badge.project ? {
        id: user_badge.project.id,
        title: user_badge.project.title
      } : nil,
      status: user_badge.status,
      comment: user_badge.comment,
      assigned_at: user_badge.created_at
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

