class AddCanAccessBadgesToUserSchool < ActiveRecord::Migration[7.0]
  def change
    add_column :user_schools, :can_access_badges, :boolean, default: false

    # UserSchool.all.each do |user_school|
    #   user_school.update!(can_access_badges: user_school.admin?)
    # end
  end
end
