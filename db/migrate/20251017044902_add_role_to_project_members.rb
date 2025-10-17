class AddRoleToProjectMembers < ActiveRecord::Migration[7.1]
  def up
    say "========================================="
    say "Adding role enum to project_members"
    say "========================================="
    
    # Count before migration
    total = execute("SELECT COUNT(*) FROM project_members").first["count"].to_i
    admins = execute("SELECT COUNT(*) FROM project_members WHERE admin = true").first["count"].to_i
    members = total - admins
    
    say "  Total ProjectMembers: #{total}"
    say "  Admins (→ admin role): #{admins}"
    say "  Members (→ member role): #{members}"
    
    # Add role column
    say ""
    say "Adding role column..."
    add_column :project_members, :role, :integer, default: 0, null: false
    say "  ✓ Role column added"
    
    # Migrate admin=true to role=1
    say ""
    say "Migrating admin boolean to role enum..."
    execute("UPDATE project_members SET role = 1 WHERE admin = true")
    say "  ✓ Migrated #{admins} admins to role=1"
    
    # Remove admin column
    say ""
    say "Removing admin boolean column..."
    remove_column :project_members, :admin, :boolean
    say "  ✓ Admin column removed"
    
    # Add index
    say ""
    say "Adding performance index..."
    add_index :project_members, :role
    say "  ✓ Index added"
    
    say ""
    say "========================================="
    say "✅ Migration completed successfully!"
    say "========================================="
  end
  
  def down
    say "Rolling back to admin boolean..."
    
    # Remove index
    remove_index :project_members, :role
    
    # Add back admin column
    add_column :project_members, :admin, :boolean, default: false, null: false
    
    # Restore data from role enum
    # role >= 1 (admin or co_owner) → admin=true
    execute("UPDATE project_members SET admin = true WHERE role >= 1")
    
    # Remove role column
    remove_column :project_members, :role
    
    say "✅ Rollback complete!"
  end
end
