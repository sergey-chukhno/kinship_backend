class ConvertMembershipBooleanFlagsToRoleEnum < ActiveRecord::Migration[7.1]
  def up
    # ==========================================
    # PART 1: Add role columns
    # ==========================================
    say "Adding role columns..."
    add_column :user_companies, :role, :integer, default: 0, null: false
    add_column :user_schools, :role, :integer, default: 0, null: false

    # ==========================================
    # PART 2: Migrate UserCompany data
    # ==========================================
    say "Migrating UserCompany data..."

    # Count before migration
    total_user_companies = execute("SELECT COUNT(*) FROM user_companies").first["count"].to_i
    owners_count = execute("SELECT COUNT(*) FROM user_companies WHERE owner = true").first["count"].to_i
    admins_count = execute("SELECT COUNT(*) FROM user_companies WHERE admin = true AND owner = false").first["count"].to_i
    referents_count = execute("SELECT COUNT(*) FROM user_companies WHERE can_access_badges = true AND admin = false AND owner = false").first["count"].to_i

    say "  Total UserCompany records: #{total_user_companies}"
    say "  Owners (→ superadmin): #{owners_count}"
    say "  Admins (→ admin): #{admins_count}"
    say "  Referents (→ referent): #{referents_count}"
    say "  Members (→ member): #{total_user_companies - owners_count - admins_count - referents_count}"

    # Migrate to superadmin (role = 4)
    execute("UPDATE user_companies SET role = 4 WHERE owner = true")
    say "  ✓ Migrated #{owners_count} owners to superadmin"

    # Migrate to admin (role = 3)
    execute("UPDATE user_companies SET role = 3 WHERE admin = true AND owner = false")
    say "  ✓ Migrated #{admins_count} admins to admin"

    # Migrate to referent (role = 2)
    execute("UPDATE user_companies SET role = 2 WHERE can_access_badges = true AND admin = false AND owner = false")
    say "  ✓ Migrated #{referents_count} badge managers to referent"

    # ==========================================
    # PART 3: Migrate UserSchool data
    # ==========================================
    say "Migrating UserSchool data..."

    total_user_schools = execute("SELECT COUNT(*) FROM user_schools").first["count"].to_i
    owners_count = execute("SELECT COUNT(*) FROM user_schools WHERE owner = true").first["count"].to_i
    admins_count = execute("SELECT COUNT(*) FROM user_schools WHERE admin = true AND owner = false").first["count"].to_i
    referents_count = execute("SELECT COUNT(*) FROM user_schools WHERE can_access_badges = true AND admin = false AND owner = false").first["count"].to_i

    say "  Total UserSchool records: #{total_user_schools}"
    say "  Owners (→ superadmin): #{owners_count}"
    say "  Admins (→ admin): #{admins_count}"
    say "  Referents (→ referent): #{referents_count}"
    say "  Members (→ member): #{total_user_schools - owners_count - admins_count - referents_count}"

    execute("UPDATE user_schools SET role = 4 WHERE owner = true")
    say "  ✓ Migrated #{owners_count} owners to superadmin"

    execute("UPDATE user_schools SET role = 3 WHERE admin = true AND owner = false")
    say "  ✓ Migrated #{admins_count} admins to admin"

    execute("UPDATE user_schools SET role = 2 WHERE can_access_badges = true AND admin = false AND owner = false")
    say "  ✓ Migrated #{referents_count} badge managers to referent"

    # ==========================================
    # PART 4: Remove old columns
    # ==========================================
    say "Removing old boolean columns from user_companies..."

    remove_column :user_companies, :admin, :boolean
    remove_column :user_companies, :owner, :boolean
    remove_column :user_companies, :can_access_badges, :boolean
    remove_column :user_companies, :can_create_project, :boolean

    say "  ✓ Removed owner, admin, can_access_badges, can_create_project from user_companies"

    say "Removing old boolean columns from user_schools..."

    remove_column :user_schools, :admin, :boolean
    remove_column :user_schools, :owner, :boolean
    remove_column :user_schools, :can_access_badges, :boolean

    say "  ✓ Removed owner, admin, can_access_badges from user_schools"

    # ==========================================
    # PART 5: Add indexes
    # ==========================================
    say "Adding indexes for performance..."
    add_index :user_companies, :role
    add_index :user_schools, :role
    say "  ✓ Added role indexes"

    say "✅ Migration completed successfully!"
  end

  def down
    say "⚠️  Rolling back to boolean flags..."

    # Remove indexes
    remove_index :user_companies, :role
    remove_index :user_schools, :role

    # Add back old columns
    add_column :user_companies, :admin, :boolean, default: false, null: false
    add_column :user_companies, :owner, :boolean, default: false, null: false
    add_column :user_companies, :can_access_badges, :boolean, default: false
    add_column :user_companies, :can_create_project, :boolean, default: false

    add_column :user_schools, :admin, :boolean, default: false, null: false
    add_column :user_schools, :owner, :boolean, default: false, null: false
    add_column :user_schools, :can_access_badges, :boolean, default: false

    # Restore data from role enum - UserCompany
    execute("UPDATE user_companies SET owner = true, admin = true, can_access_badges = true, can_create_project = true WHERE role = 4")
    execute("UPDATE user_companies SET admin = true, can_access_badges = true, can_create_project = true WHERE role = 3")
    execute("UPDATE user_companies SET can_access_badges = true WHERE role = 2")
    execute("UPDATE user_companies SET can_access_badges = true WHERE role = 1")

    # Restore data from role enum - UserSchool
    execute("UPDATE user_schools SET owner = true, admin = true, can_access_badges = true WHERE role = 4")
    execute("UPDATE user_schools SET admin = true, can_access_badges = true WHERE role = 3")
    execute("UPDATE user_schools SET can_access_badges = true WHERE role = 2")
    execute("UPDATE user_schools SET can_access_badges = true WHERE role = 1")

    # Remove role columns
    remove_column :user_companies, :role
    remove_column :user_schools, :role

    say "✅ Rollback completed!"
  end
end
