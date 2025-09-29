class CreateUserSubSkills < ActiveRecord::Migration[7.0]
  def change
    create_table :user_sub_skills do |t|
      t.references :user, null: false, foreign_key: true
      t.references :sub_skill, null: false, foreign_key: true

      t.timestamps
    end
  end
end
