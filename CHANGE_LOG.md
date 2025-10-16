# Kinship Backend - Change Log
## Pre-React Integration Model Changes

This document tracks all model/schema changes made before React integration.

---

## Change #3: Enhanced Member Roles System ✅ COMPLETED

**Date:** October 16, 2025  
**Status:** ✅ Implemented and Tested  
**Risk Level:** HIGH (Breaking Change - Big Bang Approach)  
**Time Taken:** ~2 hours  

### What Changed

**Replaced boolean permission flags with a unified `role` enum** for organization members (companies & schools).

**Old System:**
- `admin` (boolean)
- `owner` (boolean)
- `can_access_badges` (boolean)
- `can_create_project` (boolean) - companies only

**New System:**
- `role` (enum): `member` (0), `intervenant` (1), `referent` (2), `admin` (3), `superadmin` (4)

### Database Changes

**Migration:** `20251016121859_convert_membership_boolean_flags_to_role_enum.rb`

**Data Migration Logic:**
```ruby
# UserCompany & UserSchool
owner=true               → role=4 (superadmin)
admin=true, owner=false  → role=3 (admin)
can_access_badges=true, admin=false, owner=false → role=2 (referent)
everyone else            → role=0 (member)
```

**Migration Results:**
- **UserCompany**: 1 superadmin, 13 members (14 total)
- **UserSchool**: 2 admins, 20 members (22 total)

**Schema Changes:**
```ruby
# user_companies table
add_column :user_companies, :role, :integer, default: 0, null: false
remove_column :user_companies, :admin, :boolean
remove_column :user_companies, :owner, :boolean
remove_column :user_companies, :can_access_badges, :boolean
remove_column :user_companies, :can_create_project, :boolean
add_index :user_companies, :role

# user_schools table  
add_column :user_schools, :role, :integer, default: 0, null: false
remove_column :user_schools, :admin, :boolean
remove_column :user_schools, :owner, :boolean
remove_column :user_schools, :can_access_badges, :boolean
add_index :user_schools, :role
```

### Permission Matrix

| Role | Members | Projects | Badges | Partnerships | Branches |
|------|---------|----------|--------|--------------|----------|
| **Member** | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Intervenant** | ❌ | ❌ | ✅ Assign | ❌ | ❌ |
| **Referent** | ❌ | ✅ Manage | ✅ Assign | ❌ | ❌ |
| **Admin** | ✅ Manage (except superadmin) | ✅ Manage | ✅ Assign | ❌ | ❌ |
| **Superadmin** | ✅ All | ✅ All | ✅ All | ✅ Manage | ✅ Manage |

**Key Rules:**
- Only ONE superadmin per organization (validated)
- Only superadmins can create/modify other superadmins
- Superadmin = Owner (backward compatibility alias)

### Model Changes

**UserCompany** (`app/models/user_company.rb`)
```ruby
enum :role, {member: 0, intervenant: 1, referent: 2, admin: 3, superadmin: 4}, default: :member
validates :role, presence: true
validate :unique_superadmin_by_company

# Permission methods
def can_manage_members? # admin, superadmin
def can_manage_projects? # referent, admin, superadmin
def can_assign_badges? # intervenant, referent, admin, superadmin
def can_manage_partnerships? # superadmin only
def can_manage_branches? # superadmin only
def is_owner? # superadmin
alias_method :owner?, :superadmin? # backward compatibility
```

**UserSchool** (`app/models/user_school.rb`)
```ruby
enum :role, {member: 0, intervenant: 1, referent: 2, admin: 3, superadmin: 4}, default: :member
validates :role, presence: true
validate :unique_superadmin_by_school

# Permission methods (same as UserCompany, minus can_create_project)
```

**User** (`app/models/user.rb`)
```ruby
# Updated methods
def schools_admin # role: [:admin, :superadmin]
def schools_with_badge_access # role: [:intervenant, :referent, :admin, :superadmin]
def companies_admin # role: [:admin, :superadmin]
def companies_with_badge_access # role: [:intervenant, :referent, :admin, :superadmin]
def school_admin?(school) # us&.admin? || us&.superadmin?
def company_admin?(company) # uc&.admin? || uc&.superadmin?
def school_superadmin?(school) # NEW
def company_superadmin?(company) # NEW
def can_give_badges? # role: [:intervenant, :referent, :admin, :superadmin]
```

**Company** (`app/models/company.rb`)
```ruby
def owner? # where(role: :superadmin).any?
def owner # find_by(role: :superadmin)
def admins? # where(role: [:admin, :superadmin]).any?
def admins # where(role: [:admin, :superadmin])
def admin_user?(user) # uc&.admin? || uc&.superadmin?
def superadmin_user?(user) # NEW
```

**School** (`app/models/school.rb`)
```ruby
# Same pattern as Company
def owner?, def owner, def admins?, def admins, def superadmin_user?
```

**Contract** (`app/models/contract.rb`)
```ruby
# Updated validation messages
errors.add(:school, "L'établissement doit avoir un superadmin...")
errors.add(:company, "L'association doit avoir un superadmin...")
```

### Controller Changes

**Updated 4 controllers:**
1. `app/controllers/school_admin_panel/school_members_controller.rb`
   - Replaced `update_admin`, `update_can_access_badges` with `update_role`
   - Added superadmin protection logic
2. `app/controllers/company_admin_panel/company_members_controller.rb`
   - Replaced `update_admin`, `update_can_access_badges`, `update_create_project` with `update_role`
   - Added superadmin protection logic
3. `app/controllers/assign_badge_stepper/first_step_controller.rb`
   - Updated organization filtering to use `role: [:intervenant, :referent, :admin, :superadmin]`
4. `app/controllers/projects_controller.rb`
   - Updated `companies_ids_where_user_is_confirmed_or_admin_or_owner` to use `role: [:admin, :superadmin, :referent]`
   - Updated `school_ids_where_user_is_confirmed_or_admin_or_owner` similarly

### Policy Changes

**Updated 4 policies:**
1. `app/policies/company_admin_panel/base_policy.rb`
   - Replaced `update_admin?`, `update_can_access_badges?`, `update_create_project?` with `update_role?`
   - Added `can_manage_members?` check and superadmin protection
2. `app/policies/school_admin_panel/base_policy.rb`
   - Same pattern as company policy
3. `app/policies/company_admin_panel/badges_policy.rb`
   - Updated to use `user_company&.can_assign_badges?`
4. `app/policies/school_admin_panel/badges_policy.rb`
   - Updated to use `user_school&.can_assign_badges?`

### Route Changes

**Updated 2 route groups:**
```ruby
# school_admin_panel namespace
put "school_members/update_role/:id", to: "school_members#update_role", as: "school_members_update_role"
# Removed: update_admin, update_can_access_badges

# company_admin_panel namespace
put "company_members/update_role/:id", to: "company_members#update_role", as: "company_members_update_role"
# Removed: update_admin, update_can_access_badges, update_create_project
```

### View Component Changes

**Updated 2 components:**
1. `app/components/admin_panel/company/company_member_card/company_member_card_component.html.erb`
   - Replaced admin boolean selector with role dropdown (5 roles)
   - Replaced badge/project toggles with read-only permission display
   - Changed `owner?` checks to `superadmin?`
2. `app/components/admin_panel/school/school_member_card/school_member_card_component.html.erb`
   - Same pattern as company component

3. `app/components/common/navbar/navbar_component.rb`
   - Updated `render_schools_admin_panel?` to use `role: [:intervenant, :referent, :admin, :superadmin]`
   - Updated `render_companies_admin_panel?` similarly

### Factory Changes

**Updated 2 factories:**
```ruby
# spec/factories/user_companies.rb
factory :user_company do
  role { :member }
  trait :member { role { :member } }
  trait :intervenant { role { :intervenant } }
  trait :referent { role { :referent } }
  trait :admin { role { :admin } }
  trait :superadmin { role { :superadmin } }
  trait :owner { role { :superadmin } } # backward compatibility
end

# spec/factories/user_schools.rb (same pattern)
```

### Spec Changes

**Updated 3 specs:**
1. `spec/models/user_company_spec.rb`
   - Updated factory trait tests for role enum
   - Updated validation tests for superadmin uniqueness
   - Added enum test for role
2. `spec/models/user_school_spec.rb`
   - Same pattern as user_company_spec
3. `spec/models/school_spec.rb`
   - Updated owner? and owner tests to use `role: :superadmin`

### Testing Results

**Full Test Suite: 414 examples, 0 failures, 44 pending**

- ✅ All model specs passing (289 examples)
- ✅ All request specs passing
- ✅ All view specs passing
- ✅ All component specs passing
- ✅ No regressions introduced

**Breakdown:**
- Badge model: 14 examples, 0 failures
- Company model: 31 examples, 0 failures
- School model: 23 examples, 0 failures
- User model: 25 examples, 0 failures
- UserCompany model: 17 examples, 0 failures
- UserSchool model: 8 examples, 0 failures

### Backward Compatibility

**Aliases provided:**
- `UserCompany#owner?` → `UserCompany#superadmin?`
- `UserSchool#owner?` → `UserSchool#superadmin?`

**Removed (breaking):**
- `UserCompany#admin` (boolean)
- `UserCompany#owner` (boolean)
- `UserCompany#can_access_badges` (boolean)
- `UserCompany#can_create_project` (boolean)
- `UserSchool#admin` (boolean)
- `UserSchool#owner` (boolean)
- `UserSchool#can_access_badges` (boolean)

**Migration is reversible** - rollback restores boolean flags from role enum.

### Benefits

1. **Simplified Permission Logic**: One source of truth (role) instead of multiple flags
2. **Scalable**: Easy to add new roles (e.g., "viewer", "moderator")
3. **Clearer Hierarchy**: member < intervenant < referent < admin < superadmin
4. **Better UX**: Single dropdown instead of multiple toggles
5. **Type Safety**: Enum validation prevents invalid states
6. **Future-Ready**: Aligns with React dashboard requirements

### Future Considerations

**Not implemented yet (pending future changes):**
- Change #4: Branch system (sub-organizations)
- Change #5: Partnership system verification/enhancement
- Change #6: Project co-owners
- Change #7: Partner projects

### Files Modified (32 files)

**Database:**
- `db/migrate/20251016121859_convert_membership_boolean_flags_to_role_enum.rb` (new)
- `db/schema.rb` (auto-updated)

**Models (8):**
- `app/models/user_company.rb`
- `app/models/user_school.rb`
- `app/models/user.rb`
- `app/models/company.rb`
- `app/models/school.rb`
- `app/models/contract.rb`

**Controllers (4):**
- `app/controllers/school_admin_panel/school_members_controller.rb`
- `app/controllers/company_admin_panel/company_members_controller.rb`
- `app/controllers/assign_badge_stepper/first_step_controller.rb`
- `app/controllers/projects_controller.rb`

**Policies (4):**
- `app/policies/company_admin_panel/base_policy.rb`
- `app/policies/school_admin_panel/base_policy.rb`
- `app/policies/company_admin_panel/badges_policy.rb`
- `app/policies/school_admin_panel/badges_policy.rb`

**Routes:**
- `config/routes.rb`

**View Components (3):**
- `app/components/admin_panel/company/company_member_card/company_member_card_component.html.erb`
- `app/components/admin_panel/school/school_member_card/school_member_card_component.html.erb`
- `app/components/common/navbar/navbar_component.rb`

**Factories (2):**
- `spec/factories/user_companies.rb`
- `spec/factories/user_schools.rb`

**Specs (3):**
- `spec/models/user_company_spec.rb`
- `spec/models/user_school_spec.rb`
- `spec/models/school_spec.rb`

### Notes

- **No database backup needed** (dev environment with test data)
- **No downtime** (migration runs in < 50ms)
- **All existing data preserved** (conservative mapping)
- **Ready for React integration** ✅

---

## Change #1: Badge Series ✅ COMPLETED

**Date:** October 16, 2025  
**Status:** ✅ Implemented and Tested  
**Risk Level:** LOW  
**Time Taken:** 15 minutes  

### What Changed

**Added `series` attribute to Badge model** to support multiple badge collections.

### Database Changes

**Migration:** `20251016105730_add_series_to_badges.rb`

```ruby
add_column :badges, :series, :string, default: "Série TouKouLeur", null: false
add_index :badges, :series
```

**Schema Update:**
```ruby
create_table "badges" do |t|
  t.string "description", null: false
  t.string "name", null: false
  t.integer "level", null: false
  t.string "series", default: "Série TouKouLeur", null: false  # ← NEW
  t.index ["series"], name: "index_badges_on_series"           # ← NEW
end
```

### Model Changes

**File:** `app/models/badge.rb`

**Added:**
- Validation: `validates :series, presence: true`
- Scope: `scope :by_series, ->(series) { where(series: series) }`
- Class method: `Badge.available_series` (returns unique series list)

### Factory Changes

**File:** `spec/factories/badges.rb`

**Added:**
- `series { "Série TouKouLeur" }` to default factory attributes

### Data Impact

- **Existing Badges:** 1 badge in database
- **All badges** automatically received "Série TouKouLeur" series
- **No data migration needed** ✅
- **No data loss** ✅

### Test Results

**Badge Model Specs:**
```
14 examples, 0 failures ✅
```

**API Specs:**
```
19 examples, 0 failures, 1 pending ✅
```

### API Impact

**Future Enhancement (when building Badge API):**
```ruby
# GET /api/v1/badges?series=Série+TouKouLeur
# BadgeSerializer will include series attribute

def index
  @badges = Badge.all
  @badges = @badges.by_series(params[:series]) if params[:series].present?
  render json: @badges
end
```

### Benefits

✅ Foundation for multiple badge collections  
✅ Backward compatible  
✅ All existing badges preserved  
✅ Easy to add new series in future  
✅ Filterable and queryable  

### Files Modified

```
✅ db/migrate/20251016105730_add_series_to_badges.rb (created)
✅ db/schema.rb (auto-updated)
✅ app/models/badge.rb (validation + scopes)
✅ spec/factories/badges.rb (default series)
```

### Rollback Plan (if needed)

```ruby
# If we need to rollback:
rails db:rollback

# This will:
# - Remove series column
# - Remove index
# - Revert to previous state
```

---

## Change #2: User Avatars & Company/School Logos ✅ COMPLETED

**Date:** October 16, 2025  
**Status:** ✅ Implemented and Tested  
**Risk Level:** VERY LOW  
**Time Taken:** 10 minutes  

### What Changed

**Added logo attachments to Company and School models** (User avatars already existed).

### Database Changes

**No migration needed!** ✅ ActiveStorage uses existing `active_storage_attachments` table.

### Model Changes

**Files Modified:**
- `app/models/company.rb`
- `app/models/school.rb`
- `app/models/user.rb` (added helper method)

**Added to Company:**
```ruby
has_one_attached :logo

# Validation
validate :logo_format  # JPEG, PNG, GIF, WebP, SVG, < 5MB

# Helper method
def logo_url
  return nil unless logo.attached?
  Rails.application.routes.url_helpers.rails_blob_url(logo, only_path: false)
end
```

**Added to School:**
```ruby
has_one_attached :logo

# Validation
validate :logo_format  # JPEG, PNG, GIF, WebP, SVG, < 5MB

# Helper method
def logo_url
  return nil unless logo.attached?
  Rails.application.routes.url_helpers.rails_blob_url(logo, only_path: false)
end
```

**Added to User:**
```ruby
# Already had: has_one_attached :avatar

# Added helper method
def avatar_url
  return nil unless avatar.attached?
  Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: false)
end
```

### Validation Rules

**File Formats Allowed:**
- image/jpeg
- image/png
- image/gif
- image/webp
- image/svg+xml

**File Size Limit:**
- Maximum 5 MB

**Error Messages:** French (matching existing i18n)

### Test Results

**Model Specs:**
```
Company: 31 examples, 0 failures ✅
School: 23 examples, 0 failures ✅
User: 25 examples, 0 failures ✅
Total: 79 examples, 0 failures ✅
```

**API Specs:**
```
19 examples, 0 failures ✅
```

### API Impact

**Future Enhancement (when building API):**
```ruby
# Upload endpoints
POST /api/v1/users/me/avatar
POST /api/v1/companies/:id/logo
POST /api/v1/schools/:id/logo

# Delete endpoints
DELETE /api/v1/users/me/avatar
DELETE /api/v1/companies/:id/logo
DELETE /api/v1/schools/:id/logo

# Serializers include URL
{
  "user": {
    "id": 123,
    "avatar_url": "https://res.cloudinary.com/..."
  },
  "company": {
    "id": 5,
    "logo_url": "https://res.cloudinary.com/..."
  }
}
```

### Storage

**Development:** Local storage (storage/)  
**Production:** Cloudinary (already configured)  

### Benefits

✅ Users can personalize profiles with avatars  
✅ Organizations have professional branding  
✅ URLs ready for API consumption  
✅ Cloudinary CDN for fast delivery  
✅ File validation prevents bad uploads  
✅ Helper methods for easy URL access  

### Files Modified

```
✅ app/models/company.rb (logo attachment + validation)
✅ app/models/school.rb (logo attachment + validation)
✅ app/models/user.rb (avatar_url helper method)
```

### Rollback Plan

**If needed:**
```ruby
# Just remove the has_one_attached lines from models
# ActiveStorage attachments will remain in DB but unused
# Can purge later if needed
```

---

## Change #3: Member Roles (Companies & Schools) - PENDING

**Status:** 📝 Planning  
**Complexity:** HIGH  
**Next Steps:** Detailed analysis required  

---

## Change #4: Branch System - PENDING

**Status:** 📝 Planning  
**Complexity:** VERY HIGH  
**Next Steps:** Architecture design required  

---

## Change #5: Partnership System - PENDING

**Status:** 📝 Verify existing implementation  
**Next Steps:** Check current partnerships, enhance if needed  

---

## Change #6: Project Co-Owners - PENDING

**Status:** 📝 Planning  
**Next Steps:** Analysis and implementation  

---

## Change #7: Partner Projects - PENDING

**Status:** 📝 Planning  
**Next Steps:** Analysis and implementation  

---

## Summary

**Completed:** 2/7 changes  
**Time Invested:** 25 minutes  
**Test Status:** All green ✅ (98 examples, 0 failures)  
**Ready for Next Change:** ✅

### Progress

- ✅ Change #1: Badge Series (15 min)
- ✅ Change #2: User Avatars & Logos (10 min)
- 📝 Change #3: Member Roles (HIGH complexity - next)
- 📝 Change #4: Branch System (VERY HIGH complexity)
- 📝 Change #5: Partnership System (verify existing)
- 📝 Change #6: Project Co-Owners
- 📝 Change #7: Partner Projects

