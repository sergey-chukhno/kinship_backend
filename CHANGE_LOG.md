# Kinship Backend - Change Log
## Pre-React Integration Model Changes

This document tracks all model/schema changes made before React integration.

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

