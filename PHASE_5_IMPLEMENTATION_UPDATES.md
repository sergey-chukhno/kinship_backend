# Phase 5: School Dashboard API - Implementation Updates

**Date:** October 24, 2025  
**Status:** ✅ Ready for Implementation

---

## 🎯 Critical Business Rules Confirmed

### **1. Dashboard Access (CORRECTED)**

**❌ INCORRECT (Initial Assumption):**
- All school members can access the dashboard

**✅ CORRECT (Confirmed by User):**
- **ONLY Admin and Superadmin can access School Dashboard**
- Referents and Intervenants use **Teacher Dashboard** for their operations
- This separation is **key to the app architecture**

**Impact on Implementation:**
- `ensure_school_member` method updated to check `role: [:admin, :superadmin]`
- Clear error message: "School Dashboard access requires Admin or Superadmin role"
- Frontend context logic updated to only show school context for admin/superadmin

---

### **2. Superadmin Management Rules (CONFIRMED)**

**Rule 1: Only ONE Superadmin per School**
- ✅ Validated in `UserSchool` model
- ✅ Enforced in create and update actions
- ✅ Clear error message when attempting to create second superadmin

**Rule 2: Superadmin CANNOT Be Deleted**
- ✅ Block deletion completely (no transfer logic)
- ✅ Must transfer superadmin role first before removal

**Rule 3: Only Superadmins can Manage Superadmin Role**
- ✅ Enforced in create, update, and delete actions
- ✅ Admins can create/manage other admins
- ✅ Admins CANNOT create/modify superadmins

---

### **3. Member Invitation System (CONFIRMED)**

**Three Invitation Scenarios:**

#### **Scenario A: Existing User (Known on Kinship)**
```
Input: email (matches existing user)
Action: Add to school with pending status
Notification: Email notification of membership
```

#### **Scenario B: New User with Known Email**
```
Input: email (not on Kinship)
Action: Create user stub + Add to school with pending status
Notification: Registration invitation email with link to join Kinship
```

#### **Scenario C: New User Without Email**
```
Input: first_name, last_name, birthday (no email)
Action: Create user with temp email + claim token + Add to school
Notification: Generate claim link + QR code
Distribution: Admin prints/shares claim link manually
```

**Same Pattern as Teacher Dashboard Student Creation!** ✅

---

## 🔧 Key Implementation Changes

### **1. Base Controller - Admin-Only Access**

**Before:**
```ruby
def ensure_school_member
  user_school = current_user.user_schools.find_by(school: @school, status: :confirmed)
  # Any member can access
end
```

**After:**
```ruby
def ensure_school_member
  # CRITICAL: Only admin/superadmin can access School Dashboard
  user_school = current_user.user_schools.find_by(
    school: @school, 
    status: :confirmed,
    role: [:admin, :superadmin]
  )
  # Clear error: "School Dashboard access requires Admin or Superadmin role"
end
```

---

### **2. Member Creation - Smart Invitation**

**New Logic:**
1. Check if email provided → Find existing user OR create stub
2. Check if name + birthday provided → Create with temp email
3. Validate against duplicate users (name + birthday)
4. Create appropriate invitation type
5. Return invitation method (email vs claim_link)

**Helper Method Added:**
```ruby
def find_or_identify_user
  # Handles all 3 scenarios
  # Returns: { user: User, is_new: boolean }
  # OR: { error: Hash, status: Symbol }
end
```

---

### **3. Superadmin Deletion - Absolute Block**

**Before:**
```ruby
# Cannot remove yourself if you're the only superadmin
if user == current_user && @current_user_school.superadmin?
  # Check for other superadmins
end
```

**After:**
```ruby
# Rule: Superadmin CANNOT be deleted
if user_school.superadmin?
  return render json: {
    error: 'Forbidden',
    message: 'Superadmin cannot be removed from the school. Transfer superadmin role first.'
  }, status: :forbidden
end
```

---

## 📋 Updated Permission Matrix

| Action | Member | Intervenant | Referent | Admin | Superadmin |
|--------|--------|-------------|----------|-------|------------|
| **Access Dashboard** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **View school** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Update profile** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Manage members** | ❌ | ❌ | ❌ | ✅ (not superadmin) | ✅ (all) |
| **Manage levels** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Create projects** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Assign badges** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Manage partnerships** | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Manage branches** | ❌ | ❌ | ❌ | ❌ | ✅ |

**Note:** Referents and Intervenants use **Teacher Dashboard** for projects/badges.

---

## 🚀 Ready to Implement

All business rules clarified and documented. Implementation plan updated with:

✅ **Admin-only dashboard access**  
✅ **Correct superadmin management**  
✅ **Smart member invitation system**  
✅ **Same pattern as Teacher Dashboard**  

**Next Step:** Begin implementation following the updated plan in `PHASE_5_SCHOOL_DASHBOARD_IMPLEMENTATION_PLAN.md`

