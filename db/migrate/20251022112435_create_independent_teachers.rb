class CreateIndependentTeachers < ActiveRecord::Migration[7.1]
  def change
    create_table :independent_teachers do |t|
      t.references :user, null: false, foreign_key: true, index: {unique: true}
      t.string :organization_name, null: false
      t.string :city
      t.text :description
      t.integer :status, default: 0, null: false  # active=0, paused=1, archived=2
      t.timestamps
    end
    
    add_index :independent_teachers, :status
    
    # Auto-create IndependentTeacher for all existing teachers
    # (On teacher registration from now on - see User model callback)
    reversible do |dir|
      dir.up do
        # Create IndependentTeacher for all existing users with role=teacher
        execute <<-SQL
          INSERT INTO independent_teachers (user_id, organization_name, status, created_at, updated_at)
          SELECT 
            id,
            CONCAT(first_name, ' ', last_name, ' - Enseignant Indépendant'),
            0,  -- status: active
            NOW(),
            NOW()
          FROM users 
          WHERE role = 0  -- teacher role
          ON CONFLICT (user_id) DO NOTHING
        SQL
      end
    end
  end
end
