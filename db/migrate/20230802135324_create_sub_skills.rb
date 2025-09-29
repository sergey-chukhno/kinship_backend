class CreateSubSkills < ActiveRecord::Migration[7.0]
  def change
    create_table :sub_skills do |t|
      t.references :skill, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
