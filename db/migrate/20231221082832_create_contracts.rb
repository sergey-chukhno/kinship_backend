class CreateContracts < ActiveRecord::Migration[7.0]
  def change
    create_table :contracts do |t|
      t.references :school, null: false, foreign_key: true
      t.boolean :active, null: false, default: false
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end
  end
end
