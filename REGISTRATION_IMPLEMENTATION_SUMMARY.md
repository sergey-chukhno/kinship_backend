# Registration API Implementation Summary
## Quick Reference Guide

---

## What We're Building

A **unified registration API endpoint** that supports 4 different user types:
1. **Personal User** - Individual users (parents, volunteers, tutors, etc.)
2. **Teacher** - Educational professionals with academic emails
3. **School** - School administrators creating their school
4. **Company** - Company administrators creating their organization

---

## Key Changes

### 1. Role System Overhaul

**Before:**
```ruby
enum :role, {teacher: 0, tutor: 1, voluntary: 2, children: 3}
```

**After:**
```ruby
enum :role, {
  # 16 new informative roles grouped by registration type
  parent: 0, grand_parent: 1, children: 2, voluntary: 3, tutor: 4, employee: 5,      # Personal
  school_teacher: 6, college_lycee_professor: 7, teaching_staff: 8,                   # Teacher
  school_director: 9, principal: 10, education_director: 11,                          # School
  association_president: 12, company_director: 13, organization_head: 14,            # Company
  other: 15
}
```

### 2. Email Validation Rules

| User Type | Email Requirement |
|-----------|------------------|
| Personal User | ❌ **CANNOT** use academic email |
| Teacher | ✅ **MUST** use academic email |
| School Admin | ✅ **MUST** use academic email |
| Company Admin | ✅ Can use any email (not academic) |

### 3. Password Complexity
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 special character

### 4. Age Validation
- Minimum age: 13 years old

---

## API Endpoint

```
POST /api/v1/auth/register
```

### Request Structure

```json
{
  "registration_type": "personal_user" | "teacher" | "school" | "company",
  "user": {
    "email": "string",
    "password": "string",
    "password_confirmation": "string",
    "first_name": "string",
    "last_name": "string",
    "birthday": "YYYY-MM-DD",
    "role": "string (from appropriate list)",
    ...
  },
  "availability": { ... },
  "skills": { "skill_ids": [...], "sub_skill_ids": [...] },
  "join_school_ids": [...],
  "join_company_ids": [...],
  "children_info": [  // Optional, for personal_user registration
    {
      "first_name": "string (optional)",
      "last_name": "string (optional)",
      "birthday": "YYYY-MM-DD (optional)",
      "school_id": "integer (optional)",
      "school_name": "string (optional)",
      "class_id": "integer (optional)",
      "class_name": "string (optional)"
    }
  ],
  "school": { ... },  // If registration_type = "school"
  "company": { ... }  // If registration_type = "company"
}
```

### Response

**Success (200 OK):**
```json
{
  "message": "Registration successful! Please check your email to confirm your account.",
  "email": "user@example.com",
  "requires_confirmation": true
}
```

**Error (422 Unprocessable Entity):**
```json
{
  "error": "Validation failed",
  "errors": [
    "Email doit être votre mail académique",
    "Password doit contenir au moins 8 caractères"
  ]
}
```

---

## Supporting Endpoints

### Skills List (for registration form)
```
GET /api/v1/skills
GET /api/v1/skills/:skill_id/sub_skills
```

### Schools/Companies List (for joining)
```
GET /api/v1/schools/list_for_joining
GET /api/v1/companies/list_for_joining
```

### Parent Children Info (for managing children info after login)
```
GET    /api/v1/parent_children        # List all children info for logged-in parent
POST   /api/v1/parent_children        # Add new child info
PATCH  /api/v1/parent_children/:id    # Update child info
DELETE /api/v1/parent_children/:id     # Remove child info
```

---

## Registration Flow

```
1. User fills registration form → POST /api/v1/auth/register
2. System creates user + related records (transaction)
3. System sends confirmation email
4. User clicks confirmation link → Account activated
5. User logs in → POST /api/v1/auth/login
6. System returns JWT token + available_contexts
7. User accesses appropriate dashboard(s)
```

---

## What Gets Created

### Personal User Registration
- ✅ User account
- ✅ Availability record
- ✅ UserSkill records (if skills selected)
- ✅ UserSchool records (if joining schools, pending)
- ✅ UserCompany records (if joining companies, pending)
- ✅ ParentChildInfo records (if children_info provided, one per child)

### Teacher Registration
- ✅ User account (academic email)
- ✅ Availability record
- ✅ IndependentTeacher record (auto-created)
- ✅ UserSchool records (if joining schools, pending)

### School Registration
- ✅ User account (academic email)
- ✅ School record (pending)
- ✅ UserSchool record (user as superadmin, pending)
- ✅ Availability record

### Company Registration
- ✅ User account
- ✅ Company record (confirmed immediately)
- ✅ UserCompany record (user as superadmin, pending)
- ✅ BranchRequest record (if joining as branch, pending)
- ✅ Availability record

### Children Info (ParentChildInfo)

- ✅ At registration, parents may provide a `children_info` array (each record: first_name, last_name, birthday, school_id or school_name, class_id or class_name)
- ✅ Each entry is persisted as a ParentChildInfo record associated with the parent
- ✅ No User is created for the child at registration time
- ✅ After login, parent can view, add, remove, and edit these records in 'My Children' (via `/api/v1/parent_children` endpoints)
- ✅ If a child account is later created by a teacher, school, or self-registration, the backend matches and proposes a linkage based on name, birthday, and school/class info (with parent confirmation)
- ✅ Unlimited children_info may be provided/persisted per parent

**Example registration snippet:**
```json
{
  ...,
  "children_info": [
    {
      "first_name": "Anna",
      "last_name": "Dupont",
      "birthday": "2010-08-15",
      "school_id": 5,
      "school_name": "Ecole Demo",
      "class_id": 13,
      "class_name": "CP B"
    }
  ]
}
```

---

## Available Contexts After Login

### Personal User
```json
{
  "user_dashboard": true,
  "teacher_dashboard": false,
  "schools": [],
  "companies": []
}
```

### Teacher
```json
{
  "user_dashboard": false,
  "teacher_dashboard": true,
  "schools": [...]  // If joined and confirmed
}
```

### School Admin
```json
{
  "user_dashboard": false,
  "teacher_dashboard": false,
  "schools": [{
    "id": 123,
    "name": "Lycée Victor Hugo",
    "role": "superadmin",
    "permissions": { "admin": true, "owner": true, ... }
  }]
}
```

### Company Admin
```json
{
  "user_dashboard": false,
  "teacher_dashboard": false,
  "companies": [{
    "id": 456,
    "name": "Tech Corp",
    "role": "superadmin",
    "permissions": { "admin": true, "owner": true, ... }
  }]
}
```

---

## Files to Create/Modify

### New Files (7)
1. `app/services/registration_service.rb`
2. `app/controllers/api/v1/skills_controller.rb`
3. `app/controllers/api/v1/auth/confirmations_controller.rb`
4. `app/models/parent_child_info.rb` ⭐ NEW
5. `app/controllers/api/v1/parent_children_controller.rb` ⭐ NEW
6. `spec/requests/api/v1/auth/registration_spec.rb`
7. `spec/services/registration_service_spec.rb`

### Modified Files (6)
1. `app/models/user.rb` - role enum, validations
2. `app/controllers/api/v1/auth_controller.rb` - add register method
3. `app/controllers/api/v1/schools_controller.rb` - add list_for_joining
4. `app/controllers/api/v1/companies_controller.rb` - add list_for_joining
5. `app/serializers/user_serializer.rb` - update available_contexts
6. `config/routes.rb` - add registration routes

### Documentation Updates (2)
1. `postman_collection.json` - add registration requests
2. `REACT_INTEGRATION_STRATEGY.md` - mark registration completed

---

## Implementation Timeline

| Phase | Duration | Tasks |
|-------|----------|-------|
| **Phase 1** | Day 1 | User model: role enum, validations, scopes |
| **Phase 2** | Day 2 | Registration service implementation |
| **Phase 3** | Day 3 | Controllers, routes, request specs |
| **Phase 4** | Day 4 | Serializers, email flow, confirmations |
| **Phase 5** | Day 5 | Manual testing, Postman, documentation |

**Total: 5 days (1 sprint week)**

---

## Testing Checklist

### Unit Tests
- [ ] Role enum works correctly
- [ ] Email validation (academic vs. non-academic)
- [ ] Password complexity validation
- [ ] Age validation (13+)
- [ ] Role group methods

### Integration Tests
- [ ] Personal user registration
- [ ] Personal user with skills
- [ ] Personal user joining school
- [ ] Personal user joining company
- [ ] Personal user with children_info (persists ParentChildInfo records)
- [ ] Parent children CRUD endpoints (GET, POST, PATCH, DELETE)
- [ ] Teacher registration
- [ ] Teacher joining school
- [ ] School admin registration
- [ ] Company admin registration
- [ ] Company branch request creation

### Manual Tests (Postman)
- [ ] All 4 registration types
- [ ] Email confirmation flow
- [ ] Login after confirmation
- [ ] Contexts returned correctly
- [ ] Skills/sub-skills endpoints
- [ ] Schools/companies list endpoints

---

## Validation Error Messages

| Validation | Error Message (French) |
|------------|----------------------|
| Email required | "Email doit être rempli(e)" |
| Email already taken | "Email est déjà utilisé" |
| Academic email required | "L'email doit être votre mail académique" |
| Academic email not allowed | "Les utilisateurs personnels ne peuvent pas utiliser d'email académique" |
| Password too short | "Password doit contenir au moins 8 caractères" |
| Password no uppercase | "Password doit contenir au moins une lettre majuscule" |
| Password no special char | "Password doit contenir au moins un caractère spécial" |
| Password mismatch | "Password confirmation ne correspond pas" |
| Age too young | "Vous devez avoir au moins 13 ans pour vous inscrire" |
| Invalid role | "Rôle invalide pour ce type d'inscription" |

---

## Backward Compatibility

### Breaking Changes
⚠️ **Role enum values changed**
- Old code checking `user.teacher?` needs updating
- Scopes like `User.teachers` return different users

### Migration Strategy
1. Search codebase for role checks
2. Update to use new role names OR role group methods
3. Test thoroughly before deploying

### Example Updates
```ruby
# OLD:
if user.teacher?

# NEW (Option 1):
if User.is_teacher_role?(user.role)

# NEW (Option 2):
if user.school_teacher? || user.college_lycee_professor? || user.teaching_staff?
```

---

## Success Criteria

✅ All 4 registration types work  
✅ Email validation enforced  
✅ Password complexity enforced  
✅ Age validation enforced  
✅ Email confirmation flow works  
✅ Contexts calculated correctly  
✅ Skills/sub-skills endpoints work  
✅ Schools/companies list endpoints work  
✅ Branch request creation works  
✅ Member joining notifications work  
✅ Children info persistence works (ParentChildInfo records created at registration)  
✅ Parent children CRUD endpoints work  
✅ All existing tests pass  
✅ New tests written and passing  
✅ Postman collection updated  
✅ Documentation updated  

---

## Questions or Concerns?

**Review the detailed plan:** `REGISTRATION_API_IMPLEMENTATION_PLAN.md`

**Ready to proceed?** → Approve this plan and I'll start implementation! 🚀

