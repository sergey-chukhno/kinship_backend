# Change #3: Member Roles System - Complete Implementation Plan

## Overview

**Objective:** Replace boolean permission flags (admin, owner, can_access_badges, can_create_project) with a unified role-based system (member, intervenant, referent, admin, superadmin).

**Approach:** Big Bang migration - Remove old columns, add role enum, update all code at once.

**Risk Level:** HIGH (structural change affecting ~30 files)

**Time Estimate:** 8-9 hours

---

## Executive Summary

### What's Changing

**FROM (Current):**
```ruby
UserCompany:
  - admin: boolean
  - owner: boolean
  - can_access_badges: boolean
  - can_create_project: boolean

UserSchool:
  - admin: boolean
  - owner: boolean
  - can_access_badges: boolean
```

**TO (New):**
```ruby
UserCompany & UserSchool:
  - role: enum {member: 0, intervenant: 1, referent: 2, admin: 3, superadmin: 4}
  
  superadmin (was owner):
    ✅ ALL permissions including partnerships & branches
    
  admin (was admin=true):
    ✅ Manage members (except superadmin)
    ✅ Manage projects
    ✅ Assign badges
    ❌ No partnerships
    ❌ No branches
    
  referent (was can_access_badges=true):
    ✅ Full rights over projects
    ✅ Assign badges
    ❌ No member management
    
  intervenant (new role):
    ✅ Assign badges in projects
    ❌ Limited permissions
    
  member (default):
    ✅ Participate in projects
    ✅ Receive badges
```

### Data Migration Strategy

**Conservative mapping (preserves highest privilege):**
```sql
-- UserCompany
UPDATE user_companies SET role = 4 WHERE owner = true;
UPDATE user_companies SET role = 3 WHERE admin = true AND owner = false;
UPDATE user_companies SET role = 2 WHERE can_access_badges = true AND admin = false AND owner = false;
-- role = 0 (member) is default for everyone else

-- UserSchool (same logic)
UPDATE user_schools SET role = 4 WHERE owner = true;
UPDATE user_schools SET role = 3 WHERE admin = true AND owner = false;
UPDATE user_schools SET role = 2 WHERE can_access_badges = true AND admin = false AND owner = false;
```

---

## Phase A: Database Migration (Step 1)

### File 1: Create Migration

**File:** `db/migrate/[timestamp]_convert_membership_boolean_flags_to_role_enum.rb`

**Full Migration Code:**
```ruby
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
    total_user_companies = UserCompany.count
    owners_count = UserCompany.where(owner: true).count
    admins_count = UserCompany.where(admin: true, owner: false).count
    referents_count = UserCompany.where(can_access_badges: true, admin: false, owner: false).count
    
    say "  Total UserCompany records: #{total_user_companies}"
    say "  Owners (→ superadmin): #{owners_count}"
    say "  Admins (→ admin): #{admins_count}"
    say "  Referents (→ referent): #{referents_count}"
    say "  Members (→ member): #{total_user_companies - owners_count - admins_count - referents_count}"
    
    # Migrate to superadmin
    UserCompany.where(owner: true).update_all(role: 4)
    say "  ✓ Migrated #{owners_count} owners to superadmin"
    
    # Migrate to admin
    UserCompany.where(admin: true, owner: false).update_all(role: 3)
    say "  ✓ Migrated #{admins_count} admins to admin"
    
    # Migrate to referent
    UserCompany.where(can_access_badges: true, admin: false, owner: false).update_all(role: 2)
    say "  ✓ Migrated #{referents_count} badge managers to referent"
    
    # ==========================================
    # PART 3: Migrate UserSchool data
    # ==========================================
    say "Migrating UserSchool data..."
    
    total_user_schools = UserSchool.count
    owners_count = UserSchool.where(owner: true).count
    admins_count = UserSchool.where(admin: true, owner: false).count
    referents_count = UserSchool.where(can_access_badges: true, admin: false, owner: false).count
    
    say "  Total UserSchool records: #{total_user_schools}"
    say "  Owners (→ superadmin): #{owners_count}"
    say "  Admins (→ admin): #{admins_count}"
    say "  Referents (→ referent): #{referents_count}"
    say "  Members (→ member): #{total_user_schools - owners_count - admins_count - referents_count}"
    
    UserSchool.where(owner: true).update_all(role: 4)
    say "  ✓ Migrated #{owners_count} owners to superadmin"
    
    UserSchool.where(admin: true, owner: false).update_all(role: 3)
    say "  ✓ Migrated #{admins_count} admins to admin"
    
    UserSchool.where(can_access_badges: true, admin: false, owner: false).update_all(role: 2)
    say "  ✓ Migrated #{referents_count} badge managers to referent"
    
    # ==========================================
    # PART 4: Remove old columns
    # ==========================================
    say "Removing old boolean columns..."
    
    remove_column :user_companies, :admin, :boolean
    remove_column :user_companies, :owner, :boolean
    remove_column :user_companies, :can_access_badges, :boolean
    remove_column :user_companies, :can_create_project, :boolean
    
    remove_column :user_schools, :admin, :boolean
    remove_column :user_schools, :owner, :boolean
    remove_column :user_schools, :can_access_badges, :boolean
    
    say "  ✓ Removed old columns"
    
    # ==========================================
    # PART 5: Add indexes
    # ==========================================
    say "Adding indexes..."
    add_index :user_companies, :role
    add_index :user_schools, :role
    say "  ✓ Added role indexes"
    
    say "Migration completed successfully!"
  end
  
  def down
    say "Rolling back to boolean flags..."
    
    # Add back old columns
    add_column :user_companies, :admin, :boolean, default: false, null: false
    add_column :user_companies, :owner, :boolean, default: false, null: false
    add_column :user_companies, :can_access_badges, :boolean, default: false
    add_column :user_companies, :can_create_project, :boolean, default: false
    
    add_column :user_schools, :admin, :boolean, default: false, null: false
    add_column :user_schools, :owner, :boolean, default: false, null: false
    add_column :user_schools, :can_access_badges, :boolean, default: false
    
    # Restore data from role enum - UserCompany
    UserCompany.where(role: 4).update_all(owner: true, admin: true, can_access_badges: true, can_create_project: true)
    UserCompany.where(role: 3).update_all(admin: true, can_access_badges: true, can_create_project: true)
    UserCompany.where(role: 2).update_all(can_access_badges: true)
    UserCompany.where(role: 1).update_all(can_access_badges: true)  # intervenant
    
    # Restore data from role enum - UserSchool
    UserSchool.where(role: 4).update_all(owner: true, admin: true, can_access_badges: true)
    UserSchool.where(role: 3).update_all(admin: true, can_access_badges: true)
    UserSchool.where(role: 2).update_all(can_access_badges: true)
    UserSchool.where(role: 1).update_all(can_access_badges: true)  # intervenant
    
    # Remove indexes
    remove_index :user_companies, :role
    remove_index :user_schools, :role
    
    # Remove role columns
    remove_column :user_companies, :role
    remove_column :user_schools, :role
    
    say "Rollback completed!"
  end
end
```

---

## Phase B: Model Updates (Steps 2-6)

### File 2: UserCompany Model

**File:** `app/models/user_company.rb`

**BEFORE:**
```ruby
class UserCompany < ApplicationRecord
  belongs_to :user
  belongs_to :company

  enum :status, {pending: 0, confirmed: 1}, default: :pending

  validates :status, presence: true
  validates :user_id, uniqueness: {scope: :company_id}
  validate :unique_owner_by_company

  after_validation :set_admin_if_owner, :set_create_project_if_admin, :set_access_badges_if_admin

  # ... existing methods
end
```

**AFTER:**
```ruby
class UserCompany < ApplicationRecord
  belongs_to :user
  belongs_to :company

  enum :status, {pending: 0, confirmed: 1}, default: :pending
  enum :role, {
    member: 0,
    intervenant: 1,
    referent: 2,
    admin: 3,
    superadmin: 4
  }, default: :member

  validates :status, :role, presence: true
  validates :user_id, uniqueness: {scope: :company_id}
  validate :unique_superadmin_by_company

  # Permission check methods (NEW)
  def can_manage_members?
    admin? || superadmin?
  end

  def can_manage_superadmins?
    false  # Only from system/super_admin user
  end

  def can_manage_projects?
    referent? || admin? || superadmin?
  end

  def can_assign_badges?
    intervenant? || referent? || admin? || superadmin?
  end

  def can_manage_partnerships?
    superadmin?
  end

  def can_manage_branches?
    superadmin?
  end

  def can_create_project?
    referent? || admin? || superadmin?
  end

  def is_owner?
    superadmin?
  end

  # Alias for backward compatibility (temporary during transition)
  alias_method :owner?, :superadmin?

  private

  def unique_superadmin_by_company
    return unless superadmin?
    return if self == self.class.find_by(role: :superadmin, company_id: company_id)
    return if self.class.where(role: :superadmin, company_id: company_id).count.zero?

    errors.add(:role, "Il ne peut y avoir qu'un seul superadmin par entreprise")
  end
end
```

**Removed:**
- `validate :unique_owner_by_company` (replaced with unique_superadmin)
- `after_validation :set_admin_if_owner` (no longer needed)
- `after_validation :set_create_project_if_admin` (no longer needed)
- `after_validation :set_access_badges_if_admin` (no longer needed)
- All old methods that reference owner/admin flags

---

### File 3: UserSchool Model

**File:** `app/models/user_school.rb`

**AFTER:**
```ruby
class UserSchool < ApplicationRecord
  after_create :set_status

  belongs_to :school
  belongs_to :user

  enum :status, {pending: 0, confirmed: 1}, default: :pending
  enum :role, {
    member: 0,
    intervenant: 1,
    referent: 2,
    admin: 3,
    superadmin: 4
  }, default: :member

  validates :status, :role, presence: true
  validates :user_id, uniqueness: {scope: :school_id}
  validate :unique_superadmin_by_school

  # Permission check methods (NEW)
  def can_manage_members?
    admin? || superadmin?
  end

  def can_manage_projects?
    referent? || admin? || superadmin?
  end

  def can_assign_badges?
    intervenant? || referent? || admin? || superadmin?
  end

  def can_manage_partnerships?
    superadmin?
  end

  def can_manage_branches?
    superadmin?
  end

  def is_owner?
    superadmin?
  end

  # Alias for backward compatibility
  alias_method :owner?, :superadmin?

  private

  def unique_superadmin_by_school
    return unless superadmin?
    return if self == self.class.find_by(role: :superadmin, school_id: school_id)
    return if self.class.where(role: :superadmin, school_id: school_id).count.zero?

    errors.add(:role, "Il ne peut y avoir qu'un seul superadmin par établissement")
  end

  def set_status
    return update(status: :confirmed) unless user.teacher?

    update(status: :pending)
  end
end
```

**Removed:**
- `validate :unique_owner_by_school`
- `after_validation :set_admin_if_owner`
- `after_validation :set_access_badges_if_admin`

---

### File 4: User Model

**File:** `app/models/user.rb`

**Methods to UPDATE:**

```ruby
# BEFORE:
def schools_admin
  user_schools.where(admin: true, status: :confirmed).map(&:school)
end

# AFTER:
def schools_admin
  user_schools.where(role: [:admin, :superadmin], status: :confirmed).map(&:school)
end

# BEFORE:
def schools_only_badges_access
  user_schools.where(status: :confirmed, admin: false, can_access_badges: true).map(&:school)
end

# AFTER:
def schools_with_badge_access
  user_schools.where(
    status: :confirmed, 
    role: [:intervenant, :referent, :admin, :superadmin]
  ).map(&:school)
end

# BEFORE:
def companies_admin
  user_company.where(admin: true, status: :confirmed).map(&:company)
end

# AFTER:
def companies_admin
  user_company.where(role: [:admin, :superadmin], status: :confirmed).map(&:company)
end

# BEFORE:
def companies_only_badges_access
  user_company.where(status: :confirmed, admin: false, can_access_badges: true).map(&:company)
end

# AFTER:
def companies_with_badge_access
  user_company.where(
    status: :confirmed,
    role: [:intervenant, :referent, :admin, :superadmin]
  ).map(&:company)
end

# BEFORE:
def projects_owner
  project_ids_where_user_is_admin = project_members.where(admin: true).pluck(:project_id)
  project_ids_where_user_is_owner = projects.pluck(:id)

  Project.where(id: project_ids_where_user_is_admin + project_ids_where_user_is_owner)
end

# AFTER: (no change - project_members is separate from organization roles)

# BEFORE:
def school_admin?(school)
  user_schools.find_by(school:)&.admin
end

# AFTER:
def school_admin?(school)
  us = user_schools.find_by(school:)
  us&.admin? || us&.superadmin?
end

# BEFORE:
def company_admin?(company)
  user_company.find_by(company:)&.admin
end

# AFTER:
def company_admin?(company)
  uc = user_company.find_by(company:)
  uc&.admin? || uc&.superadmin?
end

# NEW METHOD:
def school_superadmin?(school)
  user_schools.find_by(school:)&.superadmin?
end

# NEW METHOD:
def company_superadmin?(company)
  user_company.find_by(company:)&.superadmin?
end

# UPDATE:
def can_give_badges?
  schools = user_schools.where(role: [:intervenant, :referent, :admin, :superadmin])
  companies = user_company.where(role: [:intervenant, :referent, :admin, :superadmin])

  schools.any? || companies.any?
end
```

---

### File 5: Company Model

**File:** `app/models/company.rb`

**Methods to UPDATE:**

```ruby
# BEFORE:
def owner?
  user_companies.where(owner: true).any?
end

# AFTER:
def owner?
  user_companies.where(role: :superadmin).any?
end

# BEFORE:
def owner
  user_companies.find_by(owner: true)
end

# AFTER:
def owner
  user_companies.find_by(role: :superadmin)
end

# BEFORE:
def admins?
  user_companies.where(admin: true).any?
end

# AFTER:
def admins?
  user_companies.where(role: [:admin, :superadmin]).any?
end

# BEFORE:
def admins
  user_companies.where(admin: true)
end

# AFTER:
def admins
  user_companies.where(role: [:admin, :superadmin])
end

# BEFORE:
def admin_user?(user)
  user_companies.find_by(user: user, admin: true).present?
end

# AFTER:
def admin_user?(user)
  uc = user_companies.find_by(user: user)
  uc&.admin? || uc&.superadmin?
end

# NEW METHOD:
def superadmin_user?(user)
  user_companies.find_by(user: user)&.superadmin?
end
```

---

### File 6: School Model

**File:** `app/models/school.rb`

**Methods to UPDATE:**

```ruby
# BEFORE:
def owner?
  user_schools.where(owner: true).any?
end

# AFTER:
def owner?
  user_schools.where(role: :superadmin).any?
end

# BEFORE:
def owner
  user_schools.find_by(owner: true)
end

# AFTER:
def owner
  user_schools.find_by(role: :superadmin)
end

# BEFORE:
def admins?
  user_schools.where(admin: true).any?
end

# AFTER:
def admins?
  user_schools.where(role: [:admin, :superadmin]).any?
end

# BEFORE:
def admins
  user_schools.where(admin: true)
end

# AFTER:
def admins
  user_schools.where(role: [:admin, :superadmin])
end

# NEW METHOD:
def superadmin_user?(user)
  user_schools.find_by(user: user)&.superadmin?
end
```

---

### File 7: Contract Model

**File:** `app/models/contract.rb`

**Validations to UPDATE:**

```ruby
# BEFORE:
def school_has_owner
  return if school&.owner?

  errors.add(:school, "L'établissement doit avoir un propriétaire pour pouvoir signer un contrat")
end

# AFTER:
def school_has_owner
  return if school&.owner?  # This method already updated in School model

  errors.add(:school, "L'établissement doit avoir un superadmin pour pouvoir signer un contrat")
end

# BEFORE:
def company_has_owner
  return if company&.owner?

  errors.add(:company, "L'association doit avoir un propriétaire pour pouvoir signer un contrat")
end

# AFTER:
def company_has_owner
  return if company&.owner?  # This method already updated in Company model

  errors.add(:company, "L'association doit avoir un superadmin pour pouvoir signer un contrat")
end
```

---

### File 8: ProjectMember Model

**File:** `app/models/project_member.rb`

**Check if this is affected:**
```ruby
# Current code:
after_validation :set_admin_if_project_owner

def set_admin_if_project_owner
  return if admin?
  return unless project.owner == user

  update(admin: true)
end
```

**Status:** ✅ NO CHANGE NEEDED
- ProjectMember.admin is for project-level admin (separate from organization roles)
- This is correct and should remain unchanged

---

## Phase C: Controller Updates (Steps 7-21)

### Controllers Affected: 15 Files

#### File 9: SchoolAdminPanel::SchoolMembersController

**File:** `app/controllers/school_admin_panel/school_members_controller.rb`

**Lines to find and UPDATE:**

```ruby
# BEFORE:
def update_admin
  @user_school.update(admin: params[:admin])
end

# AFTER:
def update_role
  new_role = params[:role]
  
  # Prevent non-superadmin from creating superadmin
  if new_role == 'superadmin' && !current_user.school_superadmin?(@user_school.school)
    return render_error("Seul un superadmin peut nommer un autre superadmin")
  end
  
  @user_school.update(role: new_role)
end

# BEFORE:
def update_can_access_badges
  @user_school.update(can_access_badges: params[:can_access_badges])
end

# AFTER:
# This endpoint can be removed - role handles this now
# OR keep for backward compat but map to role changes
def update_can_access_badges
  # If setting to true and current role is member, upgrade to intervenant
  if params[:can_access_badges] == 'true' && @user_school.member?
    @user_school.update(role: :intervenant)
  elsif params[:can_access_badges] == 'false'
    @user_school.update(role: :member)
  end
end
```

**Authorization checks:**
```ruby
# BEFORE:
before_action :ensure_admin

def ensure_admin
  redirect_to root_path unless current_user.school_admin?(@school)
end

# AFTER:
before_action :ensure_can_manage_members

def ensure_can_manage_members
  user_school = current_user.user_schools.find_by(school: @school)
  
  unless user_school&.can_manage_members?
    flash[:alert] = "Vous n'avez pas les droits pour gérer les membres"
    redirect_to root_path
  end
end
```

---

#### File 10: CompanyAdminPanel::CompanyMembersController

**File:** `app/controllers/company_admin_panel/company_members_controller.rb`

**Similar updates as SchoolMembersController:**
- Replace `update_admin` with `update_role`
- Add superadmin protection
- Update authorization checks

---

#### File 11: ProjectAdminPanel::ProjectMembersController

**File:** `app/controllers/project_admin_panel/project_members_controller.rb`

**Check:** Likely uses project-level admin, not organization admin
**Status:** Probably no changes needed (verify during implementation)

---

### All Controllers to Review:

```
1. ✅ school_admin_panel/school_members_controller.rb
2. ✅ school_admin_panel/base_controller.rb
3. ✅ school_admin_panel/badges_controller.rb
4. ✅ school_admin_panel/partnerships_controller.rb
5. ✅ company_admin_panel/company_members_controller.rb
6. ✅ company_admin_panel/base_controller.rb
7. ✅ company_admin_panel/badges_controller.rb
8. ✅ company_admin_panel/partnerships_controller.rb
9. ✅ assign_badge_stepper/* (check badge assignment logic)
10. ✅ account/* (user managing their own memberships)
```

---

## Phase D: Policy Updates (Steps 22-31)

### Policies Affected: ~10 Files

#### File 12: SchoolAdminPanel::BasePolicy

**File:** `app/policies/school_admin_panel/base_policy.rb`

**BEFORE:**
```ruby
def manage?
  user.school_admin?(record.school)
end
```

**AFTER:**
```ruby
def manage?
  user_school = user.user_schools.find_by(school: record.school)
  user_school&.can_manage_members? || user_school&.can_manage_projects?
end

def manage_members?
  user_school = user.user_schools.find_by(school: record.school)
  user_school&.can_manage_members?
end

def manage_partnerships?
  user_school = user.user_schools.find_by(school: record.school)
  user_school&.can_manage_partnerships?
end
```

---

#### File 13: CompanyAdminPanel::BasePolicy

**File:** `app/policies/company_admin_panel/base_policy.rb`

**Similar updates as SchoolAdminPanel::BasePolicy**

---

#### File 14: CompanyPolicy

**File:** `app/policies/company_policy.rb`

**Current code to review and update based on new role permissions**

---

### All Policies to Review:

```
1. ✅ school_admin_panel/base_policy.rb
2. ✅ school_admin_panel/badges_policy.rb
3. ✅ company_admin_panel/base_policy.rb
4. ✅ company_admin_panel/badges_policy.rb
5. ✅ company_policy.rb
6. ✅ school_policy.rb
7. ✅ assign_badge_policy.rb
8. ✅ active_admin/company_policy.rb
9. ✅ active_admin/school_policy.rb
10. ✅ active_admin/user_company_policy.rb
11. ✅ active_admin/user_school_policy.rb
```

---

## Phase E: Test Updates (Steps 32-40)

### File 15: Factories

**File:** `spec/factories/user_companies.rb`

**BEFORE:**
```ruby
FactoryBot.define do
  factory :user_company do
    user
    company
    status { :pending }

    trait :confirmed do
      status { :confirmed }
    end

    trait :admin do
      admin { true }
    end

    trait :owner do
      owner { true }
    end
  end
end
```

**AFTER:**
```ruby
FactoryBot.define do
  factory :user_company do
    user
    company
    status { :pending }
    role { :member }

    trait :confirmed do
      status { :confirmed }
    end

    trait :member do
      role { :member }
    end

    trait :intervenant do
      role { :intervenant }
    end

    trait :referent do
      role { :referent }
    end

    trait :admin do
      role { :admin }
    end

    trait :superadmin do
      role { :superadmin }
    end

    # Legacy aliases (temporary)
    trait :owner do
      role { :superadmin }
    end
  end
end
```

---

### File 16: UserSchool Factory

**File:** `spec/factories/user_schools.rb`

**Similar updates as user_companies.rb**

---

### Model Specs to Update:

```
1. ✅ spec/models/user_company_spec.rb
2. ✅ spec/models/user_school_spec.rb
3. ✅ spec/models/user_spec.rb
4. ✅ spec/models/company_spec.rb
5. ✅ spec/models/school_spec.rb
6. ✅ spec/models/contract_spec.rb
```

### Request Specs to Update:

```
1. ✅ spec/requests/company_admin_panel/*
2. ✅ spec/requests/school_admin_panel/*
3. ✅ Any specs creating user_companies or user_schools with admin/owner traits
```

---

## Phase F: Routes (if needed)

### File 17: Routes

**File:** `config/routes.rb`

**Lines to check:**

```ruby
# BEFORE:
put "school_members/update_admin/:id", to: "school_members#update_admin"
put "school_members/update_can_access_badges/:id", to: "school_members#update_can_access_badges"

put "company_members/update_admin/:id", to: "company_members#update_admin"
put "company_members/update_can_access_badges/:id", to: "company_members#update_can_access_badges"

# AFTER:
put "school_members/update_role/:id", to: "school_members#update_role"
# Remove update_can_access_badges route (handled by role)

put "company_members/update_role/:id", to: "company_members#update_role"
# Remove update_can_access_badges route
```

---

## Complete File Change List

### Database (2 files)
- [x] `db/migrate/[timestamp]_convert_membership_boolean_flags_to_role_enum.rb` - NEW
- [x] `db/schema.rb` - AUTO UPDATED

### Models (7 files)
- [x] `app/models/user_company.rb` - Add role enum, update methods
- [x] `app/models/user_school.rb` - Add role enum, update methods
- [x] `app/models/user.rb` - Update helper methods
- [x] `app/models/company.rb` - Update owner/admin methods
- [x] `app/models/school.rb` - Update owner/admin methods
- [x] `app/models/contract.rb` - Update validation messages
- [ ] `app/models/project_member.rb` - Verify no changes needed

### Controllers (15+ files)
- [x] `app/controllers/school_admin_panel/school_members_controller.rb`
- [x] `app/controllers/school_admin_panel/base_controller.rb`
- [x] `app/controllers/school_admin_panel/badges_controller.rb`
- [x] `app/controllers/school_admin_panel/partnerships_controller.rb`
- [x] `app/controllers/company_admin_panel/company_members_controller.rb`
- [x] `app/controllers/company_admin_panel/base_controller.rb`
- [x] `app/controllers/company_admin_panel/badges_controller.rb`
- [x] `app/controllers/company_admin_panel/partnerships_controller.rb`
- [x] `app/controllers/assign_badge_stepper/*_controller.rb` (check all 6)
- [x] `app/controllers/account/schools_controller.rb`
- [x] `app/controllers/companies_controller.rb`
- [x] `app/controllers/schools_controller.rb`

### Policies (11 files)
- [x] `app/policies/school_admin_panel/base_policy.rb`
- [x] `app/policies/school_admin_panel/badges_policy.rb`
- [x] `app/policies/company_admin_panel/base_policy.rb`
- [x] `app/policies/company_admin_panel/badges_policy.rb`
- [x] `app/policies/company_policy.rb`
- [x] `app/policies/school_policy.rb`
- [x] `app/policies/assign_badge_policy.rb`
- [x] `app/policies/active_admin/company_policy.rb`
- [x] `app/policies/active_admin/school_policy.rb`
- [x] `app/policies/active_admin/user_company_policy.rb`
- [x] `app/policies/active_admin/user_school_policy.rb`

### Routes (1 file)
- [x] `config/routes.rb` - Update admin/badge routes

### Factories (2 files)
- [x] `spec/factories/user_companies.rb` - Add role traits
- [x] `spec/factories/user_schools.rb` - Add role traits

### Specs (20+ files)
- [x] `spec/models/user_company_spec.rb`
- [x] `spec/models/user_school_spec.rb`
- [x] `spec/models/user_spec.rb`
- [x] `spec/models/company_spec.rb`
- [x] `spec/models/school_spec.rb`
- [x] `spec/models/contract_spec.rb`
- [x] `spec/requests/company_admin_panel/*`
- [x] `spec/requests/school_admin_panel/*`
- [x] All specs using admin/owner traits

---

## Implementation Phases

### Phase A: Database & Core Models (2 hours)
1. Create migration file
2. Backup database
3. Run migration on development
4. Run migration on test
5. Verify data migrated correctly
6. Update UserCompany model
7. Update UserSchool model
8. Update User model helper methods
9. Update Company model
10. Update School model
11. Update Contract model
12. Test all models still instantiate

### Phase B: Controllers (2-3 hours)
13. Update school_admin_panel controllers (4 files)
14. Update company_admin_panel controllers (4 files)
15. Update assign_badge_stepper controllers (6 files)
16. Update other affected controllers
17. Update routes if needed

### Phase C: Policies (1 hour)
18. Update school_admin_panel policies
19. Update company_admin_panel policies
20. Update main policies (company, school)
21. Update ActiveAdmin policies

### Phase D: Tests (2-3 hours)
22. Update factories
23. Update model specs
24. Update request specs
25. Run full test suite
26. Fix all failures

### Phase E: Verification (1 hour)
27. Manual testing in Rails console
28. Test critical workflows
29. Verify permissions work correctly
30. Update CHANGE_LOG.md
31. Commit changes

---

## Risk Mitigation

### Backup Strategy

**Before migration:**
```bash
# Backup production-like data
pg_dump kinship_development > backups/before_role_migration_$(date +%Y%m%d).sql

# Test on copy first
createdb kinship_development_test_migration
pg_restore -d kinship_development_test_migration backups/before_role_migration_*.sql
# Run migration on test DB
# Verify
# Then apply to real DB
```

### Rollback Plan

**If migration fails:**
```bash
rails db:rollback
# This will reverse the migration using the 'down' method
# Restores old boolean columns
# Restores data from role enum
```

**If code issues discovered after migration:**
- Can't rollback easily (would need new migration)
- Better to fix forward
- This is why comprehensive testing is critical

---

## Testing Checklist

### Unit Tests
- [ ] UserCompany role enum works
- [ ] UserSchool role enum works
- [ ] Permission methods return correct values
- [ ] Superadmin can't be duplicated
- [ ] Role transitions work correctly

### Integration Tests
- [ ] School admin can manage members
- [ ] School superadmin can manage partnerships
- [ ] Company admin can manage projects
- [ ] Company superadmin can manage branches
- [ ] Referent can assign badges
- [ ] Intervenant can assign badges in projects
- [ ] Member has limited permissions

### Permission Matrix Tests
- [ ] member: Can participate, receive badges
- [ ] intervenant: Can assign badges
- [ ] referent: Can manage projects + assign badges
- [ ] admin: Can manage members (except superadmin) + projects + badges
- [ ] superadmin: Can do everything

---

## Success Criteria

✅ Migration runs without errors  
✅ All existing users migrated to appropriate roles  
✅ No data loss  
✅ All model tests pass  
✅ All request tests pass  
✅ Manual testing of critical workflows passes  
✅ Permission matrix validated  
✅ Rollback plan tested (on copy)  

---

## Estimated Impact

**Files to Modify:** ~45 files
**Lines Changed:** ~500-700 lines
**Test Updates:** ~200-300 lines
**Time Required:** 8-9 hours
**Risk Level:** HIGH
**Complexity:** VERY HIGH

---

## Next Steps - Awaiting Your Approval

**This plan covers:**
✅ Complete migration with data preservation  
✅ All model updates  
✅ All controller updates  
✅ All policy updates  
✅ All test updates  
✅ Comprehensive testing strategy  
✅ Backup and rollback plans  

**Before I implement, please confirm:**

1. ✅ You've reviewed the plan
2. ✅ Data migration strategy is correct (owner → superadmin, admin → admin, badges → referent)
3. ✅ Permission matrix matches your requirements
4. ✅ You want to proceed with implementation

**Shall I proceed with Phase A: Database & Core Models?** 

I'll implement it step-by-step and keep you updated on progress. 🎯
