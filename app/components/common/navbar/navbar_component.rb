# frozen_string_literal: true

class Common::Navbar::NavbarComponent < ViewComponent::Base
  def initialize(current_user)
    @current_user = current_user
  end

  def render_schools_admin_panel?
    @current_user.user_schools.where(can_access_badges: true, status: :confirmed).any?
  end

  def render_companies_admin_panel?
    @current_user.user_company.where(can_access_badges: true, status: :confirmed).any?
  end
end
