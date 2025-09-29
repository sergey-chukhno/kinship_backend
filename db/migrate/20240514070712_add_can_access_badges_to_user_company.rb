class AddCanAccessBadgesToUserCompany < ActiveRecord::Migration[7.0]
  def change
    add_column :user_companies, :can_access_badges, :boolean, default: false

    # UserCompany.all.each do |user_company|
    #   user_company.update!(can_access_badges: user_company.admin?)
    # end
  end
end
