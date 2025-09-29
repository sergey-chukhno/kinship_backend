class AddCanCreateProjectToUserCompany < ActiveRecord::Migration[7.0]
  def change
    add_column :user_companies, :can_create_project, :boolean, default: false

    # UserCompany.all.each do |user_company|
    #   user_company.update!(can_create_project: user_company.admin?)
    # end
  end
end
