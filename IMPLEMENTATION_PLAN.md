# Registration API Implementation Plan
## Senior Rails Engineer Implementation Guide

**Branch:** `feature/registration-API`  
**Status:** Documentation Complete ✅ | Ready for Implementation ⏳  
**Estimated Time:** 5 days (40 hours)

---

## Table of Contents
1. [Implementation Strategy](#implementation-strategy)
2. [Phase-by-Phase Breakdown](#phase-by-phase-breakdown)
3. [Critical Dependencies](#critical-dependencies)
4. [Risk Mitigation](#risk-mitigation)
5. [Testing Strategy](#testing-strategy)
6. [Code Review Checklist](#code-review-checklist)

---

## Implementation Strategy

### Core Principles
1. **Database First** - Create migrations before models
2. **Models Before Controllers** - Establish data layer before API layer
3. **Service Layer** - Extract business logic into services
4. **Test-Driven** - Write tests as we build (when possible)
5. **Backward Compatible** - Ensure existing code continues working
6. **Incremental Commits** - Commit after each logical unit
7. **Postman Collection Updates** - Update Postman collection IMMEDIATELY after each endpoint is implemented ⭐
8. **Documentation Updates** - Update documentation as we go, not at the end ⭐

### Implementation Order
```
1. Database Migration (parent_child_infos table)
2. User Model Updates (role enum, validations, associations)
3. ParentChildInfo Model
4. RegistrationService (core business logic)
5. AuthController#register endpoint → Update Postman ⭐
6. ParentChildrenController (CRUD) → Update Postman ⭐
7. Supporting Controllers (Skills, Schools, Companies lists) → Update Postman ⭐
8. Routes Configuration
9. Testing & Validation
10. Final Postman Collection Review & Validation ⭐
```

---

## Postman Collection Updates ⭐

### **Critical Requirement: Update Postman Collection IMMEDIATELY After Each Endpoint Implementation**

**Why:** This is part of our established workflow - documentation and testing tools must be updated as we build, not at the end.

### Postman Collection Structure

**File:** `postman_collection.json`

**Collection Organization:**
```
Kinship API Collection
├── Authentication
│   ├── Login
│   ├── Register - Personal User ⭐ NEW
│   ├── Register - Teacher ⭐ NEW
│   ├── Register - School ⭐ NEW
│   ├── Register - Company ⭐ NEW
│   ├── Register - Company (Branch) ⭐ NEW
│   ├── Confirm Email ⭐ NEW
│   ├── Logout
│   ├── Refresh Token
│   └── Get Current User
├── Parent Children ⭐ NEW SECTION
│   ├── List Children Info
│   ├── Add Child Info
│   ├── Update Child Info
│   └── Delete Child Info
├── Skills ⭐ NEW SECTION
│   ├── List All Skills
│   └── List Sub-Skills
├── Schools
│   ├── List Schools for Joining ⭐ NEW
│   └── [existing endpoints...]
├── Companies
│   ├── List Companies for Joining ⭐ NEW
│   └── [existing endpoints...]
└── [other existing sections...]
```

### Postman Request Requirements

**For Each Request, Include:**

1. **Proper URL Structure:**
   ```json
   {
     "raw": "{{base_url}}/api/v1/auth/register",
     "host": ["{{base_url}}"],
     "path": ["api", "v1", "auth", "register"]
   }
   ```

2. **Headers:**
   ```json
   {
     "key": "Authorization",
     "value": "Bearer {{jwt_token}}",
     "type": "text"
   },
   {
     "key": "Content-Type",
     "value": "application/json",
     "type": "text"
   }
   ```

3. **Request Body Examples:**
   - For registration: Include all 4 types with complete examples
   - Include children_info array example for personal_user
   - Include validation error examples

4. **Variables:**
   - Use `{{base_url}}` for base URL
   - Use `{{jwt_token}}` for authenticated requests
   - Use `:id` variables for dynamic IDs (e.g., `:parent_child_id`)

5. **Example Responses:**
   - Success responses (200, 201)
   - Error responses (400, 422, 401, 404)

### Postman Collection Update Checklist

**After Each Endpoint Implementation:**
- [ ] Add request to appropriate folder
- [ ] Set correct HTTP method (GET, POST, PATCH, DELETE)
- [ ] Add all required headers
- [ ] Include complete request body example
- [ ] Add request variables if needed
- [ ] Verify JSON structure is valid (no syntax errors)
- [ ] Test request in Postman (if server is running)
- [ ] Document any special notes or requirements

### Postman Collection Validation

**Before Committing:**
- [ ] Validate JSON structure: `cat postman_collection.json | python3 -m json.tool`
- [ ] Import into Postman to verify no errors
- [ ] Test at least one request from each new section
- [ ] Verify all variable names are consistent

---

## Phase-by-Phase Breakdown

### **PHASE 1: Database & Models (Day 1 - 8 hours)**

#### Step 1.1: Create ParentChildInfo Migration
**File:** `db/migrate/YYYYMMDDHHMMSS_create_parent_child_infos.rb`

**Tasks:**
- [ ] Generate migration: `rails generate migration CreateParentChildInfos`
- [ ] Define table structure:
  - `parent_user_id` (FK to users, NOT NULL)
  - `first_name` (string, nullable)
  - `last_name` (string, nullable)
  - `birthday` (date, nullable)
  - `school_id` (FK to schools, nullable)
  - `school_name` (string, nullable)
  - `school_level_id` (FK to school_levels, nullable, column name: `class_id`)
  - `class_name` (string, nullable)
  - `linked_user_id` (FK to users, nullable)
  - `timestamps`
- [ ] Add indexes:
  - `parent_user_id` (for fast queries)
  - `linked_user_id` (for matching queries)
  - Composite index on `[first_name, last_name, birthday]` for matching
- [ ] Add foreign key constraints
- [ ] Run migration: `rails db:migrate`
- [ ] Verify in `db/schema.rb`

**Critical Notes:**
- Use `school_level_id` column name `class_id` for clarity
- Ensure foreign keys are properly indexed
- Migration should be reversible

**Estimated Time:** 1 hour

---

#### Step 1.2: Update User Model - Role Enum
**File:** `app/models/user.rb`

**Tasks:**
- [ ] **Replace role enum** (line 61):
  ```ruby
  # OLD:
  enum :role, {teacher: 0, tutor: 1, voluntary: 2, children: 3}, default: :voluntary
  
  # NEW:
  enum :role, {
    # Personal User Roles
    parent: 0,
    grand_parent: 1,
    children: 2,
    voluntary: 3,
    tutor: 4,
    employee: 5,
    # Teacher Roles
    school_teacher: 6,
    college_lycee_professor: 7,
    teaching_staff: 8,
    # School Admin Roles
    school_director: 9,
    principal: 10,
    education_director: 11,
    # Company Admin Roles
    association_president: 12,
    company_director: 13,
    organization_head: 14,
    # Other
    other: 15
  }, default: :voluntary
  ```

- [ ] **Add role group constants** (after enum):
  ```ruby
  PERSONAL_USER_ROLES = [:parent, :grand_parent, :children, :voluntary, :tutor, :employee, :other].freeze
  TEACHER_ROLES = [:school_teacher, :college_lycee_professor, :teaching_staff, :other].freeze
  SCHOOL_ADMIN_ROLES = [:school_director, :principal, :education_director, :other].freeze
  COMPANY_ADMIN_ROLES = [:association_president, :company_director, :organization_head, :other].freeze
  ```

- [ ] **Add role class methods** (after constants):
  ```ruby
  def self.is_teacher_role?(role)
    TEACHER_ROLES.include?(role.to_sym)
  end
  
  def self.is_school_admin_role?(role)
    SCHOOL_ADMIN_ROLES.include?(role.to_sym)
  end
  
  def self.is_company_admin_role?(role)
    COMPANY_ADMIN_ROLES.include?(role.to_sym)
  end
  
  def self.is_personal_user_role?(role)
    PERSONAL_USER_ROLES.include?(role.to_sym)
  end
  ```

- [ ] **Update academic email validation** (replace line 67):
  ```ruby
  # OLD:
  validate :academic_email?, if: -> { role == "teacher" && email.present? && !has_temporary_email? }
  
  # NEW:
  validate :academic_email?, if: -> { requires_academic_email? && email.present? && !has_temporary_email? }
  ```

- [ ] **Add requires_academic_email? method** (in private section):
  ```ruby
  def requires_academic_email?
    User.is_teacher_role?(role) || User.is_school_admin_role?(role)
  end
  ```

- [ ] **Add non-academic email validation** (in private section):
  ```ruby
  validate :non_academic_email_for_personal_user
  
  def non_academic_email_for_personal_user
    return unless User.is_personal_user_role?(role)
    return unless email.present?
    return if has_temporary_email?
    
    if is_academic_email?(email)
      errors.add(:email, "Les utilisateurs personnels ne peuvent pas utiliser d'email académique. Veuillez utiliser votre email personnel.")
    end
  end
  
  def is_academic_email?(email)
    email.match?(/@(ac-aix-marseille|ac-amiens|ac-besancon|ac-bordeaux|ac-caen|ac-clermont|ac-creteil|ac-corse|ac-dijon|ac-grenoble|ac-guadeloupe|ac-guyane|ac-lille|ac-limoges|ac-lyon|ac-martinique|ac-mayotte|ac-montpellier|ac-nancy-metz|ac-nantes|ac-nice|ac-orleans-tours|ac-paris|ac-poitiers|ac-reims|ac-rennes|ac-reunion|ac-rouen|ac-strasbourg|ac-toulouse|ac-versailles)\.fr$/) || 
    email.match?(/@education\.mc$/) || 
    email.match?(/@lfmadrid\.org$/)
  end
  ```

- [ ] **Add password complexity validation** (in private section):
  ```ruby
  validate :password_complexity
  
  def password_complexity
    return if password.blank? || skip_password_validation
    
    errors.add(:password, "doit contenir au moins 8 caractères") if password.length < 8
    errors.add(:password, "doit contenir au moins une lettre majuscule") unless password.match?(/[A-Z]/)
    errors.add(:password, "doit contenir au moins un caractère spécial") unless password.match?(/[!@#$%^&*(),.?":{}|<>]/)
  end
  ```

- [ ] **Add minimum age validation** (in private section):
  ```ruby
  validate :minimum_age
  
  def minimum_age
    return if birthday.blank?
    
    age = ((Time.zone.now - birthday.to_time) / 1.year.seconds).floor
    if age < 13
      errors.add(:birthday, "Vous devez avoir au moins 13 ans pour vous inscrire")
    end
  end
  ```

- [ ] **Update teachers scope** (line 93):
  ```ruby
  # OLD:
  scope :teachers, -> { where(role: "teacher") }
  
  # NEW:
  scope :teachers, -> { where(role: TEACHER_ROLES + SCHOOL_ADMIN_ROLES) }
  ```

- [ ] **Add ParentChildInfo association** (with other has_many associations):
  ```ruby
  has_many :parent_child_infos, foreign_key: :parent_user_id, dependent: :destroy
  ```

- [ ] **Remove old ADDITIONAL_ROLES constants** (lines 10-12) - no longer needed

- [ ] **Update scopes that reference roles**:
  - `participants_for_teacher` (line 71) - update role check
  - `participants_for_tutor` (line 80) - update role checks
  - Keep `voluntary`, `tutors`, `children` scopes unchanged (enum values still work)

**Critical Notes:**
- **BREAKING CHANGE:** Role enum values changed - will affect existing code
- Must search codebase for role checks: `grep -r ".teacher?" app/`
- Update all role checks to use new role names or role group methods
- Test thoroughly after changes

**Estimated Time:** 2 hours

---

#### Step 1.3: Search & Update Role Checks in Codebase
**Files:** Multiple files throughout codebase

**Tasks:**
- [ ] Search for role checks:
  ```bash
  grep -r "role == 'teacher'" app/
  grep -r ".teacher?" app/
  grep -r ".voluntary?" app/
  grep -r ".tutor?" app/
  grep -r "role.*teacher" app/
  ```

- [ ] **Update each occurrence:**
  - Replace `user.teacher?` with `User.is_teacher_role?(user.role)`
  - Replace `role == "teacher"` with `User.is_teacher_role?(role)`
  - Replace `role == "tutor"` with `role == "tutor"` (still works, enum value unchanged)
  - Replace `role == "voluntary"` with `role == "voluntary"` (still works)

- [ ] **Common patterns to update:**
  ```ruby
  # OLD:
  if user.teacher?
    # ...
  end
  
  # NEW:
  if User.is_teacher_role?(user.role)
    # ...
  end
  
  # OR (if checking specific role):
  if user.school_teacher? || user.college_lycee_professor? || user.teaching_staff?
    # ...
  end
  ```

- [ ] **Run existing tests** to catch any missed updates:
  ```bash
  bundle exec rspec
  ```

- [ ] Fix any broken tests

**Critical Notes:**
- This is the most error-prone step
- Test thoroughly after each batch of changes
- Keep a list of files modified for rollback if needed

**Estimated Time:** 2 hours

---

#### Step 1.4: Create ParentChildInfo Model
**File:** `app/models/parent_child_info.rb` (NEW)

**Tasks:**
- [ ] Create model file with associations:
  ```ruby
  class ParentChildInfo < ApplicationRecord
    belongs_to :parent_user, class_name: "User", foreign_key: :parent_user_id
    belongs_to :school, optional: true
    belongs_to :school_level, optional: true, foreign_key: :class_id
    belongs_to :linked_user, class_name: "User", foreign_key: :linked_user_id, optional: true
    
    validates :parent_user_id, presence: true
    
    scope :unlinked, -> { where(linked_user_id: nil) }
    scope :linked, -> { where.not(linked_user_id: nil) }
    
    def full_name
      "#{first_name} #{last_name}".strip
    end
    
    def linked?
      linked_user_id.present?
    end
  end
  ```

- [ ] Verify associations work in Rails console:
  ```ruby
  rails console
  user = User.first
  ParentChildInfo.create(parent_user: user, first_name: "Test")
  user.parent_child_infos.count
  ```

**Critical Notes:**
- Foreign key names must match migration
- Use `class_name` for clarity on User associations
- Scopes are for future matching logic

**Estimated Time:** 30 minutes

---

#### Step 1.5: Test Models & Associations
**Tasks:**
- [ ] Create model spec: `spec/models/parent_child_info_spec.rb`
- [ ] Test associations (parent_user, school, school_level, linked_user)
- [ ] Test validations (parent_user_id required)
- [ ] Test scopes (unlinked, linked)
- [ ] Test `full_name` and `linked?` methods
- [ ] Run: `bundle exec rspec spec/models/parent_child_info_spec.rb`

**Estimated Time:** 1 hour

---

#### Step 1.6: Commit Phase 1
**Command:**
```bash
git add .
git commit -m "feat: Add ParentChildInfo model and update User role enum

- Create parent_child_infos migration with all required fields
- Update User model role enum (16 new informative roles)
- Add role group constants and class methods
- Add password complexity validation (8+ chars, uppercase, special)
- Add minimum age validation (13+)
- Add academic email validation updates
- Add non-academic email validation for personal users
- Update teachers scope to include new teacher roles
- Add ParentChildInfo model with associations
- Update existing role checks throughout codebase
- Add comprehensive model specs for ParentChildInfo

BREAKING CHANGE: Role enum values changed - existing role checks updated"
```

**Estimated Time:** 30 minutes

---

### **PHASE 2: Registration Service (Day 2 - 8 hours)**

#### Step 2.1: Create RegistrationService
**File:** `app/services/registration_service.rb` (NEW)

**Tasks:**
- [ ] Create service file inheriting from `ApplicationService`
- [ ] Implement `initialize` method to capture all params:
  ```ruby
  def initialize(params)
    @params = params
    @registration_type = params[:registration_type]
    @user_params = params[:user] || {}
    @availability_params = params[:availability] || {}
    @skills_params = params[:skills] || {}
    @school_params = params[:school] || {}
    @company_params = params[:company] || {}
    @join_school_ids = params[:join_school_ids] || []
    @join_company_ids = params[:join_company_ids] || []
    @children_info = params[:children_info] || []
    @errors = []
  end
  ```

- [ ] Implement main `call` method with transaction:
  ```ruby
  def call
    validate_registration_type!
    validate_email_for_type!
    validate_role_for_type!
    
    return error_result if @errors.any?
    
    ActiveRecord::Base.transaction do
      create_user!
      
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
      
      send_confirmation_email!
    end
    
    success_result
  rescue ActiveRecord::RecordInvalid => e
    @errors = e.record.errors.full_messages
    error_result
  rescue => e
    @errors = [e.message]
    error_result
  end
  ```

- [ ] Implement validation methods:
  - `validate_registration_type!`
  - `validate_email_for_type!`
  - `validate_role_for_type!`
  - `is_academic_email?`

- [ ] Implement `create_user!` method:
  - Create User with params
  - Set `skip_password_validation = false`
  - Update availability if provided
  - Add skills/sub-skills if provided

- [ ] Implement `handle_personal_user_registration!`:
  - Join schools (pending)
  - Join companies (pending)
  - **Create ParentChildInfo records** (if children_info provided) ⭐

- [ ] Implement `handle_teacher_registration!`:
  - Join schools (pending)
  - IndependentTeacher auto-created by callback

- [ ] Implement `handle_school_registration!`:
  - Create School (pending)
  - Create UserSchool (superadmin, pending)

- [ ] Implement `handle_company_registration!`:
  - Create Company (confirmed)
  - Create UserCompany (superadmin, pending)
  - Create BranchRequest if specified

- [ ] Implement helper methods:
  - `send_confirmation_email!`
  - `notify_school_admins`
  - `notify_company_admins`
  - `success_result`
  - `error_result`

**Critical Notes:**
- All database operations wrapped in transaction
- Proper error handling and rollback
- Email confirmation sent AFTER all records created
- Children info creation in personal_user handler

**Estimated Time:** 4 hours

---

#### Step 2.2: Create RegistrationService Specs
**File:** `spec/services/registration_service_spec.rb` (NEW)

**Tasks:**
- [ ] Test personal_user registration (success)
- [ ] Test personal_user with children_info (creates ParentChildInfo) ⭐
- [ ] Test personal_user joining school/company
- [ ] Test teacher registration (success)
- [ ] Test teacher with academic email validation
- [ ] Test school registration (success)
- [ ] Test company registration (success)
- [ ] Test company branch request creation
- [ ] Test validation errors (wrong email, wrong role, etc.)
- [ ] Test transaction rollback on error
- [ ] Run: `bundle exec rspec spec/services/registration_service_spec.rb`

**Estimated Time:** 2 hours

---

#### Step 2.3: Test RegistrationService in Rails Console
**Tasks:**
- [ ] Open Rails console: `rails console`
- [ ] Test each registration type manually
- [ ] Verify ParentChildInfo records created ⭐
- [ ] Verify email confirmation sent
- [ ] Check transaction rollback works

**Estimated Time:** 1 hour

---

#### Step 2.4: Commit Phase 2
**Command:**
```bash
git add .
git commit -m "feat: Implement RegistrationService for unified registration

- Create RegistrationService with 4 registration type handlers
- Implement validation logic (type, email, role)
- Add children_info persistence for personal_user registration
- Create ParentChildInfo records during registration
- Handle school/company joining (pending status)
- Handle branch request creation for companies
- Implement transaction-wrapped operations
- Add comprehensive service specs"
```

**Estimated Time:** 30 minutes

---

### **PHASE 3: Controllers & Routes (Day 3 - 8 hours)**

#### Step 3.1: Add Register Endpoint to AuthController
**File:** `app/controllers/api/v1/auth_controller.rb`

**Tasks:**
- [ ] Add `register` method (see code below)
- [ ] Add `registration_params` private method
- [ ] Update `skip_before_action` at top of class
- [ ] **Update Postman Collection** ⭐:
  - Add "Register - Personal User" request with children_info example
  - Add "Register - Teacher" request
  - Add "Register - School" request
  - Add "Register - Company" request
  - Add "Register - Company with Branch Request" request
  - Include all validation error examples
  - Verify JSON structure is valid

**Code to implement:**
```ruby
# POST /api/v1/auth/register
# Unified registration endpoint for all 4 user types
def register
  skip_before_action :authenticate_api_user!, only: [:register]
    
    result = RegistrationService.new(registration_params).call
    
    if result[:success]
      render json: {
        message: "Registration successful! Please check your email to confirm your account.",
        email: result[:user].email,
        requires_confirmation: true
      }, status: :ok
    else
      render json: {
        error: "Validation failed",
        errors: result[:errors]
      }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Registration error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    render json: {
      error: "Registration failed",
      message: e.message
    }, status: :unprocessable_entity
  end
  ```

- [ ] Add `registration_params` private method:
  ```ruby
  private
  
  def registration_params
    params.permit(
      :registration_type,
      user: [
        :email, :password, :password_confirmation, :first_name, :last_name,
        :birthday, :role, :job, :take_trainee, :propose_workshop, :show_my_skills
      ],
      availability: [:monday, :tuesday, :wednesday, :thursday, :friday, :other],
      skills: [skill_ids: [], sub_skill_ids: []],
      join_school_ids: [],
      join_company_ids: [],
      children_info: [
        :first_name, :last_name, :birthday, :school_id, :school_name, :class_id, :class_name
      ],
      school: [:name, :address, :city, :zip_code],
      company: [
        :name, :description, :company_type_id, :zip_code, :city,
        :siret_number, :email, :branch_request_to_company_id
      ]
    )
  end
  ```

- [ ] Update `skip_before_action` at top of class (add `:register`)

**Critical Notes:**
- Registration endpoint must be public (no auth required)
- Proper error handling and logging
- Strong parameters properly configured

**Estimated Time:** 1 hour

---

#### Step 3.2: Create ParentChildrenController
**File:** `app/controllers/api/v1/parent_children_controller.rb` (NEW)

**Tasks:**
- [ ] Create controller inheriting from `Api::V1::BaseController`
- [ ] Implement CRUD actions (index, create, update, destroy)
- [ ] Add proper authorization
- [ ] Add error handling
- [ ] Add serialization method
- [ ] **Update Postman Collection** ⭐:
  - Add "GET /api/v1/parent_children" (List Children Info)
  - Add "POST /api/v1/parent_children" (Add Child Info)
  - Add "PATCH /api/v1/parent_children/:id" (Update Child Info)
  - Add "DELETE /api/v1/parent_children/:id" (Delete Child Info)
  - Include example request bodies
  - Include example responses
  - Verify JSON structure is valid

---

#### Step 3.3: Create SkillsController
**File:** `app/controllers/api/v1/skills_controller.rb` (NEW)

**Tasks:**
- [ ] Create controller with public endpoints (no auth required)
- [ ] Implement `index` - List all skills
- [ ] Implement `sub_skills` - List sub-skills for a skill
- [ ] Return JSON with proper structure
- [ ] **Update Postman Collection** ⭐:
  - Add "GET /api/v1/skills" (List All Skills)
  - Add "GET /api/v1/skills/:skill_id/sub_skills" (List Sub-Skills)
  - Include example responses
  - Verify JSON structure is valid

**Estimated Time:** 1 hour

---

#### Step 3.4: Update SchoolsController
**File:** `app/controllers/api/v1/schools_controller.rb`

**Tasks:**
- [ ] Add `list_for_joining` method
- [ ] **Update Postman Collection** ⭐:
  - Add "GET /api/v1/schools/list_for_joining" (List Schools for Joining)
  - Include example response
  - Verify JSON structure is valid

**Estimated Time:** 30 minutes

---

#### Step 3.5: Update CompaniesController
**File:** `app/controllers/api/v1/companies_controller.rb`

**Tasks:**
- [ ] Add `list_for_joining` method
- [ ] **Update Postman Collection** ⭐:
  - Add "GET /api/v1/companies/list_for_joining" (List Companies for Joining)
  - Include example response
  - Verify JSON structure is valid

**Estimated Time:** 30 minutes

---

#### Step 3.6: Create Auth::ConfirmationsController
**File:** `app/controllers/api/v1/auth/confirmations_controller.rb` (NEW)

**Tasks:**
- [ ] Create controller inheriting from `Devise::ConfirmationsController`
- [ ] Override `show` method for JSON responses
- [ ] Handle confirmation and organization confirmation
- [ ] **Update Postman Collection** ⭐:
  - Add "GET /api/v1/auth/confirmation" (Confirm Email)
  - Include example with confirmation_token parameter
  - Include example response
  - Verify JSON structure is valid

**Estimated Time:** 1 hour

---

#### Step 3.7: Update Routes
**File:** `config/routes.rb`

**Tasks:**
- [ ] Add registration route:
  ```ruby
  post 'auth/register', to: 'auth#register'
  ```

- [ ] Add skills routes:
  ```ruby
  resources :skills, only: [:index] do
    get :sub_skills, on: :member
  end
  ```

- [ ] Add schools/companies list routes:
  ```ruby
  get 'schools/list_for_joining', to: 'schools#list_for_joining'
  get 'companies/list_for_joining', to: 'companies#list_for_joining'
  ```

- [ ] Add parent_children routes:
  ```ruby
  resources :parent_children, only: [:index, :create, :show, :update, :destroy]
  ```

- [ ] Add confirmation route:
  ```ruby
  get 'auth/confirmation', to: 'auth/confirmations#show'
  ```

- [ ] Run: `rails routes | grep -E "(register|parent_children|skills|list_for_joining)"` to verify

**Estimated Time:** 30 minutes

---

#### Step 3.8: Create Request Specs
**File:** `spec/requests/api/v1/auth/registration_spec.rb` (NEW)

**Tasks:**
- [ ] Test personal_user registration (success)
- [ ] Test personal_user with children_info ⭐
- [ ] Test personal_user validation errors
- [ ] Test teacher registration (success)
- [ ] Test teacher with non-academic email (error)
- [ ] Test school registration (success)
- [ ] Test company registration (success)
- [ ] Test company branch request
- [ ] Test all 4 registration types error cases
- [ ] Run: `bundle exec rspec spec/requests/api/v1/auth/registration_spec.rb`

**File:** `spec/requests/api/v1/parent_children_spec.rb` (NEW)

**Tasks:**
- [ ] Test GET /api/v1/parent_children (index)
- [ ] Test POST /api/v1/parent_children (create)
- [ ] Test PATCH /api/v1/parent_children/:id (update)
- [ ] Test DELETE /api/v1/parent_children/:id (destroy)
- [ ] Test authorization (only parent can see their children)
- [ ] Run: `bundle exec rspec spec/requests/api/v1/parent_children_spec.rb`

**Estimated Time:** 2 hours

---

#### Step 3.9: Commit Phase 3
**Command:**
```bash
git add .
git commit -m "feat: Add registration and parent children API endpoints

- Add POST /api/v1/auth/register endpoint
- Create ParentChildrenController (CRUD for children info)
- Create SkillsController (public endpoints)
- Add list_for_joining to SchoolsController and CompaniesController
- Create Auth::ConfirmationsController (JSON responses)
- Add all required routes
- Add comprehensive request specs for all endpoints
- Update Postman collection with all new endpoints ⭐"
```

**Estimated Time:** 30 minutes

---

### **PHASE 4: Serializers & Email Flow (Day 4 - 8 hours)**

#### Step 4.1: Update UserSerializer
**File:** `app/serializers/user_serializer.rb`

**Tasks:**
- [ ] Update `available_contexts` method to:
  - Use new role group methods
  - Check `has_personal_dashboard?` correctly
  - Check `has_teacher_dashboard?` correctly
- [ ] Add `has_personal_dashboard?` method:
  ```ruby
  def has_personal_dashboard?
    User.is_personal_user_role?(object.role)
  end
  ```
- [ ] Add `has_teacher_dashboard?` method:
  ```ruby
  def has_teacher_dashboard?
    User.is_teacher_role?(object.role) || User.is_school_admin_role?(object.role)
  end
  ```
- [ ] Test serializer output matches expected structure

**Estimated Time:** 1 hour

---

#### Step 4.2: Test Email Confirmation Flow
**Tasks:**
- [ ] Create test user via registration endpoint
- [ ] Get confirmation token from email (or database)
- [ ] Call confirmation endpoint: `GET /api/v1/auth/confirmation?confirmation_token=xxx`
- [ ] Verify user confirmed
- [ ] Verify school/company confirmed if applicable
- [ ] Test invalid token handling

**Estimated Time:** 1 hour

---

#### Step 4.3: Test Login After Confirmation
**Tasks:**
- [ ] Confirm user email
- [ ] Login via `POST /api/v1/auth/login`
- [ ] Verify JWT token returned
- [ ] Verify `available_contexts` returned correctly
- [ ] Test unconfirmed user cannot login

**Estimated Time:** 1 hour

---

#### Step 4.4: Test Contexts Returned Correctly
**Tasks:**
- [ ] Login as personal_user → verify `user_dashboard: true`
- [ ] Login as teacher → verify `teacher_dashboard: true`
- [ ] Login as school admin → verify `schools` array populated
- [ ] Login as company admin → verify `companies` array populated
- [ ] Verify permissions calculated correctly

**Estimated Time:** 1 hour

---

#### Step 4.5: Test Registration End-to-End
**Tasks:**
- [ ] Test personal_user registration with curl:
  ```bash
  curl -X POST http://localhost:3000/api/v1/auth/register \
    -H "Content-Type: application/json" \
    -d '{
      "registration_type": "personal_user",
      "user": {
        "email": "test@example.com",
        "password": "Password123!",
        "password_confirmation": "Password123!",
        "first_name": "Test",
        "last_name": "User",
        "birthday": "1990-01-01",
        "role": "parent"
      },
      "children_info": [
        {
          "first_name": "Child",
          "last_name": "Test",
          "birthday": "2010-01-01"
        }
      ]
    }'
  ```

- [ ] Test teacher registration
- [ ] Test school registration
- [ ] Test company registration
- [ ] Test all validation errors

**Estimated Time:** 2 hours

---

#### Step 4.6: Test Parent Children CRUD
**Tasks:**
- [ ] Register parent with children_info
- [ ] Confirm email and login
- [ ] Test GET /api/v1/parent_children (should return children)
- [ ] Test POST /api/v1/parent_children (add new child)
- [ ] Test PATCH /api/v1/parent_children/:id (update child)
- [ ] Test DELETE /api/v1/parent_children/:id (delete child)

**Estimated Time:** 1 hour

---

#### Step 4.7: Commit Phase 4
**Command:**
```bash
git add .
git commit -m "feat: Update serializers and test email confirmation flow

- Update UserSerializer available_contexts for new roles
- Add has_personal_dashboard? and has_teacher_dashboard? methods
- Test email confirmation flow end-to-end
- Test login after confirmation
- Test contexts returned correctly for all user types
- Test parent children CRUD endpoints"
```

**Estimated Time:** 30 minutes

---

### **PHASE 5: Testing & Documentation (Day 5 - 8 hours)**

#### Step 5.1: Manual Testing with curl/Postman
**Tasks:**
- [ ] Test all 4 registration types via curl
- [ ] Test all validation errors
- [ ] Test email confirmation flow
- [ ] Test login after confirmation
- [ ] Test parent children CRUD
- [ ] Test skills/sub-skills endpoints
- [ ] Test schools/companies list endpoints
- [ ] **Test ALL endpoints in Postman** ⭐:
  - Verify all registration requests work
  - Verify all parent_children requests work
  - Verify all skills requests work
  - Verify all list_for_joining requests work
  - Document any issues found

**Estimated Time:** 2 hours

---

#### Step 5.2: Final Postman Collection Review & Validation
**File:** `postman_collection.json`

**Tasks:**
- [ ] **Verify all requests added during implementation** ⭐:
  - Registration endpoints (5 requests)
  - Parent children endpoints (4 requests)
  - Skills endpoints (2 requests)
  - Schools/companies list endpoints (2 requests)
  - Confirmation endpoint (1 request)
- [ ] **Validate JSON structure:**
  ```bash
  python3 -m json.tool postman_collection.json > /dev/null && echo "✅ Valid JSON"
  ```
- [ ] **Import into Postman** and verify no errors
- [ ] **Test each request** in Postman (if server running)
- [ ] **Verify examples are complete:**
  - All required fields included
  - Children_info examples present
  - Validation error examples present
- [ ] **Update collection description** to reflect registration API completion
- [ ] **Verify variable names** are consistent (`{{base_url}}`, `{{jwt_token}}`)

**Critical Notes:**
- Postman collection should be updated IMMEDIATELY after each endpoint (done in Phase 3)
- This step is FINAL REVIEW and validation only
- Must ensure JSON is valid before committing

**Estimated Time:** 1 hour

---

#### Step 5.3: Run Full Test Suite
**Tasks:**
- [ ] Run all model specs: `bundle exec rspec spec/models/`
- [ ] Run all service specs: `bundle exec rspec spec/services/`
- [ ] Run all request specs: `bundle exec rspec spec/requests/`
- [ ] Verify all tests pass
- [ ] Fix any failing tests

**Estimated Time:** 1 hour

---

#### Step 5.4: Update Documentation
**Files:** Various

**Tasks:**
- [ ] Update `REACT_INTEGRATION_STRATEGY.md`:
  - Mark "Week 1: Authentication & Registration" as completed
  - Add registration endpoint to API list
  - Add parent_children endpoints to API list
- [ ] Verify all documentation is consistent
- [ ] Create any missing documentation

**Estimated Time:** 1 hour

---

#### Step 5.5: Performance Check
**Tasks:**
- [ ] Check for N+1 queries in registration flow
- [ ] Add `includes` where needed
- [ ] Verify transaction performance
- [ ] Check email sending doesn't block request

**Estimated Time:** 1 hour

---

#### Step 5.6: Final Review & Commit
**Tasks:**
- [ ] Code review checklist (see below)
- [ ] Final git commit:
  ```bash
  git add .
  git commit -m "feat: Complete registration API implementation

  - Add comprehensive Postman collection
  - Update documentation
  - Fix all edge cases
  - Performance optimizations
  - All tests passing"
  ```

**Estimated Time:** 1 hour

---

## Critical Dependencies

### Order Matters!
1. **Migration MUST be created first** - Models depend on it
2. **User model MUST be updated before RegistrationService** - Service uses role methods
3. **RegistrationService MUST be created before AuthController** - Controller uses service
4. **Models MUST be created before controllers** - Controllers depend on models
5. **Routes MUST be updated last** - After all controllers exist

### Testing Order
1. Model specs first (fastest)
2. Service specs second (isolated)
3. Request specs last (slowest, full stack)

---

## Risk Mitigation

### Risk 1: Role Enum Breaking Changes
**Mitigation:**
- Search codebase thoroughly before changes
- Update all occurrences systematically
- Test after each batch of changes
- Keep list of files modified for rollback

### Risk 2: Transaction Failures
**Mitigation:**
- Wrap all operations in transaction
- Proper error handling and logging
- Test rollback scenarios
- Verify data integrity after errors

### Risk 3: Email Confirmation Issues
**Mitigation:**
- Test email delivery in development
- Verify confirmation token generation
- Test organization confirmation logic
- Handle edge cases (expired tokens, etc.)

### Risk 4: Children Info Persistence Issues
**Mitigation:**
- Test ParentChildInfo creation thoroughly
- Verify associations work correctly
- Test CRUD operations
- Verify no orphaned records

---

## Testing Strategy

### Unit Tests (Fast - Run Frequently)
- Model validations
- Model associations
- Model scopes
- Service logic
- Service validations

### Integration Tests (Medium - Run Before Commits)
- Registration flow end-to-end
- Email confirmation flow
- Login flow
- Parent children CRUD
- Context calculation

### Manual Tests (Slow - Run Before Deployment)
- Full registration flow in Postman
- All edge cases
- Error scenarios
- Performance testing

---

## Code Review Checklist

Before committing, verify:

### Models
- [ ] All validations are present
- [ ] All associations are correct
- [ ] Scopes are tested
- [ ] No N+1 query risks

### Services
- [ ] Transaction wrapping is correct
- [ ] Error handling is comprehensive
- [ ] Logging is appropriate
- [ ] All validation logic is tested

### Controllers
- [ ] Authorization is correct
- [ ] Strong parameters are configured
- [ ] Error responses are consistent
- [ ] Status codes are correct

### Routes
- [ ] All routes are defined
- [ ] HTTP methods are correct
- [ ] Paths are RESTful
- [ ] No duplicate routes

### Tests
- [ ] All paths are tested
- [ ] Edge cases are covered
- [ ] Error cases are tested
- [ ] Tests are passing

### Documentation
- [ ] Postman collection is updated ⭐
- [ ] REACT_INTEGRATION_STRATEGY.md is updated
- [ ] Code comments are clear
- [ ] Postman JSON structure is valid ⭐
- [ ] All new endpoints have Postman requests ⭐

---

## Success Criteria

✅ All 4 registration types work correctly  
✅ Email validation enforced (academic vs. non-academic)  
✅ Password complexity enforced  
✅ Age validation enforced (13+)  
✅ Email confirmation flow working  
✅ Contexts correctly calculated on login  
✅ Skills/sub-skills endpoints working  
✅ Schools/companies list endpoints working  
✅ Branch request creation working  
✅ Member joining notifications working  
✅ Children info persistence working ⭐  
✅ Parent children CRUD endpoints working ⭐  
✅ All existing tests still passing  
✅ New tests written and passing  
✅ Postman collection updated  
✅ Documentation updated  

---

## Ready to Implement! 🚀

This plan is:
- ✅ **Comprehensive** - All steps detailed
- ✅ **Sequential** - Logical order of operations
- ✅ **Testable** - Each step can be verified
- ✅ **Safe** - Risk mitigation included
- ✅ **Documented** - Clear instructions

**Estimated Total Time:** 40 hours (5 days)

**Ready to proceed?** → Review this plan and approve to begin implementation! 📋

