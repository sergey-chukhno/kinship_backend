class CreateSkills < ActiveRecord::Migration[7.0]
  def change
    create_table :skills do |t|
      t.string :name
      t.boolean :official, default: false

      t.timestamps
    end
  end
end
