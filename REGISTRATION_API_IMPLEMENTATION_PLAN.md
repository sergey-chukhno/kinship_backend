# Registration API Implementation Plan
## Complete Registration System for 4 Dashboard Types

---

## Table of Contents
1. [Overview](#overview)
2. [Role System Changes](#role-system-changes)
3. [Registration Types](#registration-types)
4. [API Endpoint Structure](#api-endpoint-structure)
5. [Validation Rules](#validation-rules)
6. [Database Changes](#database-changes)
7. [Implementation Steps](#implementation-steps)
8. [Testing Strategy](#testing-strategy)
9. [Impact Analysis](#impact-analysis)

---

## 1. Overview

### Objectives
✅ Replace existing role enum with new informative roles  
✅ Create unified registration endpoint for 4 user types  
✅ Maintain email confirmation workflow  
✅ Support academic email validation for teachers/schools  
✅ Enable joining schools/companies during registration  
✅ Support branch company creation  
✅ Return available skills/sub-skills for frontend  
✅ Ensure backward compatibility with existing code  

### Key Principles
- **Single API endpoint**: `POST /api/v1/auth/register`
- **Email confirmation required**: No JWT token until email confirmed
- **Academic email enforcement**: Teachers and school admins must use academic emails
- **Age validation**: Users must be 13+ years old
- **Password complexity**: 8+ characters, 1 uppercase, 1 special character
- **Transaction safety**: All database operations wrapped in transactions

---

## 2. Role System Changes

### Current Role Enum (Line 61 in user.rb)
```ruby
enum :role, {teacher: 0, tutor: 1, voluntary: 2, children: 3}, default: :voluntary
```

### New Role Enum (TO REPLACE)
```ruby
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

### Role Groups for Logic
```ruby
# In User model, add class methods:
PERSONAL_USER_ROLES = [:parent, :grand_parent, :children, :voluntary, :tutor, :employee, :other].freeze
TEACHER_ROLES = [:school_teacher, :college_lycee_professor, :teaching_staff, :other].freeze
SCHOOL_ADMIN_ROLES = [:school_director, :principal, :education_director, :other].freeze
COMPANY_ADMIN_ROLES = [:association_president, :company_director, :organization_head, :other].freeze

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

### Academic Email Validation Update (Line 438)
```ruby
# CURRENT:
validate :academic_email?, if: -> { role == "teacher" && email.present? && !has_temporary_email? }

# NEW:
validate :academic_email?, if: -> { requires_academic_email? && email.present? && !has_temporary_email? }

def requires_academic_email?
  User.is_teacher_role?(role) || User.is_school_admin_role?(role)
end
```

### Scopes to Update
```ruby
# CURRENT (Line 93-94):
scope :teachers, -> { where(role: "teacher") }

# NEW:
scope :teachers, -> { where(role: TEACHER_ROLES + SCHOOL_ADMIN_ROLES) }
```

---

## 3. Registration Types

### Type 1: Personal User Registration
**Creates:**
- User account (with personal role)
- Availability record (auto-created by callback)
- UserSkill records (if skills selected)
- UserSubSkill records (if sub-skills selected)
- UserSchool records (if joining schools, status: pending)
- UserCompany records (if joining companies, status: pending)
- ParentChildInfo records (if children_info provided, one per child in array)

**Required Fields:**
- `email` (non-academic)
- `password` (8+ chars, 1 uppercase, 1 special)
- `password_confirmation`
- `first_name`
- `last_name`
- `birthday` (age >= 13)
- `role` (from PERSONAL_USER_ROLES)

**Optional Fields:**
- `job`
- `take_trainee` (boolean)
- `propose_workshop` (boolean)
- `show_my_skills` (boolean)
- `availability` (object with days)
- `skill_ids` (array)
- `sub_skill_ids` (array)
- `join_school_ids` (array)
- `join_company_ids` (array)
- `children_info` (array of child info objects, each with: first_name, last_name, birthday, school_id or school_name, class_id or class_name)

**Available Contexts After Confirmation:**
```json
{
  "user_dashboard": true,
  "teacher_dashboard": false,
  "schools": [],
  "companies": []
}
```

---

### Type 2: Teacher Registration
**Creates:**
- User account (with teacher role, academic email)
- Availability record (auto-created by callback)
- IndependentTeacher record (auto-created by callback)
- UserSchool records (if joining schools, status: pending)

**Required Fields:**
- `email` (MUST be academic)
- `password` (8+ chars, 1 uppercase, 1 special)
- `password_confirmation`
- `first_name`
- `last_name`
- `birthday` (age >= 13)
- `role` (from TEACHER_ROLES)

**Optional Fields:**
- `availability` (object with days)
- `show_my_skills` (boolean)
- `join_school_ids` (array)

**Available Contexts After Confirmation:**
```json
{
  "user_dashboard": false,
  "teacher_dashboard": true,
  "schools": [...]  // Only confirmed schools
}
```

**Note:** Teachers with academic emails CANNOT have personal dashboard unless they register separately with a non-academic email.

---

### Type 3: School Registration
**Creates:**
- User account (with school admin role, academic email)
- School record (with name, city, etc.)
- UserSchool record (user as superadmin, status: pending until email confirmed)
- Availability record (auto-created by callback)

**Required Fields:**
User:
- `email` (MUST be academic)
- `password` (8+ chars, 1 uppercase, 1 special)
- `password_confirmation`
- `first_name`
- `last_name`
- `birthday` (age >= 13)
- `role` (from SCHOOL_ADMIN_ROLES)

School:
- `name`

**Optional Fields:**
School:
- `address`
- `city`
- `zip_code`

**Available Contexts After Confirmation:**
```json
{
  "user_dashboard": false,
  "teacher_dashboard": false,
  "schools": [{
    "id": 123,
    "name": "Lycée Victor Hugo",
    "role": "superadmin",
    "permissions": {
      "admin": true,
      "owner": true,
      "can_access_badges": false  // Until contract
    }
  }],
  "companies": []
}
```

---

### Type 4: Company Registration
**Creates:**
- User account (with company admin role)
- Company record (with name, SIRET, company_type, etc.)
- UserCompany record (user as superadmin, status: pending until email confirmed)
- Availability record (auto-created by callback)
- BranchRequest record (if joining existing company as branch, status: pending)

**Required Fields:**
User:
- `email` (can be any valid email, not academic)
- `password` (8+ chars, 1 uppercase, 1 special)
- `password_confirmation`
- `first_name`
- `last_name`
- `birthday` (age >= 13)
- `role` (from COMPANY_ADMIN_ROLES)

Company:
- `name`
- `description`
- `company_type_id` (association, enterprise, institution, metropole, cite_educative)
- `zip_code`
- `city`

**Optional Fields:**
Company:
- `siret_number`
- `email`
- `branch_request_to_company_id` (creates BranchRequest)

**Available Contexts After Confirmation:**
```json
{
  "user_dashboard": false,
  "teacher_dashboard": false,
  "schools": [],
  "companies": [{
    "id": 456,
    "name": "Tech Education Corp",
    "role": "superadmin",
    "permissions": {
      "admin": true,
      "owner": true,
      "can_access_badges": false,  // Until contract
      "can_create_project": false  // Until contract
    }
  }]
}
```

---

## 4. API Endpoint Structure

### Single Registration Endpoint

```
POST /api/v1/auth/register
Content-Type: application/json
```

### Request Body Schema

```json
{
  "registration_type": "personal_user" | "teacher" | "school" | "company",
  
  "user": {
    "email": "string (required)",
    "password": "string (required, 8+ chars, 1 uppercase, 1 special)",
    "password_confirmation": "string (required, must match password)",
    "first_name": "string (required)",
    "last_name": "string (required)",
    "birthday": "date (required, YYYY-MM-DD, age >= 13)",
    "role": "string (required, from appropriate role list)",
    "job": "string (optional)",
    "take_trainee": "boolean (optional)",
    "propose_workshop": "boolean (optional)",
    "show_my_skills": "boolean (optional)"
  },
  
  "availability": {
    "monday": "boolean (optional)",
    "tuesday": "boolean (optional)",
    "wednesday": "boolean (optional)",
    "thursday": "boolean (optional)",
    "friday": "boolean (optional)",
    "other": "boolean (optional)"
  },
  
  "skills": {
    "skill_ids": ["array of integers (optional)"],
    "sub_skill_ids": ["array of integers (optional)"]
  },
  
  "join_school_ids": ["array of integers (optional, personal_user & teacher only)"],
  "join_company_ids": ["array of integers (optional, personal_user only)"],
  
  "children_info": [
    {
      "first_name": "string (optional)",
      "last_name": "string (optional)",
      "birthday": "date (optional, YYYY-MM-DD)",
      "school_id": "integer (optional, if school selected from list)",
      "school_name": "string (optional, if school entered as free-text)",
      "class_id": "integer (optional, if class selected from list)",
      "class_name": "string (optional, if class entered as free-text)"
    }
  ],
  
  "school": {
    "name": "string (required if registration_type = school)",
    "address": "string (optional)",
    "city": "string (optional)",
    "zip_code": "string (optional)"
  },
  
  "company": {
    "name": "string (required if registration_type = company)",
    "description": "string (required if registration_type = company)",
    "company_type_id": "integer (required if registration_type = company)",
    "zip_code": "string (required if registration_type = company)",
    "city": "string (required if registration_type = company)",
    "siret_number": "string (optional)",
    "email": "string (optional)",
    "branch_request_to_company_id": "integer (optional, creates branch request)"
  }
}
```

### Success Response (200 OK)

```json
{
  "message": "Registration successful! Please check your email to confirm your account.",
  "email": "user@example.com",
  "requires_confirmation": true
}
```

### Error Responses

**400 Bad Request - Validation Error:**
```json
{
  "error": "Validation failed",
  "errors": [
    "Email doit être rempli(e)",
    "Password doit contenir au moins 8 caractères",
    "Birthday - Vous devez avoir au moins 13 ans"
  ]
}
```

**422 Unprocessable Entity - Academic Email Violation:**
```json
{
  "error": "Invalid email for registration type",
  "message": "Teachers and school administrators must use academic email addresses"
}
```

**422 Unprocessable Entity - Email Already Taken:**
```json
{
  "error": "Email already registered",
  "message": "This email is already associated with an account"
}
```

---

## 5. Validation Rules

### Email Validation

**Personal User:**
```ruby
# Must NOT be academic email
validate :non_academic_email_for_personal_user

def non_academic_email_for_personal_user
  return unless User.is_personal_user_role?(role)
  return unless email.present?
  
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

**Teacher / School Admin:**
```ruby
# MUST be academic email (existing validation, line 438-444)
validate :academic_email?, if: -> { requires_academic_email? }

def requires_academic_email?
  User.is_teacher_role?(role) || User.is_school_admin_role?(role)
end
```

**Company Admin:**
```ruby
# Can be any valid email (no restriction)
```

### Password Validation

```ruby
validate :password_complexity

def password_complexity
  return if password.blank? || skip_password_validation
  
  errors.add(:password, "doit contenir au moins 8 caractères") if password.length < 8
  errors.add(:password, "doit contenir au moins une lettre majuscule") unless password.match?(/[A-Z]/)
  errors.add(:password, "doit contenir au moins un caractère spécial") unless password.match?(/[!@#$%^&*(),.?":{}|<>]/)
end
```

### Age Validation

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

### Role Validation

```ruby
validate :valid_role_for_registration_type

def valid_role_for_registration_type
  return if role.blank?
  
  # Will be validated in the controller based on registration_type
  # This ensures role matches the registration type
end
```

---

## 6. Database Changes

### NEW MIGRATION NEEDED: parent_child_infos table ✅

**Migration: Create `parent_child_infos` table**

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_parent_child_infos.rb
class CreateParentChildInfos < ActiveRecord::Migration[7.1]
  def change
    create_table :parent_child_infos do |t|
      t.references :parent_user, null: false, foreign_key: { to_table: :users }
      t.string :first_name
      t.string :last_name
      t.date :birthday
      t.references :school, null: true, foreign_key: true
      t.string :school_name
      t.references :school_level, null: true, foreign_key: true, column: :class_id
      t.string :class_name
      t.references :linked_user, null: true, foreign_key: { to_table: :users }
      
      t.timestamps
    end
    
    add_index :parent_child_infos, :parent_user_id
    add_index :parent_child_infos, :linked_user_id
  end
end
```

### Other Changes (No Schema Migrations Needed)

**Why?**
- All required fields already exist in the database
- Role enum values are stored as integers (doesn't matter what we call them)
- User model fields already exist

**What Changes:**
- ✅ User model enum definition (code only)
- ✅ User model validation logic (code only)
- ✅ User model scopes (code only)
- ✅ NEW: ParentChildInfo model (new table)

---

## 7. Implementation Steps

### Step 1: Update User Model Role Enum
**File:** `app/models/user.rb`

**Changes:**
1. Replace line 61 role enum with new roles
2. Add role group constants (PERSONAL_USER_ROLES, TEACHER_ROLES, etc.)
3. Add class methods (`is_teacher_role?`, etc.)
4. Update `requires_academic_email?` method
5. Add `non_academic_email_for_personal_user` validation
6. Add `password_complexity` validation
7. Add `minimum_age` validation
8. Update `teachers` scope (line 93)
9. Remove old ADDITIONAL_ROLES constants (lines 10-12) - no longer needed
10. Add `has_many :parent_child_infos` association ⭐ NEW

**Affected Scopes:**
- `participants_for_teacher` (line 71) - update role check
- `participants_for_tutor` (line 80) - update role checks
- `voluntary` (line 92) - still works (enum value unchanged)
- `teachers` (line 93) - update to include new teacher roles
- `tutors` (line 94) - still works (enum value unchanged)

### Step 2: Create Registration Controller
**File:** `app/controllers/api/v1/auth_controller.rb`

**Add Method:**
```ruby
# POST /api/v1/auth/register
# Unified registration endpoint for all 4 user types
def register
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
  render json: {
    error: "Registration failed",
    message: e.message
  }, status: :unprocessable_entity
end

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

### Step 3: Create Registration Service
**File:** `app/services/registration_service.rb`

```ruby
class RegistrationService < ApplicationService
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
  
  private
  
  def validate_registration_type!
    unless %w[personal_user teacher school company].include?(@registration_type)
      @errors << "Type d'inscription invalide"
    end
  end
  
  def validate_email_for_type!
    email = @user_params[:email]
    return if email.blank?
    
    is_academic = is_academic_email?(email)
    
    case @registration_type
    when 'personal_user'
      if is_academic
        @errors << "Les utilisateurs personnels ne peuvent pas utiliser d'email académique"
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
      @errors << "Rôle invalide pour ce type d'inscription"
    end
  end
  
  def is_academic_email?(email)
    email.match?(/@(ac-aix-marseille|ac-amiens|ac-besancon|ac-bordeaux|ac-caen|ac-clermont|ac-creteil|ac-corse|ac-dijon|ac-grenoble|ac-guadeloupe|ac-guyane|ac-lille|ac-limoges|ac-lyon|ac-martinique|ac-mayotte|ac-montpellier|ac-nancy-metz|ac-nantes|ac-nice|ac-orleans-tours|ac-paris|ac-poitiers|ac-reims|ac-rennes|ac-reunion|ac-rouen|ac-strasbourg|ac-toulouse|ac-versailles)\.fr$/) || 
    email.match?(/@education\.mc$/) || 
    email.match?(/@lfmadrid\.org$/)
  end
  
  def create_user!
    @user = User.new(@user_params)
    @user.skip_password_validation = false
    @user.save!
    
    # Update availability if provided
    if @availability_params.any? && @user.availability
      @user.availability.update!(@availability_params)
    end
    
    # Add skills if provided
    if @skills_params[:skill_ids].present?
      @skills_params[:skill_ids].each do |skill_id|
        @user.user_skills.create!(skill_id: skill_id)
      end
    end
    
    # Add sub-skills if provided
    if @skills_params[:sub_skill_ids].present?
      @skills_params[:sub_skill_ids].each do |sub_skill_id|
        @user.user_sub_skills.create!(sub_skill_id: sub_skill_id)
      end
    end
  end
  
  def handle_personal_user_registration!
    # Join schools as pending member
    @join_school_ids.each do |school_id|
      school = School.find(school_id)
      user_school = @user.user_schools.create!(
        school: school,
        status: :pending,
        role: :member
      )
      
      # Notify school admins
      notify_school_admins(school, @user)
    end
    
    # Join companies as pending member
    @join_company_ids.each do |company_id|
      company = Company.find(company_id)
      user_company = @user.user_company.create!(
        company: company,
        status: :pending,
        role: :member
      )
      
      # Notify company admins
      notify_company_admins(company, @user)
    end
    
    # Create ParentChildInfo records if children_info provided
    if @children_info.present?
      @children_info.each do |child_info|
        ParentChildInfo.create!(
          parent_user: @user,
          first_name: child_info[:first_name],
          last_name: child_info[:last_name],
          birthday: child_info[:birthday],
          school_id: child_info[:school_id],
          school_name: child_info[:school_name],
          class_id: child_info[:class_id],
          class_name: child_info[:class_name]
        )
      end
    end
  end
  
  def handle_teacher_registration!
    # Join schools as pending member
    @join_school_ids.each do |school_id|
      school = School.find(school_id)
      user_school = @user.user_schools.create!(
        school: school,
        status: :pending,
        role: :member
      )
      
      # Notify school admins
      notify_school_admins(school, @user)
    end
    
    # IndependentTeacher is auto-created by after_create callback
  end
  
  def handle_school_registration!
    # Create school
    school = School.create!(
      name: @school_params[:name],
      address: @school_params[:address],
      city: @school_params[:city],
      zip_code: @school_params[:zip_code],
      status: :pending  # Will be confirmed when user confirms email
    )
    
    # Create UserSchool as superadmin (owner)
    @user.user_schools.create!(
      school: school,
      status: :pending,  # Will be confirmed when user confirms email
      role: :superadmin
    )
    
    @school = school
  end
  
  def handle_company_registration!
    # Create company
    company = Company.create!(
      name: @company_params[:name],
      description: @company_params[:description],
      company_type_id: @company_params[:company_type_id],
      zip_code: @company_params[:zip_code],
      city: @company_params[:city],
      siret_number: @company_params[:siret_number],
      email: @company_params[:email],
      status: :confirmed  # Company is confirmed immediately (not pending on user)
    )
    
    # Create UserCompany as superadmin (owner)
    @user.user_company.create!(
      company: company,
      status: :pending,  # Will be confirmed when user confirms email
      role: :superadmin
    )
    
    # Create branch request if specified
    if @company_params[:branch_request_to_company_id].present?
      parent_company = Company.find(@company_params[:branch_request_to_company_id])
      
      branch_request = BranchRequest.create!(
        parent: parent_company,
        child: company,
        status: :pending
      )
      
      # Notify parent company admins
      BranchRequestMailer.branch_request_created(branch_request).deliver_later
    end
    
    @company = company
  end
  
  def send_confirmation_email!
    @user.send_confirmation_instructions
  end
  
  def notify_school_admins(school, user)
    # Use existing member invitation mailer
    school.users_admin.each do |admin|
      # Implement notification logic (reuse existing patterns)
    end
  end
  
  def notify_company_admins(company, user)
    # Use existing member invitation mailer
    company.users_admin.each do |admin|
      # Implement notification logic (reuse existing patterns)
    end
  end
  
  def success_result
    { success: true, user: @user, school: @school, company: @company }
  end
  
  def error_result
    { success: false, errors: @errors }
  end
end
```

### Step 3.5: Create ParentChildInfo Model and Controller
**File:** `app/models/parent_child_info.rb` (NEW)

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

**Migration:** Create `parent_child_infos` table (see Database Changes section above)

**File:** `app/controllers/api/v1/parent_children_controller.rb` (NEW)

```ruby
class Api::V1::ParentChildrenController < Api::V1::BaseController
  before_action :set_parent_child_info, only: [:show, :update, :destroy]
  
  # GET /api/v1/parent_children
  # List all children info for logged-in parent
  def index
    @children_info = current_user.parent_child_infos.order(created_at: :desc)
    
    render json: {
      data: @children_info.map { |child| serialize_child_info(child) }
    }, status: :ok
  end
  
  # POST /api/v1/parent_children
  # Add new child info
  def create
    @child_info = current_user.parent_child_infos.build(parent_child_info_params)
    
    if @child_info.save
      render json: {
        message: "Child information added successfully",
        data: serialize_child_info(@child_info)
      }, status: :created
    else
      render json: {
        error: "Validation failed",
        errors: @child_info.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/parent_children/:id
  # Update child info
  def update
    if @parent_child_info.update(parent_child_info_params)
      render json: {
        message: "Child information updated successfully",
        data: serialize_child_info(@parent_child_info)
      }, status: :ok
    else
      render json: {
        error: "Validation failed",
        errors: @parent_child_info.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/parent_children/:id
  # Remove child info
  def destroy
    @parent_child_info.destroy
    head :no_content
  end
  
  private
  
  def set_parent_child_info
    @parent_child_info = current_user.parent_child_infos.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: "Child information not found"
    }, status: :not_found
  end
  
  def parent_child_info_params
    params.require(:parent_child_info).permit(
      :first_name, :last_name, :birthday,
      :school_id, :school_name, :class_id, :class_name
    )
  end
  
  def serialize_child_info(child_info)
    {
      id: child_info.id,
      first_name: child_info.first_name,
      last_name: child_info.last_name,
      birthday: child_info.birthday&.iso8601,
      school_id: child_info.school_id,
      school_name: child_info.school_name,
      school: child_info.school ? { id: child_info.school.id, name: child_info.school.name } : nil,
      class_id: child_info.class_id,
      class_name: child_info.class_name,
      school_level: child_info.school_level ? { id: child_info.school_level.id, name: child_info.school_level.name } : nil,
      linked_user_id: child_info.linked_user_id,
      linked: child_info.linked?,
      created_at: child_info.created_at.iso8601,
      updated_at: child_info.updated_at.iso8601
    }
  end
end
```

**Update Routes:**
```ruby
# In config/routes.rb
namespace :api do
  namespace :v1 do
    # ... existing routes
    
    # Parent Children Info
    resources :parent_children, only: [:index, :create, :show, :update, :destroy]
  end
end
```

### Step 4: Add Skills/SubSkills Endpoints
**File:** `app/controllers/api/v1/skills_controller.rb`

```ruby
class Api::V1::SkillsController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [:index, :sub_skills]
  
  # GET /api/v1/skills
  # Returns all available skills for registration form
  def index
    @skills = Skill.officials.order(:name)
    
    render json: {
      data: @skills.map { |skill| { id: skill.id, name: skill.name } }
    }, status: :ok
  end
  
  # GET /api/v1/skills/:skill_id/sub_skills
  # Returns sub-skills for a specific skill
  def sub_skills
    skill = Skill.find(params[:skill_id])
    @sub_skills = skill.sub_skills.order(:name)
    
    render json: {
      data: @sub_skills.map { |sub_skill| { id: sub_skill.id, name: sub_skill.name } }
    }, status: :ok
  end
end
```

### Step 5: Add Schools/Companies List Endpoints
**File:** `app/controllers/api/v1/schools_controller.rb`

```ruby
# Add to existing controller or create if doesn't exist
def list_for_joining
  @schools = School.confirmed.order(:name)
  
  render json: {
    data: @schools.map { |school| { id: school.id, name: school.full_name } }
  }, status: :ok
end
```

**File:** `app/controllers/api/v1/companies_controller.rb`

```ruby
# Add to existing controller
def list_for_joining
  @companies = Company.confirmed.where(parent_company_id: nil).order(:name)
  
  render json: {
    data: @companies.map { |company| { id: company.id, name: company.name } }
  }, status: :ok
end
```

### Step 6: Update Routes
**File:** `config/routes.rb`

```ruby
namespace :api do
  namespace :v1 do
    # Authentication
    post 'auth/login', to: 'auth#login'
    post 'auth/register', to: 'auth#register'  # NEW
    delete 'auth/logout', to: 'auth#logout'
    post 'auth/refresh', to: 'auth#refresh'
    get 'auth/me', to: 'auth#me'
    
    # Skills (public, for registration form)
    resources :skills, only: [:index] do
      get :sub_skills, on: :member  # NEW
    end
    
    # Schools & Companies (public list for joining)
    get 'schools/list_for_joining', to: 'schools#list_for_joining'  # NEW
    get 'companies/list_for_joining', to: 'companies#list_for_joining'  # NEW
    
    # ... existing routes
  end
end
```

### Step 7: Update UserSerializer
**File:** `app/serializers/user_serializer.rb`

```ruby
# Update available_contexts method to handle new roles
def available_contexts
  {
    user_dashboard: has_personal_dashboard?,
    teacher_dashboard: has_teacher_dashboard?,
    schools: object.user_schools.confirmed.map do |us|
      {
        id: us.school.id,
        name: us.school.name,
        role: us.superadmin? ? 'superadmin' : (us.admin? ? 'admin' : 'member'),
        permissions: {
          admin: us.admin? || us.superadmin?,
          owner: us.superadmin?,
          can_access_badges: us.can_assign_badges?
        }
      }
    end,
    companies: object.user_company.confirmed.map do |uc|
      {
        id: uc.company.id,
        name: uc.company.name,
        role: uc.superadmin? ? 'superadmin' : (uc.admin? ? 'admin' : 'member'),
        permissions: {
          admin: uc.admin? || uc.superadmin?,
          owner: uc.superadmin?,
          can_access_badges: uc.can_assign_badges?,
          can_create_project: uc.can_create_project?
        }
      }
    end
  }
end

def has_personal_dashboard?
  # Personal dashboard only for personal user roles
  User.is_personal_user_role?(object.role)
end

def has_teacher_dashboard?
  # Teacher dashboard for teacher roles OR school admins (they can teach)
  User.is_teacher_role?(object.role) || User.is_school_admin_role?(object.role)
end
```

### Step 8: Update Confirmation Flow
**File:** `app/controllers/api/v1/auth/confirmations_controller.rb` (NEW)

```ruby
class Api::V1::Auth::ConfirmationsController < Devise::ConfirmationsController
  # GET /api/v1/auth/confirmation?confirmation_token=xxx
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    
    if resource.errors.empty?
      # Confirm associated school/company if applicable
      confirm_associated_organizations!(resource)
      
      render json: {
        message: "Email confirmed successfully! You can now log in.",
        confirmed: true
      }, status: :ok
    else
      render json: {
        error: "Invalid confirmation token",
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def confirm_associated_organizations!(user)
    # Confirm UserSchool if user is superadmin (school registration)
    user.user_schools.where(role: :superadmin, status: :pending).each do |us|
      us.update!(status: :confirmed)
      us.school.update!(status: :confirmed) if us.school.pending?
    end
    
    # Confirm UserCompany if user is superadmin (company registration)
    user.user_company.where(role: :superadmin, status: :pending).each do |uc|
      uc.update!(status: :confirmed)
    end
  end
end
```

---

## 8. Testing Strategy

### Unit Tests (RSpec)

**Test 1: User Model Role Enum**
```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe 'role enum' do
    it 'supports personal user roles' do
      user = build(:user, role: :parent)
      expect(user.role).to eq('parent')
      expect(User.is_personal_user_role?(user.role)).to be true
    end
    
    it 'supports teacher roles' do
      user = build(:user, role: :school_teacher)
      expect(User.is_teacher_role?(user.role)).to be true
    end
    
    it 'supports school admin roles' do
      user = build(:user, role: :school_director)
      expect(User.is_school_admin_role?(user.role)).to be true
    end
    
    it 'supports company admin roles' do
      user = build(:user, role: :company_director)
      expect(User.is_company_admin_role?(user.role)).to be true
    end
  end
  
  describe 'email validation' do
    it 'rejects academic email for personal users' do
      user = build(:user, role: :parent, email: 'test@ac-paris.fr')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include(match(/académique/))
    end
    
    it 'requires academic email for teachers' do
      user = build(:user, role: :school_teacher, email: 'test@gmail.com')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include(match(/académique/))
    end
    
    it 'accepts academic email for teachers' do
      user = build(:user, role: :school_teacher, email: 'teacher@ac-paris.fr')
      expect(user).to be_valid
    end
  end
  
  describe 'password validation' do
    it 'requires 8+ characters' do
      user = build(:user, password: 'Short1!')
      expect(user).not_to be_valid
    end
    
    it 'requires uppercase letter' do
      user = build(:user, password: 'lowercase1!')
      expect(user).not_to be_valid
    end
    
    it 'requires special character' do
      user = build(:user, password: 'Password1')
      expect(user).not_to be_valid
    end
    
    it 'accepts valid password' do
      user = build(:user, password: 'Valid123!')
      expect(user).to be_valid
    end
  end
  
  describe 'age validation' do
    it 'rejects users under 13' do
      user = build(:user, birthday: 12.years.ago)
      expect(user).not_to be_valid
    end
    
    it 'accepts users 13 or older' do
      user = build(:user, birthday: 13.years.ago)
      expect(user).to be_valid
    end
  end
end
```

### Integration Tests (Request Specs)

**Test 2: Personal User Registration**
```ruby
# spec/requests/api/v1/auth/registration_spec.rb
RSpec.describe 'POST /api/v1/auth/register', type: :request do
  describe 'personal user registration' do
    let(:valid_params) do
      {
        registration_type: 'personal_user',
        user: {
          email: 'user@example.com',
          password: 'Password123!',
          password_confirmation: 'Password123!',
          first_name: 'John',
          last_name: 'Doe',
          birthday: 20.years.ago.to_date,
          role: 'parent'
        }
      }
    end
    
    it 'creates a new user' do
      expect {
        post '/api/v1/auth/register', params: valid_params
      }.to change(User, :count).by(1)
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to include('Registration successful')
      expect(json['requires_confirmation']).to be true
    end
    
    it 'rejects academic email for personal user' do
      valid_params[:user][:email] = 'user@ac-paris.fr'
      
      post '/api/v1/auth/register', params: valid_params
      
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to include(match(/académique/))
    end
    
    it 'creates availability record' do
      post '/api/v1/auth/register', params: valid_params
      
      user = User.last
      expect(user.availability).to be_present
    end
    
    it 'joins schools if specified' do
      school = create(:school, :confirmed)
      valid_params[:join_school_ids] = [school.id]
      
      post '/api/v1/auth/register', params: valid_params
      
      user = User.last
      expect(user.user_schools.pending.count).to eq(1)
      expect(user.user_schools.first.school).to eq(school)
    end
    
    it 'creates ParentChildInfo records if children_info provided' do
      valid_params[:children_info] = [
        {
          first_name: "Anna",
          last_name: "Dupont",
          birthday: "2010-08-15",
          school_id: create(:school, :confirmed).id,
          class_name: "CP B"
        }
      ]
      
      expect {
        post '/api/v1/auth/register', params: valid_params
      }.to change(ParentChildInfo, :count).by(1)
      
      user = User.last
      child_info = user.parent_child_infos.first
      expect(child_info.first_name).to eq("Anna")
      expect(child_info.last_name).to eq("Dupont")
      expect(child_info.linked_user_id).to be_nil
    end
  end
  
  describe 'teacher registration' do
    let(:valid_params) do
      {
        registration_type: 'teacher',
        user: {
          email: 'teacher@ac-paris.fr',
          password: 'Password123!',
          password_confirmation: 'Password123!',
          first_name: 'Marie',
          last_name: 'Dupont',
          birthday: 30.years.ago.to_date,
          role: 'school_teacher'
        }
      }
    end
    
    it 'creates teacher with academic email' do
      expect {
        post '/api/v1/auth/register', params: valid_params
      }.to change(User, :count).by(1)
      
      expect(response).to have_http_status(:ok)
      user = User.last
      expect(user.role).to eq('school_teacher')
      expect(user.independent_teacher).to be_present
    end
    
    it 'rejects non-academic email' do
      valid_params[:user][:email] = 'teacher@gmail.com'
      
      post '/api/v1/auth/register', params: valid_params
      
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
  
  describe 'school registration' do
    let(:valid_params) do
      {
        registration_type: 'school',
        user: {
          email: 'director@ac-paris.fr',
          password: 'Password123!',
          password_confirmation: 'Password123!',
          first_name: 'Jean',
          last_name: 'Martin',
          birthday: 40.years.ago.to_date,
          role: 'school_director'
        },
        school: {
          name: 'Lycée Test',
          city: 'Paris',
          zip_code: '75001'
        }
      }
    end
    
    it 'creates user, school, and user_school' do
      expect {
        post '/api/v1/auth/register', params: valid_params
      }.to change(User, :count).by(1)
       .and change(School, :count).by(1)
       .and change(UserSchool, :count).by(1)
      
      expect(response).to have_http_status(:ok)
      
      user = User.last
      school = School.last
      user_school = UserSchool.last
      
      expect(user_school.user).to eq(user)
      expect(user_school.school).to eq(school)
      expect(user_school.superadmin?).to be true
      expect(user_school.pending?).to be true
    end
  end
  
  describe 'company registration' do
    let(:company_type) { create(:company_type) }
    let(:valid_params) do
      {
        registration_type: 'company',
        user: {
          email: 'ceo@example.com',
          password: 'Password123!',
          password_confirmation: 'Password123!',
          first_name: 'Sophie',
          last_name: 'Bernard',
          birthday: 35.years.ago.to_date,
          role: 'company_director'
        },
        company: {
          name: 'Tech Corp',
          description: 'Technology company',
          company_type_id: company_type.id,
          zip_code: '75002',
          city: 'Paris'
        }
      }
    end
    
    it 'creates user, company, and user_company' do
      expect {
        post '/api/v1/auth/register', params: valid_params
      }.to change(User, :count).by(1)
       .and change(Company, :count).by(1)
       .and change(UserCompany, :count).by(1)
      
      expect(response).to have_http_status(:ok)
      
      user = User.last
      company = Company.last
      user_company = UserCompany.last
      
      expect(user_company.user).to eq(user)
      expect(user_company.company).to eq(company)
      expect(user_company.superadmin?).to be true
    end
    
    it 'creates branch request if specified' do
      parent_company = create(:company, :confirmed)
      valid_params[:company][:branch_request_to_company_id] = parent_company.id
      
      expect {
        post '/api/v1/auth/register', params: valid_params
      }.to change(BranchRequest, :count).by(1)
      
      branch_request = BranchRequest.last
      expect(branch_request.parent).to eq(parent_company)
      expect(branch_request.child).to eq(Company.last)
      expect(branch_request.pending?).to be true
    end
  end
end
```

### Manual Testing (Postman)

**Test 3: Registration Endpoints**
- Personal user with skills
- Personal user joining school
- Personal user joining company
- Teacher with academic email
- Teacher joining school
- School admin creating school
- Company admin creating company
- Company admin creating branch company

---

## 9. Impact Analysis

### Files to Modify

✅ **Models:**
- `app/models/user.rb` - role enum, validations, scopes
- `app/models/parent_child_info.rb` - NEW ⭐

✅ **Controllers:**
- `app/controllers/api/v1/auth_controller.rb` - add register method
- `app/controllers/api/v1/skills_controller.rb` - NEW
- `app/controllers/api/v1/schools_controller.rb` - add list_for_joining
- `app/controllers/api/v1/companies_controller.rb` - add list_for_joining
- `app/controllers/api/v1/auth/confirmations_controller.rb` - NEW
- `app/controllers/api/v1/parent_children_controller.rb` - NEW ⭐

✅ **Services:**
- `app/services/registration_service.rb` - NEW

✅ **Serializers:**
- `app/serializers/user_serializer.rb` - update available_contexts

✅ **Routes:**
- `config/routes.rb` - add registration routes, add parent_children routes ⭐

✅ **Tests:**
- `spec/models/user_spec.rb` - role tests
- `spec/requests/api/v1/auth/registration_spec.rb` - NEW
- `spec/services/registration_service_spec.rb` - NEW
- `spec/models/parent_child_info_spec.rb` - NEW ⭐
- `spec/requests/api/v1/parent_children_spec.rb` - NEW ⭐

✅ **Documentation:**
- `postman_collection.json` - add registration requests
- `REACT_INTEGRATION_STRATEGY.md` - mark registration as completed

### Potential Breaking Changes

⚠️ **Role Enum Change:**
- **What breaks:** Code that checks `user.teacher?`, `user.voluntary?`, etc.
- **Solution:** Update to use new role names OR check role groups
- **Example:**
  ```ruby
  # OLD:
  if user.teacher?
  
  # NEW:
  if User.is_teacher_role?(user.role)
  ```

⚠️ **Scopes:**
- `User.teachers` scope returns different users
- **Solution:** Already updated in Step 1

⚠️ **I18n Translations:**
- Role translations need updating
- **File:** `config/locales/fr.yml`
- **Solution:** Add translations for new roles

### Code Search for Role Dependencies

```ruby
# Search for role checks:
grep -r "role == 'teacher'" app/
grep -r ".teacher?" app/
grep -r ".voluntary?" app/
grep -r ".tutor?" app/

# Update each occurrence to use new role system
```

---

## 10. Implementation Checklist

### Pre-Implementation
- [ ] Review and approve this plan
- [ ] Backup database
- [ ] Create feature branch: `feature/registration-api`
- [ ] Ensure all existing tests pass

### Phase 1: User Model Updates (Day 1)
- [ ] Update role enum in `user.rb`
- [ ] Add role group constants
- [ ] Add role class methods
- [ ] Update `requires_academic_email?` method
- [ ] Add non-academic email validation
- [ ] Add password complexity validation
- [ ] Add minimum age validation
- [ ] Update `teachers` scope
- [ ] Search and update role checks in codebase
- [ ] Run existing tests
- [ ] Fix any broken tests

### Phase 2: Registration Service (Day 2)
- [ ] Create `RegistrationService`
- [ ] Implement validation logic
- [ ] Implement personal user registration
- [ ] Implement personal user registration with children_info persistence ⭐
- [ ] Implement teacher registration
- [ ] Implement school registration
- [ ] Implement company registration
- [ ] Write unit tests for service

### Phase 3: Controllers & Routes (Day 3)
- [ ] Add `register` method to `AuthController`
- [ ] Create `SkillsController`
- [ ] Create `ParentChildInfo` model and migration ⭐
- [ ] Create `ParentChildrenController` (CRUD endpoints) ⭐
- [ ] Update `SchoolsController` (list_for_joining)
- [ ] Update `CompaniesController` (list_for_joining)
- [ ] Create `Auth::ConfirmationsController`
- [ ] Update routes (registration + parent_children) ⭐
- [ ] Write request specs

### Phase 4: Serializer & Email (Day 4)
- [ ] Update `UserSerializer` (available_contexts)
- [ ] Test email confirmation flow
- [ ] Test organization confirmation on email confirm
- [ ] Verify email templates work

### Phase 5: Testing (Day 5)
- [ ] Test personal user registration (curl)
- [ ] Test personal user registration with children_info (curl) ⭐
- [ ] Test parent children CRUD endpoints (GET, POST, PATCH, DELETE) ⭐
- [ ] Test teacher registration (curl)
- [ ] Test school registration (curl)
- [ ] Test company registration (curl)
- [ ] Test all validation errors
- [ ] Test email confirmation flow
- [ ] Test login after confirmation
- [ ] Test contexts after login
- [ ] Update Postman collection

### Phase 6: Documentation & Deployment
- [ ] Update `REACT_INTEGRATION_STRATEGY.md`
- [ ] Update Postman collection
- [ ] Write migration guide (for role changes)
- [ ] Commit and push
- [ ] Create pull request
- [ ] Deploy to staging
- [ ] Test on staging
- [ ] Deploy to production

---

## 11. Risk Mitigation

### Risk 1: Role Enum Breaking Changes
**Mitigation:**
- Thoroughly search codebase for role checks
- Update all occurrences before deploying
- Add deprecation warnings if keeping old code
- Test extensively

### Risk 2: Email Validation Too Strict
**Mitigation:**
- Ensure academic email list is complete
- Add clear error messages
- Provide support contact for edge cases

### Risk 3: Registration Transaction Failures
**Mitigation:**
- Wrap all creation logic in transaction
- Proper error handling and rollback
- Log failures for debugging
- Test edge cases

### Risk 4: Email Delivery Issues
**Mitigation:**
- Test email delivery in staging
- Monitor email sending logs
- Have retry mechanism for failed emails

---

## 12. Timeline


| Day | Tasks | Hours |
|-----|-------|-------|
| 1 | User model updates, role enum, validations | 8h |
| 2 | Registration service implementation | 8h |
| 3 | Controllers, routes, request specs | 8h |
| 4 | Serializers, email flow, confirmations | 8h |
| 5 | Manual testing, Postman, documentation | 8h |

**Total: 40 hours (1 sprint week)**

---

## 13. Success Criteria

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
✅ Children info persistence working (ParentChildInfo records created at registration) ⭐  
✅ Parent children CRUD endpoints working ⭐  
✅ All existing tests still passing  
✅ New tests written and passing  
✅ Postman collection updated  
✅ Documentation updated  

---

## 14. Next Steps After Registration

Once registration is complete, users can:
1. **Confirm email** → Account activated
2. **Login** → Receive JWT token + available contexts
3. **Access appropriate dashboard(s)**:
   - Personal user → User Dashboard
   - Teacher → Teacher Dashboard (+ School Dashboard if school admin/superadmin)
   - School admin → School Dashboard (after confirmation)
   - Company admin → Company Dashboard (after confirmation)
4. **Manage children info** (for parents):
   - View all children info in "My Children" page ⭐
   - Add, edit, or delete children info via `/api/v1/parent_children` endpoints ⭐
   - Wait for child accounts to be created (by teacher/school/self) ⭐
   - Claim/link child accounts when match is found ⭐
5. **Switch contexts** if multiple organizations
6. **Complete profile** in their dashboard
7. **Start using features** (projects, badges, etc.)

---

## Ready to Implement! 🚀

This plan covers:
- ✅ Complete role system redesign
- ✅ Unified registration endpoint
- ✅ All 4 registration types
- ✅ Comprehensive validation
- ✅ Email confirmation flow
- ✅ Context switching support
- ✅ Testing strategy
- ✅ Impact analysis



