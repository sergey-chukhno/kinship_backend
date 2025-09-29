class DropProjectKeywordsTable < ActiveRecord::Migration[7.0]
  def up
    drop_table :project_keywords, if_exists: true
  end

  def down
    create_table :project_keywords do |t|
      t.references :project, null: false, foreign_key: true
      t.references :keyword, null: false, foreign_key: true

      t.timestamps
    end
  end
end
