class AddStatusOwnerAdminToUserSchool < ActiveRecord::Migration[7.0]
  def change
    add_column :user_schools, :status, :integer, default: 0, null: false
    add_column :user_schools, :owner, :boolean, default: false, null: false
    add_column :user_schools, :admin, :boolean, default: false, null: false

    UserSchool.all.each do |user_school|
      user_school.update!(status: :confirmed)
    end
  end
end
