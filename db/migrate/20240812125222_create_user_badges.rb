class CreateUserBadges < ActiveRecord::Migration[7.0]
  def change
    create_table :user_badges do |t|
      t.string :project_title, null: false
      t.string :project_description, null: false
      t.integer :status, null: false, default: 0
      t.references :sender, null: false, foreign_key: {to_table: :users}
      t.references :receiver, null: false, foreign_key: {to_table: :users}
      t.references :badge, null: false, foreign_key: true
      t.references :project, null: true, foreign_key: true

      t.timestamps
    end
  end
end
