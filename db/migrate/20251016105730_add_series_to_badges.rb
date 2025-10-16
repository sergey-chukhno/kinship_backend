class AddSeriesToBadges < ActiveRecord::Migration[7.1]
  def change
    add_column :badges, :series, :string, default: "Série TouKouLeur", null: false
    add_index :badges, :series
  end
end
