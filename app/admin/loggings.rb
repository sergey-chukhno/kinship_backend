ActiveAdmin.register Logging do
  menu label: "Journalisation", if: proc { current_user.super_admin? }
  actions :index, :show

  filter :ip_address
  filter :user_id
  filter :user_email

  index do
    column :ip_address
    column :request_path
    column :request_path_params
    column :request_code
    column :request_time
    column :user_agent
    column :user_id
    column :user_email
    actions
  end
end
