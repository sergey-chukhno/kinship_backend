class CreateUserBadgeSkills < ActiveRecord::Migration[7.0]
  def change
    create_table :user_badge_skills do |t|
      t.references :user_badge, null: false, foreign_key: true
      t.references :badge_skill, null: false, foreign_key: true

      t.timestamps
    end
  end
end
