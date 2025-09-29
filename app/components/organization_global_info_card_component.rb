class OrganizationGlobalInfoCardComponent < ViewComponent::Base
  include SvgHelper
  include Turbo::FramesHelper

  def initialize(school: nil, company: nil, current_user: nil)
    @organization = school || company
    @current_user = current_user
  end

  def name
    @organization.full_name
  end

  def status
    @organization.send("user_#{school? ? "schools" : "companies"}").find_by(user: @current_user).status
  end

  def school?
    @organization.is_a?(School)
  end

  def user_school_levels
    return unless school? || @current_user&.teacher?
    return "Aucune classe" if @current_user.school_levels.where(school_id: @organization.id).blank?

    @current_user.school_levels.where(school_id: @organization.id).map(&:full_name_without_school).join(", ")
  end

  def users_count
    @organization.users.count
  end

  def users_take_trainee_count
    @organization.users.by_take_trainee.count
  end

  def organization_skills_count
    @organization.users.includes([:skills]).map { |user| user.skills }.flatten.uniq.count
  end

  def delete_organization_path
    if school?
      user_school = @organization.user_schools.find_by(user: @current_user)
      user_school ? account_school_path(user_school) : nil
    else
      user_company = @organization.user_companies.find_by(user: @current_user)
      user_company ? account_network_path(user_company) : nil
    end
  end
end
