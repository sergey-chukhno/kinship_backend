class AddShowMySkillsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :show_my_skills, :boolean, default: false, null: false

    User.all.each do |user|
      if user.skills.any?
        user.update(show_my_skills: true)
      end
    end
  end
end
