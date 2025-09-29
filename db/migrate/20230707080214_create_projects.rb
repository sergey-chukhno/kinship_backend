class CreateProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :projects do |t|
      t.string :title
      t.text :description
      t.datetime :start_date
      t.datetime :end_date
      t.references :owner, null: false, foreign_key: {to_table: :users}

      t.timestamps
    end
  end
end
