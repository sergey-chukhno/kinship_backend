ActiveAdmin.register UserSchool do
  menu false
  permit_params :user_id, :school_id, :admin, :status, :owner
end
