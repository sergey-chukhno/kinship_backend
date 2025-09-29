class AddLevelToSchoolLevel < ActiveRecord::Migration[7.0]
  def change
    add_column :school_levels, :level, :integer
  end
end
