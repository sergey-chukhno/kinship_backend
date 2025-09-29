class CreateBadgeSkills < ActiveRecord::Migration[7.0]
  def change
    create_table :badge_skills do |t|
      t.string :name, null: false
      t.integer :category, null: false, default: 0
      t.references :badge, null: false, foreign_key: true

      t.timestamps
    end
  end
end
