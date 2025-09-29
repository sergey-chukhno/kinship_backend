class CreateProjectkeywords < ActiveRecord::Migration[7.0]
  def change
    create_table :project_keywords do |t|
      t.references :project, null: false, foreign_key: true
      t.references :keyword, null: false, foreign_key: true

      t.timestamps
    end
  end
end
