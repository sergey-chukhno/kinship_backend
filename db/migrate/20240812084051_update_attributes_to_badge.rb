class UpdateAttributesToBadge < ActiveRecord::Migration[7.0]
  def up
    change_table :badges do |t|
      t.remove :url
      t.string :name
      t.integer :level
    end

    # Update existing records with default values
    Badge.where(name: nil).update_all(name: "")
    Badge.where(level: nil).update_all(level: 1)

    # Add NOT NULL constraints
    change_column_null :badges, :name, false
    change_column_null :badges, :level, false
  end

  def down
    change_table :badges do |t|
      t.string :url
      t.remove :name
      t.remove :level
    end
  end
end
