class MigrateOldUserRolesToNewRoles < ActiveRecord::Migration[7.1]
  def up
    # Map old role enum values to new role enum values
    # Old enum: teacher: 0, tutor: 1, voluntary: 2, children: 3
    # New enum: parent: 0, grand_parent: 1, children: 2, voluntary: 3, tutor: 4, 
    #           employee: 5, school_teacher: 6, college_lycee_professor: 7, ...
    
    # teacher (old: 0) → school_teacher (new: 6)
    execute <<-SQL
      UPDATE users 
      SET role = 6 
      WHERE role = 0
    SQL
    
    # tutor (old: 1) → tutor (new: 4)
    execute <<-SQL
      UPDATE users 
      SET role = 4 
      WHERE role = 1
    SQL
    
    # voluntary (old: 2) → voluntary (new: 3)
    execute <<-SQL
      UPDATE users 
      SET role = 3 
      WHERE role = 2
    SQL
    
    # children (old: 3) → children (new: 2)
    execute <<-SQL
      UPDATE users 
      SET role = 2 
      WHERE role = 3
    SQL
  end

  def down
    # Reverse mapping - map new roles back to old roles
    # This is for rollback purposes
    
    # school_teacher (new: 6) → teacher (old: 0)
    execute <<-SQL
      UPDATE users 
      SET role = 0 
      WHERE role = 6
    SQL
    
    # tutor (new: 4) → tutor (old: 1)
    execute <<-SQL
      UPDATE users 
      SET role = 1 
      WHERE role = 4
    SQL
    
    # voluntary (new: 3) → voluntary (old: 2)
    execute <<-SQL
      UPDATE users 
      SET role = 2 
      WHERE role = 3
    SQL
    
    # children (new: 2) → children (old: 3)
    execute <<-SQL
      UPDATE users 
      SET role = 3 
      WHERE role = 2
    SQL
  end
end
