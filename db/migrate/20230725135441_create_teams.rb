class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams do |t|
      t.string :title
      t.string :description
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
