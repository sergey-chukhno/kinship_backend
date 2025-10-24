class Api::V1::Teachers::BadgesController < Api::V1::Teachers::BaseController
  include Pagy::Backend

  # GET /api/v1/teachers/badges/attributed
  # List all badges attributed by the teacher
  def attributed
    # Base query: all badges assigned by this teacher
    @user_badges = UserBadge.where(sender_id: current_user.id).includes(:receiver, :badge, :organization, :project)

    # Filter by project
    if params[:project_id].present?
      @user_badges = @user_badges.where(project_id: params[:project_id])
    end

    # Filter by badge series
    if params[:badge_series].present?
      badge_ids = Badge.where(series: params[:badge_series]).pluck(:id)
      @user_badges = @user_badges.where(badge_id: badge_ids)
    end

    # Filter by badge level
    if params[:badge_level].present?
      badge_ids = Badge.where(level: params[:badge_level]).pluck(:id)
      @user_badges = @user_badges.where(badge_id: badge_ids)
    end

    # Paginate results
    @pagy, @user_badges = pagy(@user_badges, items: params[:per_page] || 12)

    render json: {
      data: @user_badges.map do |user_badge|
        {
          id: user_badge.id,
          receiver: {
            id: user_badge.receiver.id,
            full_name: user_badge.receiver.full_name,
            email: user_badge.receiver.email,
            role: user_badge.receiver.role
          },
          badge: {
            id: user_badge.badge.id,
            name: user_badge.badge.name,
            description: user_badge.badge.description,
            series: user_badge.badge.series,
            level: user_badge.badge.level
          },
          project: user_badge.project ? {
            id: user_badge.project.id,
            title: user_badge.project.title
          } : nil,
          organization: organization_data(user_badge.organization),
          assigned_at: user_badge.created_at,
          status: user_badge.status
        }
      end,
      pagination: {
        current_page: @pagy.page,
        total_pages: @pagy.pages,
        total_items: @pagy.count,
        items_per_page: @pagy.items
      }
    }
  end

  private

  def organization_data(organization)
    return nil unless organization

    case organization
    when School
      {
        type: 'School',
        id: organization.id,
        name: organization.name
      }
    when Company
      {
        type: 'Company',
        id: organization.id,
        name: organization.name
      }
    else
      nil
    end
  end
end

