class CreateTeacherSchoolLevels < ActiveRecord::Migration[7.1]
  def change
    create_table :teacher_school_levels do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :school_level, null: false, foreign_key: true, index: true
      t.boolean :is_creator, default: false, null: false
      t.datetime :assigned_at

      t.timestamps
    end
    
    # Unique constraint: one teacher can only be assigned once per class
    add_index :teacher_school_levels, [:user_id, :school_level_id], 
              unique: true, 
              name: 'index_teacher_school_levels_on_user_and_school_level'
    
    say "Created teacher_school_levels table for explicit teacher-class assignments"
    say "Tracks which teachers are assigned to which classes"
    say "is_creator flag identifies who originally created the class"
  end
end
