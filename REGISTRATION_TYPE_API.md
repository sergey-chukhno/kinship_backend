# Registration Type API Design
## How Registration Type is Determined

---

## Table of Contents
1. [Overview](#overview)
2. [Chosen Approach: Explicit Parameter](#chosen-approach-explicit-parameter)
3. [Why This Approach?](#why-this-approach)
4. [Frontend Implementation](#frontend-implementation)
5. [Backend Validation Flow](#backend-validation-flow)
6. [Request Examples](#request-examples)
7. [Alternative Approaches Considered](#alternative-approaches-considered)

---

## Overview

The Kinship API supports **4 different registration types** through a single unified endpoint:
1. **Personal User** - Individual users (parents, volunteers, tutors, etc.)
2. **Teacher** - Educational professionals with academic emails
3. **School** - School administrators creating their school organization
4. **Company** - Company administrators creating their company organization

**Question:** How does the API know which type of registration is being performed?

**Answer:** The frontend **explicitly specifies** the registration type using the `registration_type` parameter.

---

## Chosen Approach: Explicit Parameter

### Single Endpoint

```
POST /api/v1/auth/register
```

### Registration Type Parameter

The `registration_type` field is **mandatory** and must be one of:
- `"personal_user"`
- `"teacher"`
- `"school"`
- `"company"`

### Request Structure

```json
{
  "registration_type": "personal_user",  // ← Frontend explicitly specifies this
  "user": {
    "email": "user@example.com",
    "password": "Password123!",
    "first_name": "John",
    "last_name": "Doe",
    "birthday": "1990-05-15",
    "role": "parent"
  }
  // ... other fields based on registration type
}
```

---

## Why This Approach?

### ✅ Advantages

**1. Clear and Explicit**
- No ambiguity about user's intent
- Backend knows exactly what to expect
- Easy to understand and debug

**2. Frontend Controls Flow**
- Different UI forms for different registration types
- Frontend can validate appropriately before sending
- Better user experience

**3. Better Validation**
- Backend validates email matches type (academic vs. non-academic)
- Backend validates role matches type
- Backend validates required fields for that specific type
- Clear error messages

**4. Easier to Debug**
- Logs show registration type clearly
- Easy to track which registration types are most popular
- Error messages reference the specific registration type

**5. Separate UI Flows**
- Each registration type has its own form/page
- Tailored experience for each user type
- Can show/hide fields based on type

**6. Scalability**
- Easy to add new registration types in the future
- Clean separation of concerns
- Minimal code changes needed

---

## Frontend Implementation

### User Journey

#### **Landing Page: Registration Type Selection**

```
+--------------------------------------------------+
|            Welcome to Kinship                     |
|                                                   |
|     How would you like to register?              |
|                                                   |
|  +------------------+    +------------------+    |
|  | Personal User    |    | Teacher          |    |
|  |                  |    |                  |    |
|  | For individuals  |    | For educators    |    |
|  +------------------+    +------------------+    |
|                                                   |
|  +------------------+    +------------------+    |
|  | School Admin     |    | Company Admin    |    |
|  |                  |    |                  |    |
|  | Create school    |    | Create company   |    |
|  +------------------+    +------------------+    |
+--------------------------------------------------+
```

### Separate Registration Forms

Each button leads to a **dedicated registration form** tailored for that user type:

#### **1. Personal User Registration Form**
```javascript
// Frontend code example
function submitPersonalUserRegistration(formData) {
  return axios.post('/api/v1/auth/register', {
    registration_type: "personal_user",  // ← Explicitly set
    user: {
      email: formData.email,              // Non-academic
      password: formData.password,
      password_confirmation: formData.passwordConfirmation,
      first_name: formData.firstName,
      last_name: formData.lastName,
      birthday: formData.birthday,
      role: formData.role,                // parent, grand-parent, voluntary, etc.
      job: formData.job,
      take_trainee: formData.takeTrainee,
      propose_workshop: formData.proposeWorkshop,
      show_my_skills: formData.showMySkills
    },
    availability: formData.availability,
    skills: {
      skill_ids: formData.selectedSkills,
      sub_skill_ids: formData.selectedSubSkills
    },
    join_school_ids: formData.selectedSchools,
    join_company_ids: formData.selectedCompanies
  });
}
```

**Form Fields:**
- Email (with validation: NOT academic)
- Password (8+ chars, 1 uppercase, 1 special)
- First Name, Last Name
- Birthday (age >= 13)
- **Role dropdown:** parent, grand-parent, children, voluntary, tutor, employee, other
- Job (optional)
- Take Trainee? (checkbox)
- Propose Workshop? (checkbox)
- Show My Skills? (checkbox)
- **Availability** (day selection)
- **Skills** (multi-select from API)
- **Join Schools** (multi-select from API)
- **Join Companies** (multi-select from API)

---

#### **2. Teacher Registration Form**
```javascript
function submitTeacherRegistration(formData) {
  return axios.post('/api/v1/auth/register', {
    registration_type: "teacher",        // ← Explicitly set
    user: {
      email: formData.email,              // MUST be academic
      password: formData.password,
      password_confirmation: formData.passwordConfirmation,
      first_name: formData.firstName,
      last_name: formData.lastName,
      birthday: formData.birthday,
      role: formData.role,                // school_teacher, college_lycee_professor, etc.
      show_my_skills: formData.showMySkills
    },
    availability: formData.availability,
    join_school_ids: formData.selectedSchools
  });
}
```

**Form Fields:**
- Email (with validation: MUST be academic - @ac-*.fr, etc.)
- Password (8+ chars, 1 uppercase, 1 special)
- First Name, Last Name
- Birthday (age >= 13)
- **Role dropdown:** school teacher, college-lycee professor, teaching staff, other
- Show My Skills? (checkbox)
- **Availability** (day selection)
- **Join Schools** (multi-select from API)

**Frontend Academic Email Validation:**
```javascript
function isAcademicEmail(email) {
  const academicDomains = [
    /@ac-aix-marseille\.fr$/,
    /@ac-amiens\.fr$/,
    /@ac-bordeaux\.fr$/,
    /@ac-paris\.fr$/,
    // ... all academic domains
    /@education\.mc$/,
    /@lfmadrid\.org$/
  ];
  
  return academicDomains.some(pattern => pattern.test(email));
}

// Show error if teacher tries non-academic email
if (registrationType === 'teacher' && !isAcademicEmail(email)) {
  showError('Teachers must use academic email addresses');
}
```

---

#### **3. School Registration Form**
```javascript
function submitSchoolRegistration(formData) {
  return axios.post('/api/v1/auth/register', {
    registration_type: "school",         // ← Explicitly set
    user: {
      email: formData.email,              // MUST be academic
      password: formData.password,
      password_confirmation: formData.passwordConfirmation,
      first_name: formData.firstName,
      last_name: formData.lastName,
      birthday: formData.birthday,
      role: formData.role                 // school_director, principal, etc.
    },
    school: {
      name: formData.schoolName,
      address: formData.schoolAddress,
      city: formData.schoolCity,
      zip_code: formData.schoolZipCode
    }
  });
}
```

**Form Fields:**
- **Personal Information:**
  - Email (with validation: MUST be academic)
  - Password (8+ chars, 1 uppercase, 1 special)
  - First Name, Last Name
  - Birthday (age >= 13)
  - **Role dropdown:** school director, principal, education director, other

- **School Information:**
  - School Name (required)
  - School Address (optional)
  - City (optional)
  - Zip Code (optional)

---

#### **4. Company Registration Form**
```javascript
function submitCompanyRegistration(formData) {
  return axios.post('/api/v1/auth/register', {
    registration_type: "company",        // ← Explicitly set
    user: {
      email: formData.email,              // Any email (NOT academic)
      password: formData.password,
      password_confirmation: formData.passwordConfirmation,
      first_name: formData.firstName,
      last_name: formData.lastName,
      birthday: formData.birthday,
      role: formData.role                 // company_director, association_president, etc.
    },
    company: {
      name: formData.companyName,
      description: formData.companyDescription,
      company_type_id: formData.companyTypeId,
      zip_code: formData.companyZipCode,
      city: formData.companyCity,
      siret_number: formData.siretNumber,
      email: formData.companyEmail,
      branch_request_to_company_id: formData.parentCompanyId  // Optional
    }
  });
}
```

**Form Fields:**
- **Personal Information:**
  - Email (with validation: NOT academic)
  - Password (8+ chars, 1 uppercase, 1 special)
  - First Name, Last Name
  - Birthday (age >= 13)
  - **Role dropdown:** association president, company director, organization head, other

- **Company Information:**
  - Company Name (required)
  - Description (required)
  - Company Type (required): association, enterprise, institution, metropole, cité éducative
  - Zip Code (required)
  - City (required)
  - SIRET Number (optional)
  - Company Email (optional)
  - **Join as Branch Company** (optional select from main companies)

---

## Backend Validation Flow

### Step-by-Step Validation

```ruby
# 1. Request arrives
POST /api/v1/auth/register
{
  "registration_type": "teacher",
  "user": {
    "email": "user@gmail.com",  // ← Oops, not academic!
    "role": "school_teacher"
  }
}

# 2. RegistrationService validates
def call
  validate_registration_type!   # ✅ "teacher" is valid
  validate_email_for_type!       # ❌ Email not academic for teacher
  validate_role_for_type!        # ✅ Role matches teacher type
  
  return error_result if @errors.any?
  # ...
end

# 3. Response
{
  "error": "Validation failed",
  "errors": [
    "Les enseignants et administrateurs scolaires doivent utiliser un email académique"
  ]
}
```

### Validation Rules by Type

| Registration Type | Email Requirement | Role Requirement | Additional Data |
|-------------------|-------------------|------------------|-----------------|
| `personal_user` | ❌ NOT academic | Must be from PERSONAL_USER_ROLES | Optional: skills, join schools/companies |
| `teacher` | ✅ MUST be academic | Must be from TEACHER_ROLES | Optional: join schools |
| `school` | ✅ MUST be academic | Must be from SCHOOL_ADMIN_ROLES | Required: school info |
| `company` | ✅ NOT academic | Must be from COMPANY_ADMIN_ROLES | Required: company info |

### Backend Implementation

```ruby
# app/services/registration_service.rb

class RegistrationService < ApplicationService
  def initialize(params)
    @registration_type = params[:registration_type]  # ← Explicit from frontend
    @user_params = params[:user] || {}
    # ...
  end
  
  def call
    validate_registration_type!
    validate_email_for_type!
    validate_role_for_type!
    
    return error_result if @errors.any?
    
    # Create appropriate records based on type
    case @registration_type
    when 'personal_user'
      handle_personal_user_registration!
    when 'teacher'
      handle_teacher_registration!
    when 'school'
      handle_school_registration!
    when 'company'
      handle_company_registration!
    end
    
    success_result
  end
  
  private
  
  def validate_registration_type!
    valid_types = %w[personal_user teacher school company]
    unless valid_types.include?(@registration_type)
      @errors << "Type d'inscription invalide. Valeurs acceptées: #{valid_types.join(', ')}"
    end
  end
  
  def validate_email_for_type!
    email = @user_params[:email]
    return if email.blank?
    
    is_academic = is_academic_email?(email)
    
    case @registration_type
    when 'personal_user'
      if is_academic
        @errors << "Les utilisateurs personnels ne peuvent pas utiliser d'email académique. Veuillez utiliser votre email personnel."
      end
    when 'teacher', 'school'
      unless is_academic
        @errors << "Les enseignants et administrateurs scolaires doivent utiliser un email académique"
      end
    when 'company'
      if is_academic
        @errors << "Les administrateurs d'entreprise ne peuvent pas utiliser d'email académique"
      end
    end
  end
  
  def validate_role_for_type!
    role = @user_params[:role]
    return if role.blank?
    
    valid_roles = case @registration_type
    when 'personal_user'
      User::PERSONAL_USER_ROLES.map(&:to_s)
    when 'teacher'
      User::TEACHER_ROLES.map(&:to_s)
    when 'school'
      User::SCHOOL_ADMIN_ROLES.map(&:to_s)
    when 'company'
      User::COMPANY_ADMIN_ROLES.map(&:to_s)
    else
      []
    end
    
    unless valid_roles.include?(role)
      @errors << "Rôle '#{role}' invalide pour le type d'inscription '#{@registration_type}'. Rôles valides: #{valid_roles.join(', ')}"
    end
  end
end
```

---

## Request Examples

### Example 1: Personal User Registration

**Request:**
```json
POST /api/v1/auth/register

{
  "registration_type": "personal_user",
  "user": {
    "email": "john.doe@example.com",
    "password": "Password123!",
    "password_confirmation": "Password123!",
    "first_name": "John",
    "last_name": "Doe",
    "birthday": "1990-05-15",
    "role": "parent",
    "job": "Software Engineer",
    "take_trainee": true,
    "propose_workshop": true,
    "show_my_skills": true
  },
  "availability": {
    "monday": true,
    "tuesday": false,
    "wednesday": true,
    "thursday": false,
    "friday": true,
    "other": false
  },
  "skills": {
    "skill_ids": [1, 2, 5],
    "sub_skill_ids": [10, 11, 15]
  },
  "join_school_ids": [3, 7],
  "join_company_ids": [2],
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

**Success Response (200 OK):**
```json
{
  "message": "Registration successful! Please check your email to confirm your account.",
  "email": "john.doe@example.com",
  "requires_confirmation": true
}
```

**What Gets Created:**
- ✅ User account (role: parent)
- ✅ Availability record
- ✅ 3 UserSkill records
- ✅ 3 UserSubSkill records
- ✅ 2 UserSchool records (status: pending)
- ✅ 1 UserCompany record (status: pending)
- ✅ 1 ParentChildInfo record (for Anna Dupont)
- ✅ Confirmation email sent

**Note:** No User account is created for Anna at this stage. The ParentChildInfo record allows the parent to view/manage this information after login. When Anna's account is later created (by teacher, school, or self-registration), the system will match and propose linkage.

---

### Example 2: Teacher Registration

**Request:**
```json
POST /api/v1/auth/register

{
  "registration_type": "teacher",
  "user": {
    "email": "marie.dupont@ac-paris.fr",
    "password": "SecurePass123!",
    "password_confirmation": "SecurePass123!",
    "first_name": "Marie",
    "last_name": "Dupont",
    "birthday": "1985-08-20",
    "role": "school_teacher",
    "show_my_skills": true
  },
  "availability": {
    "monday": true,
    "tuesday": true,
    "wednesday": false,
    "thursday": true,
    "friday": true,
    "other": false
  },
  "join_school_ids": [1]
}
```

**Success Response (200 OK):**
```json
{
  "message": "Registration successful! Please check your email to confirm your account.",
  "email": "marie.dupont@ac-paris.fr",
  "requires_confirmation": true
}
```

**What Gets Created:**
- ✅ User account (role: school_teacher)
- ✅ Availability record
- ✅ IndependentTeacher record (auto-created by callback)
- ✅ 1 UserSchool record (status: pending)
- ✅ Confirmation email sent
- ✅ Notification to school admins

---

### Example 3: School Registration

**Request:**
```json
POST /api/v1/auth/register

{
  "registration_type": "school",
  "user": {
    "email": "jean.martin@ac-lyon.fr",
    "password": "AdminPass123!",
    "password_confirmation": "AdminPass123!",
    "first_name": "Jean",
    "last_name": "Martin",
    "birthday": "1975-03-10",
    "role": "school_director"
  },
  "school": {
    "name": "Lycée Victor Hugo",
    "address": "123 Rue de la République",
    "city": "Lyon",
    "zip_code": "69000"
  }
}
```

**Success Response (200 OK):**
```json
{
  "message": "Registration successful! Please check your email to confirm your account.",
  "email": "jean.martin@ac-lyon.fr",
  "requires_confirmation": true
}
```

**What Gets Created:**
- ✅ User account (role: school_director)
- ✅ Availability record
- ✅ School record (status: pending)
- ✅ UserSchool record (user as superadmin, status: pending)
- ✅ Confirmation email sent

**After Email Confirmation:**
- ✅ User status: confirmed
- ✅ UserSchool status: confirmed
- ✅ School status: confirmed

---

### Example 4: Company Registration

**Request:**
```json
POST /api/v1/auth/register

{
  "registration_type": "company",
  "user": {
    "email": "sophie.bernard@techcorp.fr",
    "password": "CompanyPass123!",
    "password_confirmation": "CompanyPass123!",
    "first_name": "Sophie",
    "last_name": "Bernard",
    "birthday": "1980-11-25",
    "role": "company_director"
  },
  "company": {
    "name": "Tech Education Corp",
    "description": "Technology education and training services",
    "company_type_id": 2,
    "city": "Paris",
    "zip_code": "75001",
    "siret_number": "12345678900012",
    "email": "contact@techcorp.fr"
  }
}
```

**Success Response (200 OK):**
```json
{
  "message": "Registration successful! Please check your email to confirm your account.",
  "email": "sophie.bernard@techcorp.fr",
  "requires_confirmation": true
}
```

**What Gets Created:**
- ✅ User account (role: company_director)
- ✅ Availability record
- ✅ Company record (status: confirmed immediately)
- ✅ UserCompany record (user as superadmin, status: pending)
- ✅ Confirmation email sent

---

### Example 5: Company Registration as Branch

**Request:**
```json
POST /api/v1/auth/register

{
  "registration_type": "company",
  "user": {
    "email": "branch.manager@techcorp-marseille.fr",
    "password": "BranchPass123!",
    "password_confirmation": "BranchPass123!",
    "first_name": "Pierre",
    "last_name": "Dubois",
    "birthday": "1982-06-15",
    "role": "company_director"
  },
  "company": {
    "name": "Tech Education Corp - Marseille",
    "description": "Branch office in Marseille",
    "company_type_id": 2,
    "city": "Marseille",
    "zip_code": "13001",
    "branch_request_to_company_id": 5  // ← Request to join company ID 5 as branch
  }
}
```

**What Gets Created:**
- ✅ User account (role: company_director)
- ✅ Availability record
- ✅ Company record (status: confirmed)
- ✅ UserCompany record (user as superadmin, status: pending)
- ✅ **BranchRequest** record (status: pending)
- ✅ Confirmation email sent
- ✅ **Branch request notification** sent to parent company admins

---

### Example 6: Error - Wrong Email for Type

**Request:**
```json
POST /api/v1/auth/register

{
  "registration_type": "teacher",
  "user": {
    "email": "teacher@gmail.com",  // ← NOT academic!
    "password": "Password123!",
    "password_confirmation": "Password123!",
    "first_name": "Wrong",
    "last_name": "Email",
    "birthday": "1985-01-01",
    "role": "school_teacher"
  }
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "error": "Validation failed",
  "errors": [
    "Les enseignants et administrateurs scolaires doivent utiliser un email académique"
  ]
}
```

---

### Example 7: Error - Wrong Role for Type

**Request:**
```json
POST /api/v1/auth/register

{
  "registration_type": "personal_user",
  "user": {
    "email": "user@example.com",
    "password": "Password123!",
    "password_confirmation": "Password123!",
    "first_name": "Wrong",
    "last_name": "Role",
    "birthday": "1990-01-01",
    "role": "school_teacher"  // ← Teacher role for personal user!
  }
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "error": "Validation failed",
  "errors": [
    "Rôle 'school_teacher' invalide pour le type d'inscription 'personal_user'. Rôles valides: parent, grand_parent, children, voluntary, tutor, employee, other"
  ]
}
```

---

## Alternative Approaches Considered

### ❌ Option 2: Infer from Data (NOT CHOSEN)

Try to guess registration type based on what data is present:

```ruby
def infer_registration_type
  if params[:school].present?
    'school'
  elsif params[:company].present?
    'company'
  elsif is_academic_email?(params[:user][:email])
    'teacher'
  else
    'personal_user'
  end
end
```

**Why NOT this approach?**
- ❌ **Ambiguous** - What if personal user accidentally provides academic email?
- ❌ **Error-prone** - Easy to misclassify intent
- ❌ **Poor UX** - User doesn't explicitly choose
- ❌ **Harder to debug** - "Why was I classified as teacher instead of personal user?"
- ❌ **No clear validation** - Backend guesses instead of validates

---

### 🤔 Option 3: Separate Endpoints (ALTERNATIVE)

Create 4 separate endpoints instead of one:

```
POST /api/v1/auth/register/personal_user
POST /api/v1/auth/register/teacher
POST /api/v1/auth/register/school
POST /api/v1/auth/register/company
```

**Pros:**
- ✅ Clear separation per type
- ✅ Can have different parameter schemas
- ✅ RESTful approach

**Cons:**
- ❌ More code duplication
- ❌ More routes to maintain
- ❌ Harder to share common logic
- ❌ More complex routing on frontend
- ❌ Less flexible (what if user switches type mid-flow?)

**Why we didn't choose this:**
- The 4 registration types share **80% common logic** (user creation, validation, email confirmation)
- A service layer (`RegistrationService`) can handle the 20% differences cleanly
- Single endpoint is simpler for frontend (one API call to remember)
- Easier to add more types in the future

---

## Children Info at Registration

### Overview

For **personal user registration** only, parents can optionally provide information about their children using the `children_info` array. This information is persisted as `ParentChildInfo` records, allowing parents to manage their children's information after login through the "My Children" dashboard page.

### Key Points

- ✅ **Optional field** - Not required for registration
- ✅ **Persisted immediately** - Each child info record is saved as `ParentChildInfo` associated with the parent
- ✅ **No User account created** - Children do NOT get user accounts at registration time
- ✅ **Manageable after login** - Parents can view, add, edit, delete children info via `/api/v1/parent_children` endpoints
- ✅ **Future linkage** - When a child account is later created (by teacher, school, or self-registration), the system matches by name + birthday + school/class and proposes linkage

### Request Structure

```json
{
  "registration_type": "personal_user",
  "user": { ... },
  "children_info": [
    {
      "first_name": "Anna",
      "last_name": "Dupont",
      "birthday": "2010-08-15",
      "school_id": 5,              // If chosen from existing schools
      "school_name": "Ecole Demo", // If free-text (school not in list)
      "class_id": 13,              // If chosen from existing classes
      "class_name": "CP B"         // If free-text (class not in list)
    }
  ]
}
```

### ParentChildInfo Model Fields

- `parent_user_id` (FK to User - set automatically)
- `first_name` (string, optional)
- `last_name` (string, optional)
- `birthday` (date, optional)
- `school_id` (integer, optional - if school selected from list)
- `school_name` (string, optional - if school entered as free-text)
- `class_id` (integer, optional - if class selected from list)
- `class_name` (string, optional - if class entered as free-text)
- `linked_user_id` (nullable FK to User - set when child account is created and linked)
- `created_at`, `updated_at` (timestamps)

### Post-Registration Management

After the parent confirms their email and logs in, they can:

**View all children info:**
```
GET /api/v1/parent_children
```

**Add new child info:**
```
POST /api/v1/parent_children
{
  "first_name": "Marie",
  "last_name": "Dupont",
  "birthday": "2012-03-20",
  "school_id": 7
}
```

**Update child info:**
```
PATCH /api/v1/parent_children/:id
{
  "class_id": 15
}
```

**Delete child info:**
```
DELETE /api/v1/parent_children/:id
```

### Matching & Linking Process

When a child account is created through other flows (teacher/school creates student, or child self-registers):

1. **Backend searches** for matching `ParentChildInfo` records where:
   - `first_name` matches (case-insensitive)
   - `last_name` matches (case-insensitive)
   - `birthday` matches exactly
   - `school_id` matches (if both have school_id) OR `school_name` matches (if both have school_name)
   - `linked_user_id` is NULL (not already linked)

2. **If match found:**
   - System notifies parent that a potential match exists
   - Parent can confirm/claim the linkage
   - Upon confirmation, `linked_user_id` is set and `User.parent_id` is set

3. **Result:**
   - Parent-child relationship is established
   - Child's account is linked to parent's children info
   - Parent can see child in their "My Children" dashboard

---

## Summary


### ✅ Chosen Approach: Explicit `registration_type` Parameter

**How it works:**
1. Frontend has 4 separate registration forms/pages
2. Each form explicitly sets `registration_type` in the request
3. Backend validates the type and performs type-specific validation
4. Backend creates appropriate records based on the type

**Why it's best:**
- Clear, explicit, no ambiguity
- Easy to validate and debug
- Great user experience (tailored forms)
- Clean code separation
- Scalable for future types

**Implementation:**
- Single endpoint: `POST /api/v1/auth/register`
- Mandatory parameter: `registration_type`
- Type-specific validation in `RegistrationService`
- Type-specific record creation

---

## References

- **Implementation Plan:** `REGISTRATION_API_IMPLEMENTATION_PLAN.md`
- **Summary:** `REGISTRATION_IMPLEMENTATION_SUMMARY.md`
- **Main Strategy:** `REACT_INTEGRATION_STRATEGY.md`

---

**Document Version:** 1.0  
**Last Updated:** 2025-10-29  
**Status:** Approved ✅

