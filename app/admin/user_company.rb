ActiveAdmin.register UserCompany do
  menu false
  permit_params :user_id, :company_id, :admin, :status, :owner
end
