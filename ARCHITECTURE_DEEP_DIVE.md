# Kinship Backend - Deep Architecture Analysis

## Executive Overview

**Kinship** is a sophisticated educational partnership platform built on Rails 7.1.3.4 that connects schools, companies, and volunteers to facilitate project-based learning. The application manages complex multi-tenant relationships with role-based access control, skill matching, and an achievement recognition system through badges.

**Primary Business Value:** Enable educational institutions to collaborate with industry partners on real-world projects while tracking student participation and skill development.

---

## 1. Core Domain Models & Relationships

### 1.1 User Model - The Central Entity

**Purpose:** Multi-role user system supporting teachers, tutors, volunteers, and children

**Key Attributes:**
```ruby
- email, encrypted_password (Devise authentication)
- first_name, last_name
- role: enum [:teacher, :tutor, :voluntary, :children]
- admin, super_admin (system permissions)
- birthday, job, company_name
- role_additional_information, skill_additional_information
- take_trainee, propose_workshop (service offerings)
- certify (verified status)
- is_banned (moderation)
- parent_id (self-referential for children accounts)
```

**Critical Relationships:**
```ruby
# Organizational Affiliations
has_many :user_schools → has_many :schools (many-to-many with status)
has_many :user_company → has_many :companies (many-to-many with status)

# Skills & Competencies
has_many :user_skills → has_many :skills
has_many :user_sub_skills → has_many :sub_skills
has_one :availability (weekly schedule)

# Project Participation
has_many :projects (as owner)
has_many :project_members (as participant)
has_many :team_members → has_many :teams

# Badge System
has_many :badges_sent (as sender)
has_many :badges_received (as receiver, only approved)

# Family Relationships
belongs_to :parent (self-referential)
has_many :childrens (self-referential)
```

**Business Logic:**
- **Academic Email Validation**: Teachers MUST use French academic emails (@ac-*.fr, @education.mc, @lfmadrid.org)
- **Auto-admin**: super_admin automatically sets admin flag
- **Availability Creation**: Automatically creates Availability record on user creation
- **Circular Reference Prevention**: Cannot be your own parent
- **Welcome Email**: Sent asynchronously after creation (production only)

**Key Methods:**
```ruby
can_create_project?     # Admin, teacher, or company member with contract
can_give_badges?        # Has badge access in school or company
schools_admin           # Schools where user is admin
companies_admin         # Companies where user is admin
projects_owner          # Projects owned or admin of
```

---

### 1.2 School Model - Educational Institutions

**Purpose:** Represents French educational institutions with type-specific validation

**Key Attributes:**
```ruby
- name, city, zip_code, referent_phone_number
- school_type: enum [:primaire, :college, :lycee, :erea, :medico_social, 
                     :service_administratif, :information_et_orientation, :autre]
- status: enum [:pending, :confirmed]
```

**Relationships:**
```ruby
has_many :school_levels (classes/grades)
has_many :user_schools → has_many :users
has_many :school_companies → has_many :companies (partnerships)
has_many :contracts (legal agreements)
```

**Business Logic:**
- **PgSearch Integration**: Full-text search on name, city, zip_code
- **Ownership**: One owner per school (enforced in UserSchool)
- **Admin Management**: Multiple admins allowed
- **Partnership Workflow**: Companies request partnership (pending → confirmed)
- **Contract Requirement**: Must have active contract for certain features

---

### 1.3 Company Model - Business Partners

**Purpose:** Companies, associations, and organizations partnering with schools

**Key Attributes:**
```ruby
- name, city, zip_code, referent_phone_number
- description, siret_number (14 digits), email, website, job
- status: enum [:pending, :confirmed]
- take_trainee, propose_workshop, propose_summer_job (service flags)
- belongs_to :company_type (Entreprise, Association, Collectivité)
```

**Relationships:**
```ruby
has_many :user_companies → has_many :users
has_many :project_companies → has_many :projects
has_many :company_skills → has_many :skills
has_many :company_sub_skills → has_many :sub_skills
has_many :school_companies → has_many :schools
has_many :contracts
has_many :company_partners (sponsorship network)
has_many :reverse_company_partners
```

**Business Logic:**
- **SIRET Validation**: French business ID (14 digits, unique)
- **PgSearch**: Full-text search capability
- **Ownership**: One owner per company
- **Contract System**: Active contracts enable project creation
- **Sponsorship Network**: Companies can sponsor other companies

**Key Methods:**
```ruby
active_contract?           # Has active contract
user_can_create_project?   # Check if user has project creation rights
admin_user?(user)          # Check if user is admin
```

---

### 1.4 Project Model - Collaborative Initiatives

**Purpose:** Educational projects bringing together students, teachers, and mentors

**Key Attributes:**
```ruby
- title, description
- start_date, end_date
- status: enum [:coming, :in_progress, :ended]
- participants_number, time_spent
- private (boolean - visibility control)
- owner_id (User who created it)
```

**Relationships:**
```ruby
belongs_to :owner (User)
has_many :project_school_levels → has_many :school_levels → has_many :schools
has_many :project_companies → has_many :companies
has_many :project_skills → has_many :skills
has_many :project_tags → has_many :tags
has_many :project_members (participants with status)
has_many :teams (sub-groups within project)
has_many :team_members (through teams)
has_many :keywords, :links (metadata)
has_many :user_badges (achievements)
has_one_attached :main_picture
has_many_attached :pictures, :documents
```

**Critical Validation:**
```ruby
school_levels_or_company_presence: 
  # Project MUST have either school_levels OR companies
  # Exception: Admin users can create projects without either
```

**Business Logic:**
- **Date Validation**: start_date must be before end_date
- **Participant Management**: Pending participants need owner approval
- **Edit Permissions**: Only owner or project admin can edit
- **Search**: Full-text search on title and description
- **Scopes**: Complex filtering by school, company, tags, user participation

**Key Methods:**
```ruby
can_edit?(user)              # Owner or project admin
pending_participants?        # Has unapproved participants
number_of_participants       # Count unique team members
schools                      # Unique schools via school_levels
```

---

### 1.5 Badge System - Achievement Recognition

**Purpose:** Multi-level skill recognition system with approval workflow

#### Badge Model
```ruby
- name, description
- level: enum [:level_1, :level_2, :level_3, :level_4]
- has_one_attached :icon
has_many :badge_skills (categorized competencies)
```

#### UserBadge Model - The Assignment
```ruby
- project_title, project_description (context)
- status: enum [:pending, :approved, :rejected]
- belongs_to :sender (User who assigns)
- belongs_to :receiver (User who receives)
- belongs_to :badge
- belongs_to :organization (polymorphic: School or Company)
- belongs_to :project (optional)
- has_many_attached :documents (required for level 2+)
```

**Badge Workflow:**
1. Sender (with badge access) creates UserBadge
2. Level 1: Auto-approved
3. Level 2-4: Requires document upload + manual approval
4. On approval: Email notification sent to receiver
5. Approved badges appear in user profile

#### BadgeSkill Model
```ruby
- name
- category: enum [:domain, :expertise]
- belongs_to :badge
```

**Business Logic:**
- **Document Validation**: Level 2+ badges require proof documents
- **Auto-approval**: Level 1 badges auto-approve on creation
- **Email Notification**: Async email on badge approval
- **Organization Scoping**: Badge must come from School or Company

---

### 1.6 Join Tables & Membership Models

#### UserSchool (School Membership)
```ruby
- status: enum [:pending, :confirmed]
- owner, admin, can_access_badges (permissions)

Business Rules:
- Teachers: Start as pending, need approval
- Non-teachers: Auto-confirmed
- One owner per school (enforced)
- Owner automatically becomes admin
- Admin automatically gets badge access
```

#### UserCompany (Company Membership)
```ruby
- status: enum [:pending, :confirmed]
- owner, admin, can_access_badges, can_create_project (permissions)

Business Rules:
- One owner per company (enforced)
- Owner → admin → badge access → project creation (cascading permissions)
```

#### ProjectMember (Project Participation)
```ruby
- status: enum [:pending, :confirmed]
- admin (project administrator)

Business Rules:
- Project owner automatically becomes admin
- Requires approval from project owner
- One user per project (uniqueness constraint)
```

#### SchoolCompany (School-Company Partnership)
```ruby
- status: enum [:pending, :confirmed]

Business Rules:
- Partnership must be confirmed by school admin
- Enables collaboration on projects
```

---

### 1.7 Contract Model - Legal Agreements

**Purpose:** Formal contracts between schools/companies enabling premium features

```ruby
belongs_to :school (optional - XOR with company)
belongs_to :company (optional - XOR with school)
- active (boolean)
- start_date, end_date

Business Rules:
- Contract is EITHER for school OR company (XOR validation)
- Only one active contract per school/company
- School/Company must be confirmed
- School/Company must have an owner
- End date must not be expired if active
- Active contract enables project creation for company members
```

---

### 1.8 SchoolLevel Model - Grade/Class System

**Purpose:** Represents specific classes within schools

```ruby
belongs_to :school
- name (e.g., "A", "B", "1", "2")
- level: enum [18 levels from petite_section to terminale, cap, bts]

Level Categories:
- PRIMARY_SCHOOL_LEVEL: [:petite_section → :cm2]
- SECONDARY_SCHOOL_LEVEL: [:sixieme → :troisieme]
- HIGH_SCHOOL_LEVEL: [:seconde → :terminale, :cap, :bts]

Business Rules:
- Level must match school type (primaire → PRIMARY_SCHOOL_LEVEL)
- Unique combination of (level, name) per school
- PgSearch on level, name, and school attributes
```

---

### 1.9 Skill System - Competency Taxonomy

#### Skill Model
```ruby
- name
- official (boolean - curated vs user-created)
has_many :users, :companies, :projects
has_many :sub_skills (hierarchical)
```

#### SubSkill Model
```ruby
belongs_to :skill
- name
has_many :users, :companies
```

**Usage Pattern:**
- Skills: Broad categories (e.g., "Informatique & Numérique")
- SubSkills: Specific competencies (e.g., "Développeur", "Design")
- Used for matching users to projects and filtering participants

---

### 1.10 Team System - Project Organization

#### Team Model
```ruby
belongs_to :project
- title, description
has_many :team_members → has_many :users
```

**Purpose:** Organize project participants into sub-groups (e.g., "Backend Team", "Design Team")

---

## 2. Data Flow Patterns

### 2.1 User Registration Flow

```
1. User Registration (registration_stepper namespace)
   ├─ Step 1: Role selection + RGPD acceptance
   ├─ Step 2: Basic profile (name, birthday, role_additional_information)
   ├─ Step 3: Skills selection
   ├─ Step 4: School/Company affiliation
   └─ Step 5: Availability + final confirmation

2. Email Confirmation (Devise confirmable)
   ├─ Confirmation email sent via Postmark
   └─ User must confirm before full access

3. Organization Approval (if needed)
   ├─ Teachers → UserSchool pending → School admin approves
   └─ Company members → UserCompany pending → Company admin approves
```

### 2.2 Project Creation Flow

```
1. Authorization Check
   ├─ User.can_create_project?
   │  ├─ Admin? → ✅
   │  ├─ Teacher? → ✅
   │  └─ Company member with active contract? → ✅

2. Project Creation
   ├─ Must have school_levels OR companies (unless admin)
   ├─ Nested attributes: tags, skills, links, keywords, teams
   ├─ File uploads: main_picture, pictures, documents
   └─ Owner automatically becomes project admin

3. Participant Recruitment
   ├─ Users request to join (ProjectMember pending)
   ├─ Owner/admin approves → confirmed
   └─ Daily job notifies owner of pending requests

4. Team Formation
   ├─ Project admin creates teams
   └─ Assigns confirmed project members to teams
```

### 2.3 Badge Assignment Flow

```
1. Authorization Check
   ├─ User.can_give_badges?
   │  ├─ UserSchool with can_access_badges? → ✅
   │  └─ UserCompany with can_access_badges? → ✅

2. Badge Assignment (assign_badge_stepper namespace)
   ├─ Step 1: Select receiver (participant)
   ├─ Step 2: Select badge level (1-4)
   ├─ Step 3: Select badge skills (domains + expertises)
   ├─ Step 4: Provide project context
   ├─ Step 5: Upload documents (required for level 2+)
   └─ Success: UserBadge created

3. Approval Workflow
   ├─ Level 1: Auto-approved
   ├─ Level 2-4: Pending → Manual approval
   └─ On approval: Email notification sent

4. Badge Display
   └─ Only approved badges shown in user profile
```

### 2.4 Partnership Flow

```
School-Company Partnership:
1. Company requests partnership → SchoolCompany (pending)
2. Daily job notifies school admins
3. School admin approves → confirmed
4. Enables collaboration on projects

Company-Company Sponsorship:
1. Sponsor company adds partner → CompanyCompany (pending)
2. Partner confirms → confirmed
3. Prevents reverse sponsorship (A→B blocks B→A)
```

### 2.5 Contract Management Flow

```
1. Contract Creation (Admin only via ActiveAdmin)
   ├─ School OR Company (XOR constraint)
   ├─ Must have owner
   ├─ Must be confirmed status
   └─ start_date, end_date, active flag

2. Active Contract Effects
   ├─ Company members can create projects
   ├─ Enhanced permissions
   └─ Only one active contract per organization

3. Contract Expiration
   ├─ Validation prevents activating expired contracts
   └─ Must be manually deactivated
```

---

## 3. Authorization Architecture (Pundit)

### 3.1 Authorization Layers

**ApplicationController:**
```ruby
after_action :verify_authorized (all actions except index)
after_action :verify_policy_scoped (index actions)
```

**Policy Structure:**
- Base: `ApplicationPolicy`
- Namespaced: `Api::`, `Participants::`, `SchoolAdminPanel::`, `CompanyAdminPanel::`, `ProjectAdminPanel::`
- Each model has corresponding policy

### 3.2 Key Policy Patterns

**ProjectPolicy:**
```ruby
Scope:
  - Public projects (private: false)
  - Private projects where user is in associated company
  - Private projects where user is in associated school

Actions:
  - create?: user.can_create_project?
  - update?: record.owner == user
  - show?: true (but scope limits visibility)
```

**User Permission Hierarchy:**
```
super_admin → admin → organization owner → organization admin → member
```

### 3.3 Admin Panel Access

**ActiveAdmin:**
- Mounted at `/admin`
- Separate policy namespace: `ActiveAdmin::`
- Super admins have full access
- Manages: users, companies, schools, badges, contracts, API access

---

## 4. Complex Business Rules

### 4.1 Participant Matching System

**For Teachers:**
```ruby
scope :participants_for_teacher
  - Same school as teacher
  - Has skills defined
  - Not admin, not voluntary
  - Not the teacher themselves
```

**For Tutors:**
```ruby
scope :participants_for_tutor
  - Same school AND same school_level
  - Has skills defined
  - Not admin, not voluntary, not teacher
  - OR teachers from same school
```

**Filtering Capabilities:**
- By skills, sub_skills
- By availability (day of week)
- By service offerings (take_trainee, propose_workshop)
- By school, school_level

### 4.2 Project Visibility Rules

**Public Projects:**
- Visible to all authenticated users

**Private Projects:**
- Visible to users in associated companies (confirmed status)
- Visible to users in associated schools (via school_levels)
- Always visible to owner and project admins

### 4.3 Permission Cascading

**School Membership:**
```
owner → admin → can_access_badges
```

**Company Membership:**
```
owner → admin → can_access_badges → can_create_project
```

**Project Membership:**
```
owner → admin (automatic for owner)
```

---

## 5. Background Jobs & Async Processing

### 5.1 Scheduled Jobs (Sidekiq-Cron)

**Daily Jobs (0 0 * * *):**
```ruby
1. SendEmailToOrganizationAdminJob
   - Notifies organization admins of pending actions

2. NotifySchoolsAdminsForNewPartnershipsJob
   - Alerts school admins of pending company partnerships
   - Sends to school owner admins or super admins

3. NotifyProjectOwnerForNewParticipationsRequestJob
   - Alerts project owners of pending participant requests

4. DestroyLoggingWhenTheyAreOneYearAndOneDayOldJob
   - Cleanup old logging records (GDPR compliance)
```

**Every 6 Hours (0 */6 * * *):**
```ruby
DestroyUserNotConfirmedAfter48HoursJob
   - Cleanup unconfirmed users after 48 hours
   - Prevents database bloat from abandoned registrations
```

### 5.2 Async Email Jobs

**Email Delivery (ActiveJob → Sidekiq):**
- Welcome emails
- Confirmation emails
- Badge approval notifications
- Project participation requests
- Partnership notifications
- Password reset

**Email Provider:** Postmark with templated emails

---

## 6. API Architecture

### 6.1 API V1 (Public/Semi-Public)

**Endpoints:**
- `GET /api/v1/companies` - List companies (optional admin param)
- `GET /api/v1/schools` - List schools (optional admin param)

**Authentication:** None (but admin param for elevated access)

**Authorization:** Pundit policy scopes

**Response Format:** Simple JSON arrays with `as_json`

**Use Case:** Autocomplete/search functionality for forms

### 6.2 API V2 (Token-Based)

**Endpoints:**
- `GET /api/v2/users` - List users (paginated)
- `GET /api/v2/users/:id` - User details (nested data)

**Authentication:** 
```ruby
ApiAccess model with token
  → has_many :companies (via company_api_accesses)
  → Scopes access to users in those companies
```

**Authorization:** Company-scoped access control

**Response Format:** 
- Pagination with Pagy
- Nested includes (skills, badges, projects)
- Complex `as_json` with includes

**Use Case:** External systems accessing user data (HR systems, reporting)

---

## 7. Data Integrity & Validation Patterns

### 7.1 Uniqueness Constraints

```ruby
User:
  - email (unique, required)
  - contact_email (unique, optional)

UserSchool, UserCompany, ProjectMember:
  - user_id unique per organization/project

School, Company:
  - One owner per organization (custom validation)

Contract:
  - One active contract per organization
```

### 7.2 Conditional Validations

```ruby
User:
  - academic_email? (only if teacher role)
  - privacy_policy_accepted? (always)
  - check_for_circular_reference (if parent_id present)

Project:
  - school_levels_or_company_presence (unless owner.admin?)
  - start_date_before_end_date (if both dates present)

Contract:
  - school_confirmed, company_confirmed (if respective ID present)
  - end_date_not_expired (if active)
  - school_has_owner, company_has_owner
```

### 7.3 Enum Validations

**Status Enums (Common Pattern):**
```ruby
pending: 0, confirmed: 1
```
Used in: School, Company, UserSchool, UserCompany, ProjectMember, SchoolCompany, CompanyCompany

**Role-Based Enums:**
```ruby
User.role: [:teacher, :tutor, :voluntary, :children]
Badge.level: [:level_1, :level_2, :level_3, :level_4]
Project.status: [:coming, :in_progress, :ended]
BadgeSkill.category: [:domain, :expertise]
```

---

## 8. Search & Filtering

### 8.1 PgSearch Integration

**Full-Text Search Models:**
```ruby
Company: by_full_name (name, city, zip_code)
School: by_full_name (name, city, zip_code)
SchoolLevel: by_full_name (name, level, + associated school fields)
```

**Search Strategy:** PostgreSQL tsearch with prefix matching

### 8.2 Complex Scopes

**User Scopes:**
- 14+ scopes for participant filtering
- By role, school, school_level, skills, availability
- Special scopes: participants_for_teacher, participants_for_tutor

**Project Scopes:**
- my_projects, my_administration_projects
- by_school, by_school_level, by_companies, by_tags
- search (full-text on title/description)

---

## 9. File Storage Architecture

### 9.1 ActiveStorage + Cloudinary

**User:**
- `has_one_attached :avatar`

**Project:**
- `has_one_attached :main_picture`
- `has_many_attached :pictures`
- `has_many_attached :documents`

**Badge:**
- `has_one_attached :icon`

**UserBadge:**
- `has_many_attached :documents` (required for level 2+)

**Storage:** Cloudinary for production, local for development

---

## 10. Multi-Tenant Patterns

### 10.1 Organization Isolation

**School Tenancy:**
- Users belong to schools via UserSchool
- Projects scoped to school_levels
- Admins see only their school's data

**Company Tenancy:**
- Users belong to companies via UserCompany
- Projects can be company-specific
- API V2 scoped to company's users

**Cross-Tenant Collaboration:**
- Projects can span multiple schools (via school_levels)
- Projects can involve companies
- Partnerships enable school-company collaboration

### 10.2 Permission Scoping

**Data Access Patterns:**
```ruby
# School Admin sees:
- All users in their school
- All projects for their school's levels
- Partnership requests

# Company Admin sees:
- All users in their company
- Company's projects
- Partnership requests

# Project Owner sees:
- All project participants
- Pending participation requests
- Team composition
```

---

## 11. Key Technical Patterns

### 11.1 Nested Attributes Pattern

**Extensive use of `accepts_nested_attributes_for`:**
- User: skills, sub_skills, availability, schools, school_levels, companies
- Project: tags, skills, school_levels, companies, teams, links, keywords
- Company: skills, sub_skills, school_companies, company_partners

**Benefit:** Single-form submission for complex object graphs

### 11.2 Polymorphic Associations

**UserBadge → Organization:**
```ruby
belongs_to :organization, polymorphic: true
organization_type: "School" or "Company"
organization_id: respective ID
```

**Use Case:** Badges can be issued by either schools or companies

### 11.3 Self-Referential Associations

**User → Parent:**
```ruby
belongs_to :parent, class_name: "User", optional: true
has_many :childrens, class_name: "User", foreign_key: :parent_id
```

**Use Case:** Parent accounts managing children's profiles

**CompanyCompany → Sponsorship:**
```ruby
belongs_to :company_sponsor, class_name: "Company"
belongs_to :company
```

**Use Case:** Company sponsorship network

### 11.4 Callback Chains

**UserSchool:**
```ruby
after_create :set_status (auto-confirm non-teachers)
after_validation :set_admin_if_owner
after_validation :set_access_badges_if_admin
```

**UserCompany:**
```ruby
after_validation :set_admin_if_owner
after_validation :set_create_project_if_admin
after_validation :set_access_badges_if_admin
```

**Pattern:** Cascading permissions through callbacks

---

## 12. Security & Compliance

### 12.1 Authentication

**Devise Modules:**
- `:database_authenticatable` - Email/password
- `:registerable` - User signup
- `:recoverable` - Password reset
- `:rememberable` - Remember me
- `:validatable` - Email/password validation
- `:confirmable` - Email confirmation required

**Session Management:**
- Cookie-based sessions for web
- Token-based for API V2

### 12.2 Authorization

**Pundit:**
- Policy-based authorization
- Scope-based data filtering
- Automatic verification via after_actions

**Admin Levels:**
- `super_admin`: Full system access
- `admin`: Enhanced permissions
- Organization owner: Full org access
- Organization admin: Org management
- Member: Basic access

### 12.3 Data Privacy (GDPR)

**Logging:**
```ruby
- IP address, request path, user agent
- User ID and email tracked
- Auto-deletion after 1 year + 1 day
```

**User Deletion:**
```ruby
- Delete token system (secure random)
- Token expires after time period
- Cascading deletions via dependent: :destroy
```

**Privacy Policy:**
- Required acceptance during registration
- Stored as boolean flag

---

## 13. Internationalization (I18n)

**Default Locale:** French (`:fr`)

**Localized Content:**
- User role names
- School level names
- Error messages
- Email templates (via Postmark)
- UI labels

**Translation Files:** `config/locales/` (31 YAML files)

---

## 14. Performance Optimizations

### 14.1 Eager Loading

**Common Patterns:**
```ruby
Project.default_project(current_user)
  .includes(:team_members, :project_members, :project_school_levels, 
            :schools, :school_levels, :main_picture_attachment)

User.participants_for_teacher
  .includes(:school_levels, :schools, :availability)
```

### 14.2 Pagination

**Pagy Gem:**
- Used in ProjectsController
- Used in API V2 UsersController
- 20 items per page default

### 14.3 Database Indexing

**Key Indexes (from schema):**
- Foreign keys (all associations)
- Unique constraints (email, tokens)
- Composite indexes (user_id + organization_id)
- Polymorphic indexes (organization_type + organization_id)

---

## 15. External Integrations

### 15.1 Email Service

**Postmark:**
- Templated emails (PostmarkRails::TemplatedMailer)
- Templates managed in Postmark dashboard
- Async delivery via Sidekiq

### 15.2 File Storage

**Cloudinary:**
- Image transformations
- CDN delivery
- Configured via environment variables

### 15.3 School Data

**French Education Database:**
- CSV import from data.education.gouv.fr
- ~70k schools available
- Seed process with user confirmation

---

## 16. Testing Strategy

### 16.1 Test Stack

```ruby
- RSpec (behavior-driven testing)
- FactoryBot (test data generation)
- Faker (realistic fake data)
- DatabaseCleaner (test isolation)
- Capybara + Selenium (system tests)
- Shoulda Matchers (model testing)
- rswag (API documentation + testing)
```

### 16.2 Test Coverage

**Existing Tests:**
- Component specs (25 files)
- Model specs (36 files)
- Request specs (15 files)
- System specs (16 files)
- Job specs (5 files)
- Mailer specs (11 files)

### 16.3 Factory Coverage

**37 Factories** covering all models with traits:
- Status traits: `:pending`, `:confirmed`
- Role traits: `:teacher`, `:tutor`, `:voluntary`
- Level traits: `:level_1` through `:level_4`

---

## 17. Admin Interface (ActiveAdmin)

### 17.1 Managed Resources

**Core Entities:**
- Users, Companies, Schools
- Projects, Teams
- Badges, UserBadges
- Contracts, API Access
- Skills, SubSkills, Tags

**Admin Features:**
- CRUD operations
- Batch actions
- CSV export
- Custom filters
- Dashboard with metrics

### 17.2 Admin Customizations

**Gems:**
- `activeadmin` (3.2.5) - Core admin framework
- `activeadmin_addons` - Enhanced UI components
- `active_admin_datetimepicker` - Date/time pickers
- `active_admin_theme` - Custom styling

---

## 18. Data Model Relationships - Complete Map

```
User (Central Hub)
├─ parent (User) - self-referential
├─ childrens (Users) - self-referential
├─ projects (as owner)
├─ project_members → projects (as participant)
├─ team_members → teams → projects
├─ user_schools → schools
│  └─ school_levels
├─ user_company → companies
│  ├─ contracts
│  └─ company_type
├─ user_skills → skills → sub_skills
├─ user_sub_skills → sub_skills
├─ badges_sent (UserBadges)
├─ badges_received (UserBadges)
└─ availability

Project
├─ owner (User)
├─ project_school_levels → school_levels → schools
├─ project_companies → companies
├─ project_skills → skills
├─ project_tags → tags
├─ project_members → users
├─ teams → team_members → users
├─ keywords
├─ links
└─ user_badges

School
├─ school_levels
├─ user_schools → users
├─ school_companies → companies
└─ contracts

Company
├─ company_type
├─ user_companies → users
├─ project_companies → projects
├─ company_skills → skills
├─ company_sub_skills → sub_skills
├─ school_companies → schools
├─ contracts
├─ company_partners (sponsorship)
└─ reverse_company_partners

Badge
├─ badge_skills
│  └─ user_badge_skills → user_badges
└─ user_badges
   ├─ sender (User)
   ├─ receiver (User)
   ├─ organization (polymorphic: School/Company)
   └─ project (optional)
```

---

## 19. Critical Business Constraints

### 19.1 Ownership Rules

1. **One Owner Per Organization**
   - Schools: Enforced in UserSchool
   - Companies: Enforced in UserCompany
   - Projects: Single owner_id

2. **Owner Privileges**
   - Automatically becomes admin
   - Cannot be removed
   - Required for contracts

### 19.2 Contract Rules

1. **XOR Constraint**: School OR Company, never both
2. **Single Active Contract**: One per organization
3. **Prerequisites**: Confirmed status + owner exists
4. **Expiration**: Cannot activate expired contracts

### 19.3 Badge Rules

1. **Level 1**: Auto-approved, no documents
2. **Level 2-4**: Manual approval + documents required
3. **Organization Scoping**: Must come from School or Company
4. **Sender Authorization**: Must have `can_access_badges` permission

### 19.4 Project Rules

1. **Target Audience**: Must have school_levels OR companies (unless admin)
2. **Ownership**: Owner cannot be changed
3. **Privacy**: Private projects only visible to affiliated users
4. **Participation**: Requires owner approval

---

## 20. Key Architectural Decisions

### 20.1 Why Join Tables Have Status?

**Pattern:** UserSchool, UserCompany, ProjectMember, SchoolCompany all have `status: [:pending, :confirmed]`

**Rationale:**
- **Approval Workflow**: Organizations control their membership
- **Security**: Prevents unauthorized access
- **Audit Trail**: Track membership lifecycle
- **Flexibility**: Can reject or remove members

### 20.2 Why Polymorphic Organization?

**UserBadge → Organization (School or Company)**

**Rationale:**
- Badges can be issued by either schools or companies
- Maintains single badge table
- Flexible for future organization types
- Simplifies badge issuance logic

### 20.3 Why Self-Referential User?

**User → Parent → Children**

**Rationale:**
- Parents manage children's accounts
- Children under 18 need parental consent
- Single user table simplifies authentication
- Enables family-based features

### 20.4 Why Separate SchoolLevel?

**School → SchoolLevel → Users/Projects**

**Rationale:**
- Granular targeting (specific classes, not whole school)
- Accurate participant matching
- Flexible class organization
- Supports French education system structure

---

## 21. Potential Technical Debt & Observations

### 21.1 Naming Inconsistencies

```ruby
# Inconsistent pluralization
has_many :user_company  # Should be :user_companies
has_many :childrens     # Should be :children
```

### 21.2 N+1 Query Risks

**High-Risk Areas:**
- Project index with multiple counts
- Participant filtering with complex joins
- Badge display with nested includes

**Mitigation:** Bullet gem enabled in development

### 21.3 Callback Complexity

**UserSchool, UserCompany:**
- Multiple after_validation callbacks
- Cascading updates
- Potential for callback loops (mitigated by conditional checks)

### 21.4 Scope Complexity

**User.by_school_level:**
- Includes N+1 query (SchoolLevel.find in lambda)
- Complex OR logic
- Performance concern for large datasets

---

## 22. Security Considerations

### 22.1 Authentication Layers

1. **Web App**: Devise session-based
2. **API V1**: Public with optional admin param (⚠️ potential security risk)
3. **API V2**: Token-based with company scoping

### 22.2 Authorization Enforcement

**Pundit Verification:**
```ruby
after_action :verify_authorized (enforced)
after_action :verify_policy_scoped (enforced)
```

**Bypass Rules:**
- Devise controllers
- Admin controllers
- Pages controller

### 22.3 Banned User Handling

**ApplicationController:**
```ruby
before_action :redirect_for_banned_users
rescue_from SecurityError (redirects to banned_information)
```

**Flow:** Banned users immediately redirected, cannot access any features

---

## 23. Frontend Architecture

### 23.1 Technology Stack

**View Layer:**
- ERB templates
- ViewComponent (3.8) - Component-based UI
- Turbo Rails (1.5) - SPA-like navigation
- Stimulus (1.3) - JavaScript controllers
- Lookbook (2.3) - Component preview (dev only)

**Asset Pipeline:**
- Importmap Rails (no webpack)
- Sprockets for CSS
- SCSS with 87 stylesheets
- Font Awesome icons

### 23.2 Component Architecture

**ViewComponents (39 components):**
- Admin panel components
- Badge components
- Company/School cards
- Participant cards
- Project cards
- UI components (buttons, modals, steppers)

**Pattern:** Reusable, testable view components

### 23.3 Stimulus Controllers (31 controllers)

**Key Controllers:**
- `schools_form_controller` - Dynamic school selection
- `school_searcher_controller` - Autocomplete
- `companies_select_search_controller` - Company search
- `file_uploader_controller` - File uploads
- `lottie_controller` - Animations

---

## 24. Deployment & Infrastructure

### 24.1 Environment Configuration

**Environments:**
- Development (local)
- Test (RSpec)
- Staging (pre-production)
- Production (CleverCloud)

**CleverCloud Configuration:**
- `clevercloud/ruby.json` - Deployment config
- Environment variables via `.env` files (dotenv-rails)

### 24.2 Background Processing

**Sidekiq:**
- Redis-backed job queue
- Sidekiq-Cron for scheduled jobs
- Web UI at `/sidekiq` (admin only)
- Queue: `:jobs` for all background jobs

### 24.3 Monitoring & Logging

**Lograge:**
- Structured logging
- Custom log format
- Production-only logging to database

**Logging Model:**
- Tracks: IP, path, params, status, user_agent, user
- Auto-cleanup after 1 year

**Rack Mini Profiler:**
- Development performance monitoring

---

## 25. Data Flow Examples

### Example 1: Teacher Creates Project

```
1. Teacher logs in (Devise authentication)
2. Navigates to /projects/new
3. ProjectPolicy#create? checks user.can_create_project?
   → Teacher role: ✅ allowed
4. Form submission with nested attributes:
   - project[title], project[description]
   - project[school_level_ids][] (multiple)
   - project[skill_ids][] (multiple)
   - project[links_attributes][]
   - project[main_picture] (file upload)
5. ProjectsController#create
   - Validates school_levels presence
   - Creates Project with owner = current_user
   - Creates associated records via nested attributes
   - Uploads files to Cloudinary
6. Redirect to project show page
7. (Disabled) Send notification emails to potential participants
```

### Example 2: Company Member Assigns Badge

```
1. Company admin logs in
2. User.can_give_badges? checks UserCompany.can_access_badges
   → Company admin: ✅ allowed
3. Navigate to /assign_badge_stepper/first_step/new
4. Step 1: Select receiver (participant from company)
5. Step 2: Select badge (level 1-4)
6. Step 3: Select badge_skills (domains + expertises)
7. Step 4: Provide project context
8. Step 5: Upload documents (if level 2+)
9. UserBadge created:
   - sender: current_user
   - receiver: selected user
   - organization: current company
   - status: level_1 ? :approved : :pending
10. If level 1: Auto-approved, email sent immediately
11. If level 2+: Awaits admin approval
```

### Example 3: School-Company Partnership

```
1. Company requests partnership with school
   → SchoolCompany created (status: :pending)
2. Daily job (NotifySchoolsAdminsForNewPartnershipsJob) runs at midnight
3. Job finds schools with pending partnerships
4. Sends email to school owner/admins
5. School admin logs in → school_admin_panel/partnerships
6. Reviews company details
7. Approves → SchoolCompany.update(status: :confirmed)
8. Now both can collaborate on projects
```

---

## 26. Critical Code Patterns to Remember

### 26.1 Status Confirmation Pattern

**Everywhere:**
```ruby
.where(status: :confirmed)
.confirmed  # scope
```

**Why:** Pending records exist but shouldn't be visible/active until approved

### 26.2 Policy Scope Pattern

**Controllers:**
```ruby
policy_scope(Model)  # Automatically filters based on user permissions
```

**Example:**
```ruby
# ProjectsController#index
policy_scope(Project.default_project(current_user))
# Returns only projects user is allowed to see
```

### 26.3 Nested Attributes Pattern

**Forms:**
```ruby
# Single form creates multiple related records
project[links_attributes][][name]
project[links_attributes][][url]
project[teams_attributes][][title]
```

**Models:**
```ruby
accepts_nested_attributes_for :links, allow_destroy: true
```

### 26.4 Polymorphic Query Pattern

**UserBadge:**
```ruby
organization_type: "School"
organization_id: 123

# Query:
UserBadge.where(organization: school)
UserBadge.where(organization: company)
```

---

## 27. Database Schema Insights

### 27.1 Table Count: 29 Tables

**Core Entities (8):**
- users, schools, companies, projects, badges, skills, tags, contracts

**Join Tables (14):**
- user_schools, user_companies, user_skills, user_sub_skills
- user_school_levels, user_badge_skills
- project_members, project_companies, project_school_levels
- project_skills, project_tags
- school_companies, company_companies, company_skills, company_sub_skills

**Supporting Tables (7):**
- availabilities, school_levels, teams, team_members
- user_badges, badge_skills, keywords, links
- company_types, api_accesses, company_api_accesses, loggings

### 27.2 Polymorphic Tables

**user_badges:**
```sql
organization_type VARCHAR
organization_id BIGINT
INDEX (organization_type, organization_id)
```

### 27.3 Self-Referential Tables

**users:**
```sql
parent_id BIGINT REFERENCES users(id)
```

**company_companies:**
```sql
company_sponsor_id BIGINT REFERENCES companies(id)
company_id BIGINT REFERENCES companies(id)
```

---

## 28. API Design Patterns

### 28.1 V1 vs V2 Philosophy

**V1 (Public):**
- Simple list endpoints
- No authentication required
- Used for form autocomplete
- Limited data exposure
- Policy scopes for data filtering

**V2 (Private):**
- Token-based authentication
- Company-scoped access
- Rich nested data
- Pagination support
- External system integration

### 28.2 Response Patterns

**V1 Simple:**
```ruby
render json: @companies.map { |c| {id: c.id, full_name: c.full_name} }
```

**V2 Complex:**
```ruby
render json: {
  data: @users.as_json(only: [...], include: {...}),
  meta: @pagination.as_json(only: [...])
}
```

---

## 29. Workflow State Machines

### 29.1 User Lifecycle

```
Created → Unconfirmed → Confirmed → Active
                ↓
         (48h timeout) → Deleted
```

### 29.2 Organization Membership

```
Request → Pending → Confirmed
            ↓
        Rejected (implicit - just delete)
```

### 29.3 Project Participation

```
Request → Pending → Confirmed → Active Participant
            ↓
        Rejected (delete ProjectMember)
```

### 29.4 Badge Lifecycle

```
Created → Pending → Approved → Visible in Profile
            ↓
        Rejected → Hidden
```

---

## 30. Performance & Scalability Considerations

### 30.1 Current Bottlenecks

**Identified:**
1. **Project Index**: Multiple count queries
2. **Participant Filtering**: Complex joins with scopes
3. **Badge Display**: Deep nested includes
4. **School Import**: 70k records in seeds

**Mitigations:**
- Pagy for pagination
- Eager loading with includes
- Limit results (20 per page)
- Database indexes on foreign keys

### 30.2 Caching Strategy

**Redis:**
- Session storage
- Sidekiq job queue
- (Potential) Fragment caching for project lists

### 30.3 Database Optimization

**Indexes Present:**
- All foreign keys indexed
- Unique constraints on critical fields
- Composite indexes for join tables
- Polymorphic indexes

---

## Summary - Ready to Answer Questions

I now have a **complete understanding** of:

✅ **Data Model**: 29 tables, complex many-to-many relationships, polymorphic associations  
✅ **Business Logic**: Multi-role users, approval workflows, permission cascading  
✅ **Authorization**: Pundit policies, organization-scoped access, admin hierarchies  
✅ **Data Flows**: Registration, project creation, badge assignment, partnerships  
✅ **API Architecture**: V1 (public) vs V2 (token-based), company-scoped access  
✅ **Background Jobs**: 5 scheduled jobs for notifications and cleanup  
✅ **Validation Rules**: Complex conditional validations, enum constraints  
✅ **Integration Points**: Postmark, Cloudinary, French education database  
✅ **Performance Patterns**: Eager loading, pagination, scopes  
✅ **Security**: Devise + Pundit, multi-level admin, banned user handling  

**I'm ready to answer any questions about the backend architecture, data flows, business logic, or implementation details!** 🚀

