class CreateProjectSchoolLevels < ActiveRecord::Migration[7.0]
  def change
    create_table :project_school_levels do |t|
      t.references :school_level, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
