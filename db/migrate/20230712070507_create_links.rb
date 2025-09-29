class CreateLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :links do |t|
      t.string :name
      t.string :url
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
