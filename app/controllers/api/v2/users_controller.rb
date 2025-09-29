class Api::V2::UsersController < Api::V2::BaseController
  include Pagy::Backend

  def index
    items_per_page = 20
    query = params[:query] || ""
    query_parts = query.strip.split
    search_query = query_parts.map do |part|
      "first_name ILIKE :part_#{part} OR last_name ILIKE :part_#{part}"
    end.join(" OR ")
    search_query_values = query_parts.each_with_index.map do |part, index|
      [:"part_#{part}", "%#{part}%"]
    end.to_h

    @pagy, @users = pagy(User
      .includes(:user_company)
      .where(
        user_company: {
          status: :confirmed,
          company_id: @api_access.company_ids
        }
      )
      .where(search_query, search_query_values),
      items: items_per_page)
    @pagination = pagy_metadata(@pagy)

    render json: {
      data: @users.as_json(only: [:id, :first_name, :last_name, :email, :role]),
      meta: @pagination.as_json(only: [:count, :pages, :prev, :next, :page])
    }, status: :ok
  end

  def show
    @user = User.includes(:companies).find_by(id: params[:id])

    if can_access_user?(@user, @api_access)
      render json: @user.as_json(
        only: [:id, :first_name, :last_name, :email, :role, :birthday, :role_additional_information, :job, :company_name, :certify],
        include: {
          skills: {
            only: [:name]
          },
          badges_received: {
            only: [:project_title, :project_description, :created_at],
            include: {
              badge: {
                only: [:id, :name, :level],
                include: {
                  badge_skills: {
                    only: [:name, :category]
                  }
                }
              }
            }
          },
          project_members: {
            only: [],
            include: {
              project: {
                only: [:id, :title, :description],
                include: {
                  skills: {
                    only: [:name]
                  }
                }
              }
            }
          }
        }
      ), status: :ok
    else
      render json: {error: "Unauthorized"}, status: :unauthorized
    end
  end

  private

  def can_access_user?(user, api_access)
    return false if user.nil?

    user.user_company.any? { |user_company| api_access.company_ids.include?(user_company.company_id) && user_company.status == "confirmed" }
  end
end
