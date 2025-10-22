# Badges API controller for User Dashboard
# Handles badge assignment with permission checks
class Api::V1::BadgesController < Api::V1::BaseController
  
  # POST /api/v1/badges/assign
  # Assign badge to user(s)
  def assign
    # Find organization
    organization = find_organization
    
    unless organization
      return render json: {
        error: 'Bad Request',
        message: 'Valid organization_id and organization_type are required'
      }, status: :bad_request
    end
    
    # Verify user has badge assignment permission
    unless user_can_assign_badges_in_organization?(organization)
      return render json: {
        error: 'Forbidden',
        message: "You don't have permission to assign badges in #{organization.name}"
      }, status: :forbidden
    end
    
    # Verify organization has active contract
    unless organization.active_contract?
      return render json: {
        error: 'Forbidden',
        message: 'Organization must have an active contract to assign badges'
      }, status: :forbidden
    end
    
    # Find badge
    badge = Badge.find_by(id: params[:badge_assignment][:badge_id])
    unless badge
      return render json: {
        error: 'Not Found',
        message: 'Badge not found'
      }, status: :not_found
    end
    
    # Get recipients
    recipient_ids = params[:badge_assignment][:recipient_ids] || []
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
          organization: organization,
          project_title: params[:badge_assignment][:project_title] || "Badge assigned via API",
          project_description: params[:badge_assignment][:project_description] || "Badge assigned by #{current_user.full_name}"
        )
        
        # Add badge skills if provided
        if params[:badge_assignment][:badge_skill_ids].present?
          params[:badge_assignment][:badge_skill_ids].each do |badge_skill_id|
            user_badge.user_badge_skills.create!(badge_skill_id: badge_skill_id)
          end
        end
        
        assignments << {
          user_id: recipient.id,
          user_name: recipient.full_name,
          badge_id: badge.id,
          badge_name: badge.name,
          organization: organization.name
        }
        
        # Send notification email (background job - user preference)
        # UserBadgeMailer.notify_badge_received(user_badge).deliver_later
        
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
  
  private
  
  # Find organization from params
  def find_organization
    return nil unless params[:badge_assignment]
    
    org_type = params[:badge_assignment][:organization_type]
    org_id = params[:badge_assignment][:organization_id]
    
    return nil unless org_type && org_id
    
    case org_type
    when 'School'
      School.find_by(id: org_id)
    when 'Company'
      Company.find_by(id: org_id)
    end
  end
  
  # Check if user can assign badges in organization
  def user_can_assign_badges_in_organization?(organization)
    case organization
    when School
      current_user.user_schools.exists?(
        school: organization,
        role: [:intervenant, :referent, :admin, :superadmin],
        status: :confirmed
      )
    when Company
      current_user.user_company.exists?(
        company: organization,
        role: [:intervenant, :referent, :admin, :superadmin],
        status: :confirmed
      )
    else
      false
    end
  end
end

