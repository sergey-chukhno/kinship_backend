class CreateApiAccesses < ActiveRecord::Migration[7.0]
  def change
    create_table :api_accesses do |t|
      t.string :token, null: false, unique: true
      t.string :name, null: false

      t.timestamps
    end
  end
end
