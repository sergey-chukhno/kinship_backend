# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu false

  controller do
    before_action do |_|
      redirect_to admin_users_path
    end
  end
end
