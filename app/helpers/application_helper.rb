module ApplicationHelper
  include Pagy::Frontend

  def remove_main_container?(path)
    path.include?("sign_in") || path.include?("users/edit") || path.include?("mobile_phone_menu")
  end

  def remove_navbar?(path)
    path.include?("sign_in") || path.include?("sign_up") || path.include?("registration_stepper") || path.include?("password")
  end
end
