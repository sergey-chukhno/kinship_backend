# React Frontend Integration Strategy
## Transforming Kinship Backend to API-First Architecture

---

## Table of Contents
1. [Strategy Overview](#strategy-overview)
2. [Executive Summary](#executive-summary)
3. [Strategic Architecture Decision](#strategic-architecture-decision)
4. [Target React Dashboards](#target-react-dashboards)
5. [Backend Transformation Strategy](#backend-transformation-strategy)
6. [Implementation Roadmap](#implementation-roadmap)
7. [Technical Implementation Details](#technical-implementation-details)
8. [React Frontend Architecture](#react-frontend-architecture)
9. [Migration Strategy](#migration-strategy)
10. [Security Considerations](#security-considerations)
11. [Testing Strategy](#testing-strategy)
12. [Deployment Strategy](#deployment-strategy)
13. [Monitoring & Observability](#monitoring--observability)
14. [Documentation](#documentation)
15. [Final Recommendations](#final-recommendations)

---

## Strategy Overview

### 🎯 Mission
Transform the Kinship Rails monolith into a modern API-first backend that serves **4 separate React dashboards** while maintaining zero downtime and full backward compatibility.

### 📊 Current State
- **Rails 7.1.3.4** monolith with ERB views, Turbo, and Stimulus
- **4 API endpoints** (2 in V1, 2 in V2)
- **Session-based authentication** (Devise)
- **29 database tables** with complex relationships
- **Pundit authorization** with comprehensive policies
- **Active user base** using the web application

### 🎯 Target State
- **API-first architecture** with comprehensive REST endpoints
- **JWT authentication** for stateless access
- **4 React dashboards** (Company, School, User, Teacher)
- **Hybrid deployment** (Rails API + React SPAs)
- **Backward compatible** during transition
- **Auto-generated documentation** (OpenAPI/Swagger)

### 🏗️ Architecture Transformation

```
BEFORE:                          AFTER:
┌─────────────────┐             ┌─────────────────┐
│   Rails Views   │             │   React Apps    │
│   (ERB/Turbo)   │             │  (4 Dashboards) │
└────────┬────────┘             └────────┬────────┘
         │                               │
         │                               │ JWT/REST
         │                               │
┌────────▼────────┐             ┌────────▼────────┐
│  Controllers    │             │   API Layer     │
│  (HTML/Turbo)   │             │  (JSON/REST)    │
└────────┬────────┘             └────────┬────────┘
         │                               │
         │                               │
┌────────▼────────┐             ┌────────▼────────┐
│  Models/Logic   │             │  Models/Logic   │
│   (Unchanged)   │             │   (Unchanged)   │
└────────┬────────┘             └────────┬────────┘
         │                               │
┌────────▼────────┐             ┌────────▼────────┐
│   PostgreSQL    │             │   PostgreSQL    │
└─────────────────┘             └─────────────────┘
```

### 📦 Deliverables

**Backend (Rails API):**
- ✅ JWT authentication system
- ✅ ~50+ RESTful API endpoints
- ✅ Serialization layer (JSON responses)
- ✅ CORS configuration
- ✅ Enhanced Pundit policies
- ✅ Comprehensive rswag specs
- ✅ OpenAPI 3.0 documentation
- ✅ Postman collections

**Frontend (React):**
- ✅ 4 separate dashboard applications
- ✅ TypeScript types (auto-generated)
- ✅ React Query integration
- ✅ Authentication flow
- ✅ Responsive UI
- ✅ File upload handling

### 🔄 Migration Approach

**Phase 1: Build (Weeks 1-8)**
- Develop API layer
- Keep existing views
- No user impact

**Phase 2: Test (Weeks 9-10)**
- Beta testing with select users
- Performance optimization
- Bug fixes

**Phase 3: Migrate (Weeks 11-12)**
- Gradual rollout: 10% → 25% → 50% → 75% → 100%
- Feature flags control access
- Monitor metrics
- Full migration

**Phase 4: Cleanup (Week 13+)**
- Remove old Rails views
- Optimize API
- Documentation updates

### 📈 Success Metrics

**Technical:**
- ✅ < 200ms average API response time
- ✅ 99.9% API uptime
- ✅ 100% endpoint test coverage
- ✅ Zero security vulnerabilities

**Business:**
- ✅ > 80% user adoption in 4 weeks
- ✅ > 4/5 user satisfaction
- ✅ Decreased support tickets
- ✅ Increased feature usage

### 🛠️ Technology Stack

**Backend Additions:**
```ruby
gem 'jwt'                        # Authentication
gem 'rack-cors'                  # CORS support
gem 'active_model_serializers'  # JSON serialization
gem 'rack-attack'                # Rate limiting (optional)
```

**Frontend Stack:**
```javascript
React 18+                        // UI framework
TypeScript                       // Type safety
React Router v6                  // Routing
React Query                      // API state
Axios                           // HTTP client
Material-UI / Ant Design        // Component library
```

### 🎯 Implementation Priority

**Priority 1: Authentication** (Week 1)
- Most critical
- Blocks all other work
- Affects all dashboards

**Priority 2: User Dashboard** (Week 2-3)
- Simplest dashboard
- Affects all users
- Proves the concept

**Priority 3: Teacher Dashboard** (Week 4-5)
- Core user base
- High business value
- Complex features

**Priority 4: School Dashboard** (Week 6-7)
- Admin features
- Less frequent use
- Similar to company

**Priority 5: Company Dashboard** (Week 8-9)
- Smallest user base
- Similar patterns to school
- Last to migrate

### 🔒 Security Enhancements

**API Security:**
- JWT with 24-hour expiration
- Token refresh mechanism
- Rate limiting (300 requests/5min per IP)
- HTTPS enforcement
- CORS whitelist
- Input validation
- SQL injection prevention (ActiveRecord handles)

**Authorization:**
- Pundit policies on every endpoint
- Organization-scoped data access
- Role-based permissions
- Admin privilege checks

### 📊 Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Breaking existing features | LOW | HIGH | Parallel development, feature flags |
| Performance issues | MEDIUM | MEDIUM | Load testing, caching, pagination |
| Authentication bugs | MEDIUM | HIGH | Comprehensive testing, gradual rollout |
| User resistance | MEDIUM | MEDIUM | Training, gradual migration, support |
| Timeline overrun | MEDIUM | MEDIUM | Agile sprints, MVP approach |

### 🎓 Key Learnings from Current Architecture

**Strengths to Leverage:**
- ✅ Well-designed database schema
- ✅ Comprehensive Pundit policies
- ✅ Rich model business logic
- ✅ Extensive FactoryBot coverage
- ✅ Existing API patterns (V2)

**Challenges to Address:**
- ⚠️ Complex nested attributes
- ⚠️ Multi-tenant authorization
- ⚠️ File upload handling
- ⚠️ Real-time notifications
- ⚠️ N+1 query prevention

### 📝 Documentation Deliverables

**For Backend Team:**
- ✅ This strategy document
- ✅ Architecture deep dive (ARCHITECTURE_DEEP_DIVE.md)
- ✅ API documentation (swagger.yaml)
- ✅ Postman collections
- ✅ rswag specs (living documentation)

**For Frontend Team:**
- ✅ OpenAPI specification
- ✅ TypeScript types (auto-generated)
- ✅ Authentication guide
- ✅ API endpoint reference
- ✅ Example React components
- ✅ Error handling patterns

### 🔄 Multi-Context User Experience

**Critical Feature:** Users can have multiple roles/contexts simultaneously and switch between them without re-authentication.

**Example User:**
```
Marie Dupont (marie@ac-nantes.fr)
├─ Personal Context → User Dashboard
│  └─ My profile, my projects, my badges
│
├─ Teacher Context → Teacher Dashboard  
│  └─ My classes, my students, create projects
│
├─ Admin of "Lycée Victor Hugo" → School Dashboard
│  └─ Manage school, approve teachers, partnerships
│
└─ Admin of "Tech Education Company" → Company Dashboard
   └─ Manage company, members, projects, partnerships
```

**Context Switching:**
- ✅ Single JWT token for all contexts
- ✅ Switch dashboards without re-login
- ✅ Context persisted in localStorage
- ✅ Default to User Dashboard (or first available if organization-only account)

**Special Case - Organization-Only Accounts:**
```
Some users register ONLY as organization admins (no personal profile)
→ available_contexts.user_dashboard: false
→ Default to first organization context
→ Context switcher shows only organization options
```

**Frontend Implementation:**
- **Single unified React app** with context-based routing
- Context stored in React Context + localStorage
- Context switcher in header/sidebar
- Routes: `/dashboard/user`, `/dashboard/company/:id`, `/dashboard/school/:id`, `/dashboard/teacher`

**Backend Support:**
- Login response includes `available_contexts`
- Each endpoint validates user has access to that context
- Existing authorization already supports this pattern

### 🚀 Getting Started

**Immediate Actions:**
1. Review this strategy document
2. Approve the hybrid approach
3. Confirm dashboard priorities
4. Set up development environment
5. Begin Sprint 1: JWT Authentication

**First Week Goals:**
- ✅ JWT authentication working
- ✅ Login/logout endpoints tested
- ✅ CORS configured
- ✅ Base API structure created
- ✅ First serializers implemented
- ✅ Context switching logic implemented

---

## Executive Summary

**Goal:** Transform the current Rails monolith into an API-first backend serving 4 separate React dashboards while maintaining the existing web application during transition.

**Approach:** Incremental API expansion with parallel frontend development

**Timeline Estimate:** 8-12 weeks for complete migration

---

## 1. Strategic Architecture Decision

### Option A: Hybrid Approach (RECOMMENDED)
**Keep Rails views + Add API layer**

✅ **Pros:**
- Zero downtime migration
- Gradual transition
- Existing features continue working
- Test React dashboards in parallel
- Rollback capability

❌ **Cons:**
- Temporary code duplication
- Maintain two codebases briefly

### Option B: Full API Replacement
**Replace all views with API**

✅ **Pros:**
- Clean separation
- Modern architecture
- Better for mobile apps later

❌ **Cons:**
- High risk, big bang deployment
- Longer development time
- No fallback

**RECOMMENDATION: Option A - Hybrid Approach**

---

## 2. Target React Dashboards

### Dashboard 1: Organization Dashboard (Companies)
**Users:** Company admins, company members  
**Features:**
- Company profile management
- Member management (invite, approve, remove)
- Partnership management (with schools)
- Project creation and management
- Badge assignment
- Skills management

**Routes:** `/company-dashboard/*`

### Dashboard 2: Educational Establishment Dashboard (Schools)
**Users:** School admins, teachers  
**Features:**
- School profile management
- Teacher/staff management
- Class/level management
- Partnership management (with companies)
- Student oversight
- Badge assignment
- Project oversight

**Routes:** `/school-dashboard/*`

### Dashboard 3: Individual User Space
**Users:** All users (teachers, tutors, volunteers)  
**Features:**
- Personal profile
- Skills and availability
- My projects (participating in)
- My badges received
- Network connections
- Participant search
- Project discovery

**Routes:** `/user-dashboard/*`

### Dashboard 4: Teacher Dashboard
**Users:** Teachers specifically  
**Features:**
- Class management
- Student participant matching
- Project creation wizard
- Badge assignment to students
- School-level project oversight
- Collaboration tools

**Routes:** `/teacher-dashboard/*`

---

## 3. Backend Transformation Strategy

### Phase 1: API Foundation (Weeks 1-2)

#### Step 1.1: Restructure API Namespace
**Current:** Only 4 endpoints in `api/v1` and `api/v2`  
**Target:** Comprehensive REST API

```ruby
# Proposed API structure
namespace :api do
  namespace :v1 do
    # Authentication
    post 'auth/login'
    post 'auth/logout'
    post 'auth/refresh'
    post 'auth/register'
    post 'auth/confirm'
    
    # User resources
    resources :users do
      get :me, on: :collection
      resources :skills
      resources :badges
      resource :availability
      resources :projects, only: [:index]
    end
    
    # Organization resources
    resources :companies do
      resources :members
      resources :partnerships
      resources :projects
      resource :profile
    end
    
    resources :schools do
      resources :members
      resources :levels
      resources :partnerships
      resources :projects
    end
    
    # Project resources
    resources :projects do
      resources :members
      resources :teams
      resources :badges
    end
    
    # Badge resources
    resources :badges, only: [:index, :show]
    
    # Skill resources
    resources :skills, only: [:index]
    resources :tags, only: [:index]
  end
end
```

#### Step 1.2: Create Base API Controllers

**File:** `app/controllers/api/v1/base_controller.rb`

```ruby
class Api::V1::BaseController < ActionController::API
  include ActionController::Cookies
  
  before_action :authenticate_api_user!
  
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from Pundit::NotAuthorizedError, with: :forbidden
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  
  private
  
  def authenticate_api_user!
    # JWT or session-based authentication
    @current_user = authenticate_user_from_token || authenticate_user_from_session
    
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end
  
  def authenticate_user_from_token
    # JWT implementation
    token = request.headers['Authorization']&.split(' ')&.last
    return nil unless token
    
    # Decode JWT and find user
    # Implementation depends on JWT gem choice
  end
  
  def authenticate_user_from_session
    # Devise session authentication (for hybrid mode)
    warden.authenticate(:scope => :user)
  end
  
  def current_user
    @current_user
  end
  
  def not_found
    render json: { error: 'Not found' }, status: :not_found
  end
  
  def forbidden
    render json: { error: 'Forbidden' }, status: :forbidden
  end
  
  def unprocessable_entity(exception)
    render json: { 
      error: 'Validation failed', 
      details: exception.record.errors.full_messages 
    }, status: :unprocessable_entity
  end
end
```

#### Step 1.3: Add JWT Authentication Gem

**Gemfile addition:**
```ruby
gem 'jwt'
# OR
gem 'devise-jwt'  # If keeping Devise
```

**Why JWT?**
- Stateless authentication
- Works across domains
- Mobile-ready
- Can coexist with session auth

---

### Phase 2: Serialization Layer (Weeks 2-3)

#### Step 2.1: Choose Serialization Strategy

**Option A: active_model_serializers** (RECOMMENDED)
```ruby
# Gemfile
gem 'active_model_serializers', '~> 0.10.0'

# app/serializers/user_serializer.rb
class UserSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :email, :role, :full_name
  
  has_many :skills
  has_many :badges_received
  has_one :availability
  
  def full_name
    "#{object.first_name} #{object.last_name}"
  end
end
```

**Option B: jsonapi-serializer** (Fast, JSON:API compliant)
```ruby
gem 'jsonapi-serializer'
```

**Option C: Jbuilder** (Already installed, but slower)
```ruby
# Already have it, but verbose for complex APIs
```

**RECOMMENDATION: active_model_serializers**
- Fast enough for your scale
- Clean, declarative syntax
- Handles nested associations well
- Easy to version

#### Step 2.2: Create Serializers for All Models

**Priority Order:**
1. UserSerializer (most complex)
2. ProjectSerializer
3. CompanySerializer
4. SchoolSerializer
5. BadgeSerializer
6. SkillSerializer
7. Supporting serializers (Team, SchoolLevel, etc.)

**Example Structure:**

```ruby
# app/serializers/user_serializer.rb
class UserSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :email, :role, 
             :job, :birthday, :certify, :full_name
  
  has_many :skills, serializer: SkillSerializer
  has_one :availability, serializer: AvailabilitySerializer
  
  # Conditional includes based on context
  attribute :badges_received, if: :include_badges?
  attribute :projects, if: :include_projects?
  
  def include_badges?
    instance_options[:include_badges]
  end
  
  def include_projects?
    instance_options[:include_projects]
  end
end

# Usage in controller:
render json: @user, serializer: UserSerializer, include_badges: true
```

---

### Phase 3: Authentication & Authorization API (Week 3)

#### Step 3.1: Implement JWT Authentication

**Create Authentication Controller:**

```ruby
# app/controllers/api/v1/auth_controller.rb
class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [:login, :register]
  
  def login
    user = User.find_by(email: params[:email])
    
    if user&.valid_password?(params[:password])
      if user.confirmed?
        token = generate_jwt(user)
        render json: {
          token: token,
          user: UserSerializer.new(user, include_contexts: true)
        }, status: :ok
      else
        render json: { error: 'Email not confirmed' }, status: :unauthorized
      end
    else
      render json: { error: 'Invalid credentials' }, status: :unauthorized
    end
  end
  
  def logout
    # Invalidate token (implement token blacklist if needed)
    head :no_content
  end
  
  def refresh
    # Refresh JWT token
    token = generate_jwt(current_user)
    render json: { token: token }, status: :ok
  end
  
  def me
    render json: current_user, serializer: UserSerializer, include_badges: true
  end
  
  private
  
  def generate_jwt(user)
    JWT.encode(
      { 
        user_id: user.id, 
        exp: 24.hours.from_now.to_i 
      },
      Rails.application.credentials.secret_key_base
    )
  end
end
```

#### Step 3.2: Add CORS Support

**Gemfile:**
```ruby
gem 'rack-cors'
```

**config/initializers/cors.rb:**
```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV['FRONTEND_URL'] || 'http://localhost:3001'
    
    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ['Authorization']
  end
end
```

#### Step 3.3: Update ApplicationController

**Keep existing for Rails views, create separate API base:**

```ruby
# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ActionController::API
  include Pundit::Authorization
  
  before_action :authenticate_api_user!
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
  
  # ... (authentication methods from earlier)
end
```

---

### Phase 4: Dashboard-Specific API Endpoints (Weeks 4-6)

#### Step 4.1: Company Dashboard API

**File:** `app/controllers/api/v1/companies_controller.rb`

```ruby
class Api::V1::CompaniesController < Api::V1::BaseController
  def show
    @company = Company.find(params[:id])
    authorize @company
    
    render json: @company, serializer: CompanySerializer, 
           include_members: true, include_projects: true
  end
  
  def update
    @company = Company.find(params[:id])
    authorize @company
    
    if @company.update(company_params)
      render json: @company, serializer: CompanySerializer
    else
      render json: { errors: @company.errors }, status: :unprocessable_entity
    end
  end
  
  def members
    @company = Company.find(params[:id])
    authorize @company, :manage_members?
    
    @members = @company.user_companies.includes(:user)
    render json: @members, each_serializer: UserCompanySerializer
  end
  
  def stats
    @company = Company.find(params[:id])
    authorize @company
    
    render json: {
      total_members: @company.users.count,
      total_projects: @company.projects.count,
      pending_members: @company.users_waiting_for_confirmation.count,
      active_contract: @company.active_contract?
    }
  end
  
  private
  
  def company_params
    params.require(:company).permit(
      :name, :city, :zip_code, :description, :email, :website,
      :take_trainee, :propose_workshop, :propose_summer_job,
      skill_ids: [], sub_skill_ids: []
    )
  end
end
```

**Additional Controllers:**
```ruby
Api::V1::Companies::MembersController      # Member CRUD
Api::V1::Companies::ProjectsController     # Company projects
Api::V1::Companies::PartnershipsController # School partnerships
Api::V1::Companies::BadgesController       # Badge assignment
```

#### Step 4.2: School Dashboard API

**File:** `app/controllers/api/v1/schools_controller.rb`

```ruby
class Api::V1::SchoolsController < Api::V1::BaseController
  def show
    @school = School.find(params[:id])
    authorize @school
    
    render json: @school, serializer: SchoolSerializer,
           include_levels: true, include_members: true
  end
  
  def members
    @school = School.find(params[:id])
    authorize @school, :manage_members?
    
    @members = @school.user_schools.includes(:user, :school_levels)
    render json: @members, each_serializer: UserSchoolSerializer
  end
  
  def levels
    @school = School.find(params[:id])
    authorize @school
    
    render json: @school.school_levels, each_serializer: SchoolLevelSerializer
  end
  
  def stats
    @school = School.find(params[:id])
    authorize @school
    
    render json: {
      total_teachers: @school.users.teachers.count,
      total_students: @school.users.children.count,
      total_levels: @school.school_levels.count,
      pending_partnerships: @school.school_companies.pending.count,
      active_contract: @school.active_contract?
    }
  end
end
```

**Additional Controllers:**
```ruby
Api::V1::Schools::MembersController        # Teacher/staff management
Api::V1::Schools::LevelsController         # Class management
Api::V1::Schools::PartnershipsController   # Company partnerships
Api::V1::Schools::ProjectsController       # School projects
Api::V1::Schools::BadgesController         # Badge management
```

#### Step 4.3: User Dashboard API

**File:** `app/controllers/api/v1/users_controller.rb`

```ruby
class Api::V1::UsersController < Api::V1::BaseController
  def me
    render json: current_user, serializer: UserSerializer,
           include_badges: true, include_projects: true, include_skills: true
  end
  
  def update
    if current_user.update(user_params)
      render json: current_user, serializer: UserSerializer
    else
      render json: { errors: current_user.errors }, status: :unprocessable_entity
    end
  end
  
  def projects
    @projects = policy_scope(Project.my_projects(current_user))
    render json: @projects, each_serializer: ProjectSerializer
  end
  
  def badges
    @badges = current_user.badges_received.includes(:badge, :sender, :organization)
    render json: @badges, each_serializer: UserBadgeSerializer
  end
  
  def participants
    @participants = policy_scope(User, policy_scope_class: Participants::SchoolsPolicy::Scope)
    @participants += policy_scope(User, policy_scope_class: Participants::CompaniesPolicy::Scope) if current_user.companies.any?
    
    render json: @participants.uniq, each_serializer: ParticipantSerializer
  end
  
  private
  
  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :job, :birthday, :contact_email,
      :take_trainee, :propose_workshop, :show_my_skills,
      skill_ids: [], sub_skill_ids: [],
      availability_attributes: [:monday, :tuesday, :wednesday, :thursday, :friday, :other]
    )
  end
end
```

#### Step 4.4: Teacher Dashboard API

**File:** `app/controllers/api/v1/teachers_controller.rb`

```ruby
class Api::V1::TeachersController < Api::V1::BaseController
  before_action :ensure_teacher!
  
  def dashboard
    render json: {
      my_schools: current_user.schools.confirmed.map { |s| SchoolSerializer.new(s) },
      my_projects: current_user.projects_owner.map { |p| ProjectSerializer.new(p) },
      pending_participants: pending_participants_count,
      students_count: students_in_my_classes_count
    }
  end
  
  def students
    @students = policy_scope(User.participants_for_teacher(current_user))
    render json: @students, each_serializer: StudentSerializer
  end
  
  def my_classes
    @school_levels = current_user.schools.flat_map(&:school_levels).uniq
    render json: @school_levels, each_serializer: SchoolLevelSerializer,
           include_students: true
  end
  
  private
  
  def ensure_teacher!
    render json: { error: 'Teacher access only' }, status: :forbidden unless current_user.teacher?
  end
  
  def pending_participants_count
    current_user.projects_owner.sum { |p| p.pending_participants.count }
  end
  
  def students_in_my_classes_count
    current_user.school_levels.sum { |level| level.users.children.count }
  end
end
```

---

### Phase 5: Create Comprehensive Serializers (Week 3)

#### Core Serializers

**UserSerializer:**
```ruby
class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :first_name, :last_name, :full_name,
             :role, :job, :birthday, :certify, :admin, :avatar_url
  
  has_many :skills, if: -> { instance_options[:include_skills] }
  has_many :badges_received, serializer: UserBadgeSerializer, if: -> { instance_options[:include_badges] }
  has_one :availability, if: -> { instance_options[:include_availability] }
  
  def avatar_url
    return nil unless object.avatar.attached?
    Rails.application.routes.url_helpers.rails_blob_url(object.avatar, only_path: false)
  end
end
```

**ProjectSerializer:**
```ruby
class ProjectSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :status, 
             :start_date, :end_date, :participants_number,
             :main_picture_url, :can_edit
  
  belongs_to :owner, serializer: UserSerializer
  has_many :skills
  has_many :tags
  has_many :school_levels, if: -> { instance_options[:include_levels] }
  has_many :companies, if: -> { instance_options[:include_companies] }
  has_many :teams, if: -> { instance_options[:include_teams] }
  
  def can_edit
    object.can_edit?(current_user)
  end
  
  def main_picture_url
    return nil unless object.main_picture.attached?
    Rails.application.routes.url_helpers.rails_blob_url(object.main_picture, only_path: false)
  end
  
  def current_user
    scope
  end
end
```

**CompanySerializer:**
```ruby
class CompanySerializer < ActiveModel::Serializer
  attributes :id, :name, :city, :zip_code, :full_name,
             :description, :email, :website, :status,
             :take_trainee, :propose_workshop, :has_active_contract
  
  belongs_to :company_type
  has_many :skills, if: -> { instance_options[:include_skills] }
  has_many :users, serializer: UserSerializer, if: -> { instance_options[:include_members] }
  
  def has_active_contract
    object.active_contract?
  end
end
```

**SchoolSerializer:**
```ruby
class SchoolSerializer < ActiveModel::Serializer
  attributes :id, :name, :city, :zip_code, :full_name,
             :school_type, :status, :has_active_contract
  
  has_many :school_levels, if: -> { instance_options[:include_levels] }
  has_many :users, serializer: UserSerializer, if: -> { instance_options[:include_members] }
  
  def has_active_contract
    object.active_contract?
  end
end
```

---

### Phase 6: Implement Dashboard Controllers (Weeks 4-5)

#### Company Dashboard Controllers

```ruby
# app/controllers/api/v1/dashboards/company_controller.rb
class Api::V1::Dashboards::CompanyController < Api::V1::BaseController
  before_action :set_company
  before_action :authorize_company_access!
  
  def show
    render json: {
      company: CompanySerializer.new(@company, include_skills: true),
      stats: company_stats,
      recent_projects: recent_projects,
      pending_approvals: pending_approvals
    }
  end
  
  private
  
  def set_company
    @company = Company.find(params[:company_id])
  end
  
  def authorize_company_access!
    user_company = current_user.user_company.find_by(company: @company)
    
    unless user_company&.confirmed?
      render json: { error: 'Not a member of this company' }, status: :forbidden
    end
  end
  
  def company_stats
    {
      total_members: @company.users.count,
      confirmed_members: @company.user_companies.confirmed.count,
      pending_members: @company.user_companies.pending.count,
      total_projects: @company.projects.count,
      active_projects: @company.projects.in_progress.count,
      partnerships: @company.schools.count
    }
  end
  
  def recent_projects
    @company.projects.order(created_at: :desc).limit(5)
      .map { |p| ProjectSerializer.new(p) }
  end
  
  def pending_approvals
    return [] unless current_user.company_admin?(@company)
    
    @company.user_companies.pending.map { |uc| UserCompanySerializer.new(uc) }
  end
end
```

#### School Dashboard Controllers

```ruby
# app/controllers/api/v1/dashboards/school_controller.rb
class Api::V1::Dashboards::SchoolController < Api::V1::BaseController
  before_action :set_school
  before_action :authorize_school_access!
  
  def show
    render json: {
      school: SchoolSerializer.new(@school, include_levels: true),
      stats: school_stats,
      recent_projects: recent_projects,
      pending_approvals: pending_approvals
    }
  end
  
  private
  
  def set_school
    @school = School.find(params[:school_id])
  end
  
  def authorize_school_access!
    user_school = current_user.user_schools.find_by(school: @school)
    
    unless user_school&.confirmed?
      render json: { error: 'Not a member of this school' }, status: :forbidden
    end
  end
  
  def school_stats
    {
      total_teachers: @school.users.teachers.count,
      total_students: @school.users.children.count,
      total_levels: @school.school_levels.count,
      total_projects: @school.projects.count,
      partnerships: @school.companies.count,
      pending_teachers: @school.user_schools.pending.count
    }
  end
end
```

#### User Dashboard Controller

```ruby
# app/controllers/api/v1/dashboards/user_controller.rb
class Api::V1::Dashboards::UserController < Api::V1::BaseController
  def show
    render json: {
      user: UserSerializer.new(current_user, include_all: true),
      my_projects: my_projects,
      my_badges: my_badges,
      my_schools: my_schools,
      my_companies: my_companies,
      available_projects: available_projects
    }
  end
  
  private
  
  def my_projects
    Project.my_projects(current_user)
      .order(created_at: :desc)
      .map { |p| ProjectSerializer.new(p) }
  end
  
  def my_badges
    current_user.badges_received
      .includes(:badge, :sender, :organization)
      .order(created_at: :desc)
      .map { |b| UserBadgeSerializer.new(b) }
  end
  
  def my_schools
    current_user.confirmed_schools
      .map { |s| SchoolSerializer.new(s) }
  end
  
  def my_companies
    current_user.confirmed_companies
      .map { |c| CompanySerializer.new(c) }
  end
  
  def available_projects
    policy_scope(Project)
      .where.not(owner: current_user)
      .order(created_at: :desc)
      .limit(10)
      .map { |p| ProjectSerializer.new(p) }
  end
end
```

---

### Phase 7: Enhance Existing Policies (Week 6)

#### Update Policies for API Context

**CompanyPolicy:**
```ruby
class CompanyPolicy < ApplicationPolicy
  def show?
    user.user_company.exists?(company: record)
  end
  
  def update?
    user.company_admin?(record)
  end
  
  def manage_members?
    user.company_admin?(record)
  end
  
  def manage_projects?
    user.company_admin?(record) || user.user_company.find_by(company: record)&.can_create_project?
  end
  
  def assign_badges?
    user.user_company.find_by(company: record)&.can_access_badges?
  end
end
```

**SchoolPolicy:**
```ruby
class SchoolPolicy < ApplicationPolicy
  def show?
    user.user_schools.exists?(school: record)
  end
  
  def update?
    user.school_admin?(record)
  end
  
  def manage_members?
    user.school_admin?(record)
  end
  
  def manage_levels?
    user.school_admin?(record)
  end
  
  def assign_badges?
    user.user_schools.find_by(school: record)&.can_access_badges?
  end
end
```

---

## 4. Implementation Roadmap

### Week 1-2: Foundation ✅ COMPLETED
- [x] Add JWT gem (devise-jwt or jwt)
- [x] Add CORS gem and configure
- [x] Add active_model_serializers gem
- [x] Create Api::V1::BaseController
- [x] Implement JWT authentication
- [x] Create AuthController (login, logout, refresh, me)
- [x] Write rswag specs for auth endpoints
- [x] Test authentication flow

### Week 3: Serialization Layer ✅ COMPLETED
- [x] Create all core serializers (User, Project, Company, School, Badge)
- [x] Create supporting serializers (Skill, Tag, Team, etc.)
- [x] Add conditional includes
- [x] Handle file attachments (URLs)
- [x] Test serializer output

### Week 4: Company Dashboard API
- [ ] CompaniesController (show, update, stats)
- [ ] Companies::MembersController (index, create, update, destroy)
- [ ] Companies::ProjectsController (index, create, update)
- [ ] Companies::PartnershipsController (index, update)
- [ ] Companies::BadgesController (create)
- [ ] Write rswag specs for all endpoints
- [ ] Test with Postman

### Week 5: School Dashboard API ✅ COMPLETED
- [x] SchoolsController (show, update, stats)
- [x] Schools::MembersController (index, create, update, destroy)
- [x] Schools::LevelsController (index, create, update, destroy, students)
- [x] Schools::ProjectsController (index, create)
- [x] Schools::PartnershipsController (index, create, update, destroy, confirm, reject) ⭐ NEW
- [x] Schools::BranchesController (index, invite, settings)
- [x] Schools::BranchRequestsController (index, create, confirm, reject, destroy)
- [x] Schools::BadgesController (assign, assigned)
- [x] PartnershipMailer (request, confirm, reject emails) ⭐ NEW
- [x] BranchRequestMailer (request, confirm, reject emails) ⭐ NEW
- [x] Test with curl (all endpoints verified)

### Week 6: User & Teacher Dashboard API ✅ COMPLETED
- [x] UsersController (me, update, projects, badges, participants)
- [x] TeachersController (dashboard, students, my_classes)
- [x] Teachers::ProjectsController (CRUD, member management)
- [x] Teachers::BadgesController (attribution tracking)
- [x] BadgesController (index, assign)
- [x] Write rswag specs
- [x] Test with Postman

### Week 7-8: Advanced Features
- [ ] File upload API (avatar, project images)
- [ ] Badge assignment API (multi-step wizard)
- [ ] Participant search/filter API
- [ ] Project creation API (with nested attributes)
- [ ] Real-time notifications (ActionCable)
- [ ] Write comprehensive specs

### Week 9-10: React Dashboard Development
- [ ] Setup React apps (4 separate or monorepo)
- [ ] Implement authentication flow
- [ ] Build dashboard layouts
- [ ] Integrate API calls
- [ ] Handle file uploads
- [ ] Implement routing

### Week 11-12: Testing & Migration
- [ ] End-to-end testing
- [ ] Performance optimization
- [ ] Security audit
- [ ] Gradual user migration
- [ ] Monitor and fix issues

---

## 5. Technical Implementation Details

### 5.1 Recommended Gems to Add

```ruby
# Gemfile additions
gem 'jwt'                           # JWT authentication
gem 'rack-cors'                     # CORS support
gem 'active_model_serializers'     # JSON serialization
gem 'kaminari'                      # Already have pagy, but AMS works better with kaminari
gem 'redis-rails'                   # Token blacklist (optional)

# Optional but recommended
gem 'fast_jsonapi'                  # Alternative serializer (faster)
gem 'oj'                            # Faster JSON parsing
gem 'rack-attack'                   # Rate limiting
gem 'versionist'                    # API versioning helper
```

### 5.2 JWT Implementation Pattern

**Create JWT Service:**

```ruby
# app/services/json_web_token.rb
class JsonWebToken
  SECRET_KEY = Rails.application.credentials.secret_key_base
  
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end
  
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
```

**Usage in BaseController:**

```ruby
def authenticate_user_from_token
  token = request.headers['Authorization']&.split(' ')&.last
  return nil unless token
  
  decoded = JsonWebToken.decode(token)
  return nil unless decoded
  
  User.find_by(id: decoded[:user_id])
end
```

### 5.3 File Upload API Pattern

**For ActiveStorage attachments:**

```ruby
# app/controllers/api/v1/users/avatars_controller.rb
class Api::V1::Users::AvatarsController < Api::V1::BaseController
  def create
    if current_user.avatar.attach(params[:avatar])
      render json: { 
        avatar_url: rails_blob_url(current_user.avatar) 
      }, status: :created
    else
      render json: { error: 'Upload failed' }, status: :unprocessable_entity
    end
  end
  
  def destroy
    current_user.avatar.purge
    head :no_content
  end
end
```

**React side:**
```javascript
const formData = new FormData();
formData.append('avatar', file);

fetch('/api/v1/users/avatar', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`
  },
  body: formData
});
```

### 5.4 Pagination Pattern

**Controller:**
```ruby
def index
  @pagy, @records = pagy(policy_scope(Model).all, items: 20)
  
  render json: {
    data: ActiveModelSerializers::SerializableResource.new(@records),
    meta: {
      current_page: @pagy.page,
      total_pages: @pagy.pages,
      total_count: @pagy.count,
      per_page: @pagy.items
    }
  }
end
```

### 5.5 Error Handling Pattern

**Standardized Error Responses:**

```ruby
# app/controllers/concerns/api_error_handler.rb
module ApiErrorHandler
  extend ActiveSupport::Concern
  
  included do
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from Pundit::NotAuthorizedError, with: :forbidden
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :bad_request
  end
  
  private
  
  def not_found(exception)
    render json: { 
      error: 'Not Found',
      message: exception.message 
    }, status: :not_found
  end
  
  def forbidden(exception)
    render json: { 
      error: 'Forbidden',
      message: 'You are not authorized to perform this action'
    }, status: :forbidden
  end
  
  def unprocessable_entity(exception)
    render json: { 
      error: 'Validation Failed',
      details: exception.record.errors.full_messages 
    }, status: :unprocessable_entity
  end
  
  def bad_request(exception)
    render json: { 
      error: 'Bad Request',
      message: exception.message 
    }, status: :bad_request
  end
end
```

---

## 6. React Frontend Architecture

### 6.1 Recommended Stack

```javascript
// Core
- React 18+
- TypeScript (strongly recommended)
- React Router v6 (routing)

// State Management
- React Query (API state) - HIGHLY RECOMMENDED
- Zustand or Redux Toolkit (global state)

// UI Framework
- Material-UI or Ant Design (component library)
- Tailwind CSS (styling)

// Forms
- React Hook Form (form management)
- Zod (validation)

// HTTP Client
- Axios (with interceptors for JWT)
```

### 6.2 Project Structure (Single Unified App - RECOMMENDED)

```
kinship-frontend/
├── src/
│   ├── app/
│   │   ├── App.tsx                    # Main app with routing
│   │   ├── AppLayout.tsx              # Layout with context switcher
│   │   └── routes.tsx                 # Route configuration
│   │
│   ├── contexts/
│   │   ├── UserContext.tsx            # User + available contexts
│   │   ├── DashboardContext.tsx       # Current dashboard context
│   │   └── AuthContext.tsx            # Authentication state
│   │
│   ├── dashboards/
│   │   ├── user/                      # Personal dashboard
│   │   │   ├── pages/
│   │   │   ├── components/
│   │   │   └── index.tsx
│   │   │
│   │   ├── teacher/                   # Teacher dashboard
│   │   │   ├── pages/
│   │   │   ├── components/
│   │   │   └── index.tsx
│   │   │
│   │   ├── company/                   # Company dashboard
│   │   │   ├── pages/
│   │   │   ├── components/
│   │   │   └── index.tsx
│   │   │
│   │   └── school/                    # School dashboard
│   │       ├── pages/
│   │       ├── components/
│   │       └── index.tsx
│   │
│   ├── shared/
│   │   ├── components/
│   │   │   ├── ContextSwitcher.tsx    # Dashboard switcher
│   │   │   ├── Navigation.tsx
│   │   │   └── Layout.tsx
│   │   ├── hooks/
│   │   │   ├── useCurrentContext.ts
│   │   │   ├── useContextSwitch.ts
│   │   │   └── useAuth.ts
│   │   └── utils/
│   │
│   ├── api/
│   │   ├── client.ts                  # Axios instance
│   │   ├── hooks/                     # React Query hooks
│   │   └── types.ts                   # TypeScript types
│   │
│   └── types/
│       ├── user.ts
│       ├── context.ts
│       └── dashboard.ts
│
├── package.json
└── tsconfig.json
```

**Benefits of Unified App:**
- ✅ Single authentication state
- ✅ Shared components and utilities
- ✅ Seamless context switching
- ✅ Easier state management
- ✅ Single deployment

### 6.3 API Client Setup

```typescript
// packages/api-client/src/client.ts
import axios from 'axios';

const apiClient = axios.create({
  baseURL: process.env.REACT_APP_API_URL || 'http://localhost:3000/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor - add JWT token
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor - handle errors
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Redirect to login
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default apiClient;
```

### 6.4 Context Switching Implementation

#### 6.4.1 Context Types

```typescript
// src/types/context.ts
export type DashboardContext = 'user' | 'teacher' | 'company' | 'school';

export interface OrganizationContext {
  id: number;
  name: string;
  role: 'admin' | 'member' | 'owner';
  permissions: {
    admin: boolean;
    owner?: boolean;
    can_access_badges?: boolean;
    can_create_project?: boolean;
  };
}

export interface AvailableContexts {
  user_dashboard: boolean;
  teacher_dashboard: boolean;
  schools: OrganizationContext[];
  companies: OrganizationContext[];
}

export interface UserContextState {
  user: User;
  currentContext: DashboardContext;
  currentOrganizationId?: number;
  availableContexts: AvailableContexts;
}
```

#### 6.4.2 Context Provider

```typescript
// src/contexts/DashboardContext.tsx
import { createContext, useContext, useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useCurrentUser } from '../api/hooks/useAuth';

const DashboardContext = createContext<DashboardContextType | undefined>(undefined);

export const DashboardProvider = ({ children }) => {
  const navigate = useNavigate();
  const { data: user, isLoading } = useCurrentUser();
  
  // Load persisted context from localStorage
  const [currentContext, setCurrentContext] = useState<DashboardContext>(() => {
    return localStorage.getItem('kinship_current_context') as DashboardContext || 'user';
  });
  
  const [currentOrgId, setCurrentOrgId] = useState<number | undefined>(() => {
    const stored = localStorage.getItem('kinship_current_org_id');
    return stored ? parseInt(stored) : undefined;
  });
  
  // Determine default context on login
  useEffect(() => {
    if (!user || isLoading) return;
    
    const contexts = user.available_contexts;
    
    // If no stored context, determine default
    if (!localStorage.getItem('kinship_current_context')) {
      const defaultContext = determineDefaultContext(contexts);
      setCurrentContext(defaultContext.type);
      setCurrentOrgId(defaultContext.orgId);
    }
  }, [user, isLoading]);
  
  const determineDefaultContext = (contexts: AvailableContexts) => {
    // Priority 1: User dashboard (if available)
    if (contexts.user_dashboard) {
      return { type: 'user' as DashboardContext, orgId: undefined };
    }
    
    // Priority 2: First school (if admin)
    const adminSchool = contexts.schools.find(s => s.permissions.admin);
    if (adminSchool) {
      return { type: 'school' as DashboardContext, orgId: adminSchool.id };
    }
    
    // Priority 3: First company (if admin)
    const adminCompany = contexts.companies.find(c => c.permissions.admin);
    if (adminCompany) {
      return { type: 'company' as DashboardContext, orgId: adminCompany.id };
    }
    
    // Priority 4: First available school
    if (contexts.schools.length > 0) {
      return { type: 'school' as DashboardContext, orgId: contexts.schools[0].id };
    }
    
    // Priority 5: First available company
    if (contexts.companies.length > 0) {
      return { type: 'company' as DashboardContext, orgId: contexts.companies[0].id };
    }
    
    // Fallback: user dashboard (even if not available - will show error)
    return { type: 'user' as DashboardContext, orgId: undefined };
  };
  
  const switchContext = (context: DashboardContext, orgId?: number) => {
    setCurrentContext(context);
    setCurrentOrgId(orgId);
    
    // Persist to localStorage
    localStorage.setItem('kinship_current_context', context);
    if (orgId) {
      localStorage.setItem('kinship_current_org_id', orgId.toString());
    } else {
      localStorage.removeItem('kinship_current_org_id');
    }
    
    // Navigate to appropriate dashboard
    navigateToDashboard(context, orgId);
  };
  
  const navigateToDashboard = (context: DashboardContext, orgId?: number) => {
    switch (context) {
      case 'user':
        navigate('/dashboard/user');
        break;
      case 'teacher':
        navigate('/dashboard/teacher');
        break;
      case 'company':
        navigate(`/dashboard/company/${orgId}`);
        break;
      case 'school':
        navigate(`/dashboard/school/${orgId}`);
        break;
    }
  };
  
  const getCurrentOrganization = (): OrganizationContext | undefined => {
    if (!user || !currentOrgId) return undefined;
    
    if (currentContext === 'company') {
      return user.available_contexts.companies.find(c => c.id === currentOrgId);
    }
    
    if (currentContext === 'school') {
      return user.available_contexts.schools.find(s => s.id === currentOrgId);
    }
    
    return undefined;
  };
  
  const value = {
    user,
    currentContext,
    currentOrganizationId: currentOrgId,
    currentOrganization: getCurrentOrganization(),
    availableContexts: user?.available_contexts,
    switchContext,
    isLoading,
  };
  
  return (
    <DashboardContext.Provider value={value}>
      {children}
    </DashboardContext.Provider>
  );
};

export const useDashboardContext = () => {
  const context = useContext(DashboardContext);
  if (!context) {
    throw new Error('useDashboardContext must be used within DashboardProvider');
  }
  return context;
};
```

#### 6.4.3 Context Switcher Component

```typescript
// src/shared/components/ContextSwitcher.tsx
import { Menu, MenuItem, ListItemIcon, ListItemText, Divider, Badge } from '@mui/material';
import { Person, School, Business, MenuBook } from '@mui/icons-material';
import { useDashboardContext } from '../../contexts/DashboardContext';

export const ContextSwitcher = () => {
  const { 
    user, 
    currentContext, 
    currentOrganizationId,
    availableContexts, 
    switchContext 
  } = useDashboardContext();
  
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  
  if (!user || !availableContexts) return null;
  
  const getCurrentContextLabel = () => {
    if (currentContext === 'user') return 'Personal Dashboard';
    if (currentContext === 'teacher') return 'Teacher Dashboard';
    if (currentContext === 'company') {
      const company = availableContexts.companies.find(c => c.id === currentOrganizationId);
      return company?.name || 'Company Dashboard';
    }
    if (currentContext === 'school') {
      const school = availableContexts.schools.find(s => s.id === currentOrganizationId);
      return school?.name || 'School Dashboard';
    }
  };
  
  return (
    <>
      <Button
        onClick={(e) => setAnchorEl(e.currentTarget)}
        startIcon={<SwapHoriz />}
        variant="outlined"
      >
        {getCurrentContextLabel()}
      </Button>
      
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={() => setAnchorEl(null)}
      >
        {/* Personal Dashboard */}
        {availableContexts.user_dashboard && (
          <MenuItem 
            onClick={() => {
              switchContext('user');
              setAnchorEl(null);
            }}
            selected={currentContext === 'user'}
          >
            <ListItemIcon><Person /></ListItemIcon>
            <ListItemText primary="Personal Dashboard" />
          </MenuItem>
        )}
        
        {/* Teacher Dashboard */}
        {availableContexts.teacher_dashboard && (
          <MenuItem 
            onClick={() => {
              switchContext('teacher');
              setAnchorEl(null);
            }}
            selected={currentContext === 'teacher'}
          >
            <ListItemIcon><MenuBook /></ListItemIcon>
            <ListItemText primary="Teacher Dashboard" />
          </MenuItem>
        )}
        
        {/* Schools */}
        {availableContexts.schools.length > 0 && (
          <>
            <Divider />
            <MenuItem disabled>
              <ListItemText primary="Schools" secondary="Your educational institutions" />
            </MenuItem>
            {availableContexts.schools.map(school => (
              <MenuItem
                key={school.id}
                onClick={() => {
                  switchContext('school', school.id);
                  setAnchorEl(null);
                }}
                selected={currentContext === 'school' && currentOrganizationId === school.id}
                sx={{ pl: 4 }}
              >
                <ListItemIcon><School /></ListItemIcon>
                <ListItemText 
                  primary={school.name}
                  secondary={school.permissions.admin ? 'Admin' : 'Member'}
                />
                {school.permissions.admin && (
                  <Badge badgeContent="Admin" color="primary" />
                )}
              </MenuItem>
            ))}
          </>
        )}
        
        {/* Companies */}
        {availableContexts.companies.length > 0 && (
          <>
            <Divider />
            <MenuItem disabled>
              <ListItemText primary="Companies" secondary="Your organizations" />
            </MenuItem>
            {availableContexts.companies.map(company => (
              <MenuItem
                key={company.id}
                onClick={() => {
                  switchContext('company', company.id);
                  setAnchorEl(null);
                }}
                selected={currentContext === 'company' && currentOrganizationId === company.id}
                sx={{ pl: 4 }}
              >
                <ListItemIcon><Business /></ListItemIcon>
                <ListItemText 
                  primary={company.name}
                  secondary={
                    company.permissions.owner ? 'Owner' : 
                    company.permissions.admin ? 'Admin' : 'Member'
                  }
                />
                {company.permissions.admin && (
                  <Badge badgeContent="Admin" color="primary" />
                )}
              </MenuItem>
            ))}
          </>
        )}
      </Menu>
    </>
  );
};
```

#### 6.4.4 App Routing with Context

```typescript
// src/app/App.tsx
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { DashboardProvider, useDashboardContext } from '../contexts/DashboardContext';
import { AppLayout } from './AppLayout';

// Dashboard imports
import UserDashboard from '../dashboards/user';
import TeacherDashboard from '../dashboards/teacher';
import CompanyDashboard from '../dashboards/company';
import SchoolDashboard from '../dashboards/school';

const queryClient = new QueryClient();

export const App = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <DashboardProvider>
          <AppRoutes />
        </DashboardProvider>
      </BrowserRouter>
    </QueryClientProvider>
  );
};

const AppRoutes = () => {
  const { user, availableContexts, isLoading } = useDashboardContext();
  
  if (isLoading) return <LoadingScreen />;
  if (!user) return <Navigate to="/login" />;
  
  return (
    <AppLayout>
      <Routes>
        {/* Personal Dashboard */}
        {availableContexts?.user_dashboard && (
          <Route path="/dashboard/user/*" element={<UserDashboard />} />
        )}
        
        {/* Teacher Dashboard */}
        {availableContexts?.teacher_dashboard && (
          <Route path="/dashboard/teacher/*" element={<TeacherDashboard />} />
        )}
        
        {/* School Dashboards */}
        {availableContexts?.schools.map(school => (
          <Route 
            key={school.id}
            path={`/dashboard/school/${school.id}/*`} 
            element={<SchoolDashboard schoolId={school.id} />} 
          />
        ))}
        
        {/* Company Dashboards */}
        {availableContexts?.companies.map(company => (
          <Route 
            key={company.id}
            path={`/dashboard/company/${company.id}/*`} 
            element={<CompanyDashboard companyId={company.id} />} 
          />
        ))}
        
        {/* Default redirect to first available dashboard */}
        <Route path="/" element={<DefaultDashboardRedirect />} />
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </AppLayout>
  );
};

const DefaultDashboardRedirect = () => {
  const { availableContexts } = useDashboardContext();
  
  // Priority 1: User dashboard
  if (availableContexts?.user_dashboard) {
    return <Navigate to="/dashboard/user" />;
  }
  
  // Priority 2: First school (admin)
  const adminSchool = availableContexts?.schools.find(s => s.permissions.admin);
  if (adminSchool) {
    return <Navigate to={`/dashboard/school/${adminSchool.id}`} />;
  }
  
  // Priority 3: First company (admin)
  const adminCompany = availableContexts?.companies.find(c => c.permissions.admin);
  if (adminCompany) {
    return <Navigate to={`/dashboard/company/${adminCompany.id}`} />;
  }
  
  // Priority 4: First available organization
  if (availableContexts?.schools.length > 0) {
    return <Navigate to={`/dashboard/school/${availableContexts.schools[0].id}`} />;
  }
  
  if (availableContexts?.companies.length > 0) {
    return <Navigate to={`/dashboard/company/${availableContexts.companies[0].id}`} />;
  }
  
  // No contexts available
  return <NoAccessPage />;
};
```

#### 6.4.5 Context-Aware Hooks

```typescript
// src/shared/hooks/useCurrentContext.ts
export const useCurrentContext = () => {
  const context = useDashboardContext();
  
  return {
    isUserContext: context.currentContext === 'user',
    isTeacherContext: context.currentContext === 'teacher',
    isCompanyContext: context.currentContext === 'company',
    isSchoolContext: context.currentContext === 'school',
    currentOrganization: context.currentOrganization,
    hasAdminAccess: context.currentOrganization?.permissions.admin || false,
  };
};

// Usage in components
const MyComponent = () => {
  const { isCompanyContext, currentOrganization, hasAdminAccess } = useCurrentContext();
  
  if (isCompanyContext && hasAdminAccess) {
    return <AdminFeatures company={currentOrganization} />;
  }
  
  return <MemberFeatures />;
};
```

#### 6.4.6 Context Validation Guard

```typescript
// src/shared/components/ContextGuard.tsx
interface ContextGuardProps {
  requiredContext: DashboardContext;
  requiredPermission?: 'admin' | 'owner' | 'can_access_badges';
  fallback?: React.ReactNode;
  children: React.ReactNode;
}

export const ContextGuard = ({ 
  requiredContext, 
  requiredPermission,
  fallback,
  children 
}: ContextGuardProps) => {
  const { currentContext, currentOrganization } = useDashboardContext();
  
  // Check context matches
  if (currentContext !== requiredContext) {
    return fallback || <Navigate to="/" />;
  }
  
  // Check permissions if required
  if (requiredPermission && currentOrganization) {
    const hasPermission = currentOrganization.permissions[requiredPermission];
    if (!hasPermission) {
      return fallback || <PermissionDenied />;
    }
  }
  
  return <>{children}</>;
};

// Usage
<ContextGuard requiredContext="company" requiredPermission="admin">
  <CompanySettings />
</ContextGuard>
```

### 6.5 React Query Setup

```typescript
// packages/api-client/src/hooks/useUser.ts
import { useQuery, useMutation } from '@tanstack/react-query';
import apiClient from '../client';

export const useCurrentUser = () => {
  return useQuery({
    queryKey: ['currentUser'],
    queryFn: async () => {
      const { data } = await apiClient.get('/auth/me');
      return data;
    },
  });
};

export const useUpdateUser = () => {
  return useMutation({
    mutationFn: async (userData) => {
      const { data } = await apiClient.patch('/users/me', userData);
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['currentUser']);
    },
  });
};

export const useUserProjects = () => {
  return useQuery({
    queryKey: ['userProjects'],
    queryFn: async () => {
      const { data } = await apiClient.get('/users/me/projects');
      return data;
    },
  });
};
```

---

## 7. Migration Strategy

### 7.1 Parallel Development Approach

**Phase 1: API Development (Backend)**
- Build all API endpoints
- Keep existing Rails views functioning
- Deploy API to staging
- Test thoroughly

**Phase 2: React Dashboard Development (Frontend)**
- Develop React apps against staging API
- User acceptance testing
- Performance optimization

**Phase 3: Gradual Migration**
```
Week 1: Beta users on React (10%)
Week 2: Early adopters (25%)
Week 3: Half users (50%)
Week 4: Majority (75%)
Week 5: All users (100%)
Week 6: Remove old Rails views
```

### 7.2 Feature Flags

**Add gem:**
```ruby
gem 'flipper'
gem 'flipper-active_record'
gem 'flipper-ui'
```

**Usage:**
```ruby
# Enable React dashboard for specific users
if Flipper.enabled?(:react_dashboard, current_user)
  redirect_to react_dashboard_url
else
  # Show existing Rails views
end
```

### 7.3 Backward Compatibility

**Keep existing routes:**
```ruby
# config/routes.rb
Rails.application.routes.draw do
  # New API routes
  namespace :api do
    namespace :v1 do
      # ... all new API routes
    end
  end
  
  # Existing web routes (keep during transition)
  resources :projects
  resources :companies
  # ... etc
  
  # React dashboard routes (catch-all)
  get '/company-dashboard/*path', to: 'react#index'
  get '/school-dashboard/*path', to: 'react#index'
  get '/user-dashboard/*path', to: 'react#index'
  get '/teacher-dashboard/*path', to: 'react#index'
end
```

---

## 8. Security Considerations for API

### 8.1 Rate Limiting

```ruby
# Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
Rack::Attack.throttle('api/ip', limit: 300, period: 5.minutes) do |req|
  req.ip if req.path.start_with?('/api')
end

Rack::Attack.throttle('api/user', limit: 1000, period: 1.hour) do |req|
  req.env['current_user']&.id if req.path.start_with?('/api')
end
```

### 8.2 Token Blacklist (Optional)

```ruby
# For logout functionality
class TokenBlacklist < ApplicationRecord
  # token, expires_at
end

# In BaseController
def token_blacklisted?
  token = request.headers['Authorization']&.split(' ')&.last
  TokenBlacklist.exists?(token: token)
end
```

### 8.3 HTTPS Enforcement

```ruby
# config/environments/production.rb
config.force_ssl = true
```

---

## 9. Testing Strategy for API

### 9.1 Expand rswag Specs

**For each new endpoint:**
```ruby
# spec/requests/api/v1/companies_spec.rb
path '/api/v1/companies/{id}' do
  get 'Get company details' do
    tags 'Companies'
    security [Bearer: []]
    
    parameter name: :id, in: :path, type: :integer
    
    response '200', 'successful' do
      schema type: :object,
        properties: {
          id: { type: :integer },
          name: { type: :string },
          # ... full schema
        }
      
      let(:company) { create(:company, :confirmed) }
      let(:id) { company.id }
      
      run_test! do |response|
        json = JSON.parse(response.body)
        expect(json['id']).to eq(company.id)
      end
    end
    
    response '404', 'not found' do
      let(:id) { 99999 }
      run_test!
    end
  end
end
```

### 9.2 Integration Tests

**Test complete workflows:**
```ruby
# spec/requests/workflows/project_creation_spec.rb
RSpec.describe 'Project Creation Workflow', type: :request do
  it 'allows teacher to create project with nested attributes' do
    teacher = create(:user, :teacher, :confirmed)
    school = create(:school, :confirmed)
    create(:user_school, user: teacher, school: school, status: :confirmed)
    
    token = generate_jwt(teacher)
    
    post '/api/v1/projects',
      headers: { 'Authorization' => "Bearer #{token}" },
      params: {
        project: {
          title: 'Test Project',
          description: 'Description',
          start_date: 1.week.from_now,
          end_date: 1.month.from_now,
          school_level_ids: [school.school_levels.first.id],
          skill_ids: [create(:skill).id]
        }
      }
    
    expect(response).to have_http_status(:created)
    expect(Project.last.owner).to eq(teacher)
  end
end
```

---

## 10. Data Migration Considerations

### 10.1 No Schema Changes Needed! ✅

**Good news:** Your database schema is already well-designed for API consumption.

**Minor additions (optional):**
```ruby
# Add API-specific fields if needed
add_column :users, :api_token_version, :integer, default: 0
# For token invalidation on password change
```

### 10.2 Seed Data for Development

**Update seeds.rb to create API tokens:**
```ruby
# db/seeds.rb
if Rails.env.development?
  # Create API access for testing
  api_access = ApiAccess.create!(
    name: "Development Testing",
    token: "dev-token-123"
  )
  
  Company.first(3).each do |company|
    CompanyApiAccess.create!(
      api_access: api_access,
      company: company
    )
  end
  
  puts "API Token: #{api_access.token}"
end
```

---

## 11. Deployment Strategy

### 11.1 Infrastructure Setup

**Backend (Rails API):**
- Deploy to CleverCloud (existing)
- Environment variables: JWT_SECRET, FRONTEND_URL
- Enable CORS for frontend domains

**Frontend (React):**
- Deploy to Vercel/Netlify (recommended)
- OR Serve from Rails (public/ folder)
- Environment variables: REACT_APP_API_URL

### 11.2 CI/CD Pipeline

```yaml
# .github/workflows/api-tests.yml
name: API Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3.7
      - run: bundle install
      - run: bundle exec rspec spec/requests/api
      - run: bundle exec rake rswag:specs:swaggerize
      - uses: actions/upload-artifact@v2
        with:
          name: swagger-docs
          path: swagger/
```

---

## 12. Quick Start Implementation Guide

### Step-by-Step First Implementation

#### Step 1: Add Required Gems
```bash
# Add to Gemfile
bundle add jwt rack-cors active_model_serializers

# Install
bundle install
```

#### Step 2: Configure CORS
```bash
# Create config/initializers/cors.rb
# (content from section 3.2)
```

#### Step 3: Create JWT Service
```bash
# Create app/services/json_web_token.rb
# (content from section 5.2)
```

#### Step 4: Create API Base Controller
```bash
# Create app/controllers/api/v1/base_controller.rb
# (content from section 1.2)
```

#### Step 5: Create Auth Controller
```bash
# Create app/controllers/api/v1/auth_controller.rb
# (content from section 3.1)
```

#### Step 6: Create First Serializer
```bash
# Create app/serializers/user_serializer.rb
# (content from section 2.2)
```

#### Step 7: Test Authentication
```bash
# Start Rails server
rails s

# Test login endpoint
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@drakkar.io","password":"password"}'

# Should return JWT token
```

---

## 13. Dashboard-Specific Considerations

### 13.1 Company Dashboard Needs

**Critical Endpoints:**
```
GET    /api/v1/companies/:id                    # Company details
PATCH  /api/v1/companies/:id                    # Update company
GET    /api/v1/companies/:id/members            # List members
POST   /api/v1/companies/:id/members            # Invite member
PATCH  /api/v1/companies/:id/members/:user_id   # Update member permissions
DELETE /api/v1/companies/:id/members/:user_id   # Remove member
GET    /api/v1/companies/:id/projects           # Company projects
POST   /api/v1/companies/:id/projects           # Create project
GET    /api/v1/companies/:id/partnerships       # School partnerships
GET    /api/v1/companies/:id/stats              # Dashboard stats
```

**State Management Needs:**
- Current company context
- User permissions within company
- Pending approvals count
- Active contract status

### 13.2 School Dashboard Needs

**Critical Endpoints:**
```
GET    /api/v1/schools/:id                      # School details
PATCH  /api/v1/schools/:id                      # Update school
GET    /api/v1/schools/:id/members              # Teachers/staff
PATCH  /api/v1/schools/:id/members/:user_id     # Approve teacher
GET    /api/v1/schools/:id/levels               # Classes
POST   /api/v1/schools/:id/levels               # Create class
GET    /api/v1/schools/:id/projects             # School projects
GET    /api/v1/schools/:id/partnerships         # Company partnerships
GET    /api/v1/schools/:id/stats                # Dashboard stats
```

**State Management Needs:**
- Current school context
- User permissions within school
- Pending teacher approvals
- Class/level management

### 13.3 User Dashboard Needs

**Critical Endpoints:**
```
GET    /api/v1/users/me                         # Current user
PATCH  /api/v1/users/me                         # Update profile
GET    /api/v1/users/me/projects                # My projects
GET    /api/v1/users/me/badges                  # My badges
GET    /api/v1/users/me/skills                  # My skills
PATCH  /api/v1/users/me/skills                  # Update skills
GET    /api/v1/users/me/availability            # My availability
PATCH  /api/v1/users/me/availability            # Update availability
GET    /api/v1/projects                         # Available projects
GET    /api/v1/participants                     # Find participants
```

**State Management Needs:**
- User profile
- Organizations (schools/companies)
- Project participation
- Badge collection

### 13.4 Teacher Dashboard Needs

**Critical Endpoints:**
```
GET    /api/v1/teachers/dashboard               # Overview stats
GET    /api/v1/teachers/students                # My students
GET    /api/v1/teachers/classes                 # My classes
GET    /api/v1/teachers/projects                # Projects I own
POST   /api/v1/projects                         # Create project
GET    /api/v1/projects/:id/participants        # Project participants
POST   /api/v1/projects/:id/participants        # Add participant
PATCH  /api/v1/projects/:id/participants/:user_id # Approve participant
POST   /api/v1/badges                           # Assign badge
```

**State Management Needs:**
- Teacher's schools
- Classes taught
- Projects owned
- Pending participant requests

---

## 14. Recommended Implementation Order

### Priority 1: Authentication (Week 1)
**Why first:** All dashboards need this  
**Deliverable:** Login/logout working in React

### Priority 2: User Dashboard (Week 2-3)
**Why second:** Simplest, affects all users  
**Deliverable:** Profile management, view projects/badges

### Priority 3: Teacher Dashboard (Week 4-5)
**Why third:** Core user base, high value  
**Deliverable:** Project creation, student management

### Priority 4: School Dashboard (Week 6-7)
**Why fourth:** Admin features, less frequent use  
**Deliverable:** School management, teacher approval

### Priority 5: Company Dashboard (Week 8-9)
**Why last:** Smallest user base, similar to school  
**Deliverable:** Company management, partnerships

---

## 15. Risk Mitigation

### 15.1 Technical Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing web app | HIGH | Parallel development, feature flags |
| Performance degradation | MEDIUM | Load testing, caching, pagination |
| Authentication issues | HIGH | Thorough testing, gradual rollout |
| Data inconsistency | MEDIUM | Transaction wrapping, validation |
| CORS issues | LOW | Proper configuration, testing |

### 15.2 Business Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| User resistance to change | MEDIUM | Gradual migration, training |
| Feature parity gaps | HIGH | Comprehensive feature checklist |
| Data loss during migration | HIGH | Backups, rollback plan |
| Downtime | MEDIUM | Zero-downtime deployment |

---

## 16. Success Metrics

### 16.1 Technical Metrics

- [ ] 100% API endpoint coverage (vs current features)
- [ ] < 200ms average API response time
- [ ] 99.9% API uptime
- [ ] All rswag specs passing
- [ ] Zero security vulnerabilities

### 16.2 Business Metrics

- [ ] User adoption rate > 80% in 4 weeks
- [ ] User satisfaction score > 4/5
- [ ] Support tickets decrease (better UX)
- [ ] Feature usage increase (better discoverability)

---

## 17. Next Steps - What Should We Do First?

### Immediate Actions (This Week):

**1. Decide on Authentication Strategy**
- JWT tokens (recommended)
- Session-based (simpler but less flexible)
- OAuth2 (overkill for this use case)

**2. Choose Serialization Library**
- active_model_serializers (recommended)
- fast_jsonapi (faster, more complex)
- Jbuilder (already have, but verbose)

**3. Define API Versioning Strategy**
- Keep V1 for existing endpoints
- Create V3 for new comprehensive API
- OR expand V2 with proper namespacing

**4. Set Up Development Environment**
- Install required gems
- Configure CORS
- Create base controllers
- Test authentication

---

## 18. Detailed First Sprint Plan

### Sprint 1: Foundation (2 weeks)

#### Week 1: Backend Setup
**Day 1-2: Gems & Configuration**
- [ ] Add jwt, rack-cors, active_model_serializers
- [ ] Configure CORS
- [ ] Create JWT service
- [ ] Create Api::V1::BaseController

**Day 3-4: Authentication**
- [ ] Create AuthController
- [ ] Implement login/logout/refresh
- [ ] Add JWT to existing user sessions
- [ ] Write rswag specs for auth

**Day 5: Testing**
- [ ] Test authentication flow
- [ ] Verify CORS works
- [ ] Test with Postman
- [ ] Document auth flow

#### Week 2: Core Serializers & User API
**Day 1-2: Serializers**
- [ ] UserSerializer (with all associations)
- [ ] ProjectSerializer
- [ ] CompanySerializer
- [ ] SchoolSerializer
- [ ] BadgeSerializer

**Day 3-4: User API**
- [ ] GET /api/v1/users/me
- [ ] PATCH /api/v1/users/me
- [ ] GET /api/v1/users/me/projects
- [ ] GET /api/v1/users/me/badges
- [ ] Write rswag specs

**Day 5: Testing & Documentation**
- [ ] Test all user endpoints
- [ ] Generate swagger docs
- [ ] Update Postman collection
- [ ] Create API documentation

---

## 19. Code Examples - Complete Implementation

### Example 1: Complete User Profile API

**Controller:**
```ruby
# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < Api::V1::BaseController
  def me
    render json: current_user, 
           serializer: UserSerializer,
           include_badges: true,
           include_projects: true,
           include_skills: true,
           include_availability: true
  end
  
  def update
    if current_user.update(user_params)
      render json: current_user, serializer: UserSerializer
    else
      render json: { 
        errors: current_user.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  def upload_avatar
    if current_user.avatar.attach(params[:avatar])
      render json: { 
        avatar_url: rails_blob_url(current_user.avatar) 
      }, status: :ok
    else
      render json: { error: 'Upload failed' }, status: :unprocessable_entity
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :job, :birthday, :contact_email,
      :take_trainee, :propose_workshop, :show_my_skills,
      skill_ids: [],
      availability_attributes: [
        :id, :monday, :tuesday, :wednesday, :thursday, :friday, :other
      ]
    )
  end
end
```

**Serializer:**
```ruby
# app/serializers/user_serializer.rb
class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :first_name, :last_name, :full_name,
             :role, :job, :birthday, :certify, :admin, :avatar_url,
             :take_trainee, :propose_workshop, :show_my_skills
  
  has_many :skills, if: -> { instance_options[:include_skills] }
  has_many :badges_received, 
           serializer: UserBadgeSerializer, 
           if: -> { instance_options[:include_badges] }
  has_one :availability, if: -> { instance_options[:include_availability] }
  
  attribute :projects, if: -> { instance_options[:include_projects] }
  attribute :schools, if: -> { instance_options[:include_schools] }
  attribute :companies, if: -> { instance_options[:include_companies] }
  attribute :available_contexts, if: -> { instance_options[:include_contexts] }
  
  def full_name
    "#{object.first_name} #{object.last_name}"
  end
  
  def avatar_url
    return nil unless object.avatar.attached?
    Rails.application.routes.url_helpers.rails_blob_url(object.avatar, only_path: false)
  end
  
  def projects
    object.project_members.confirmed.map do |pm|
      ProjectSerializer.new(pm.project)
    end
  end
  
  def schools
    object.confirmed_schools.map { |s| SchoolSerializer.new(s) }
  end
  
  def companies
    object.confirmed_companies.map { |c| CompanySerializer.new(c) }
  end
  
  def available_contexts
    {
      user_dashboard: has_personal_dashboard?,
      teacher_dashboard: object.teacher?,
      schools: object.user_schools.confirmed.map do |us|
        {
          id: us.school.id,
          name: us.school.name,
          role: us.admin? ? 'admin' : 'member',
          permissions: {
            admin: us.admin?,
            owner: us.owner?,
            can_access_badges: us.can_access_badges?
          }
        }
      end,
      companies: object.user_company.confirmed.map do |uc|
        {
          id: uc.company.id,
          name: uc.company.name,
          role: uc.owner? ? 'owner' : (uc.admin? ? 'admin' : 'member'),
          permissions: {
            admin: uc.admin?,
            owner: uc.owner?,
            can_access_badges: uc.can_access_badges?,
            can_create_project: uc.can_create_project?
          }
        }
      end
    }
  end
  
  def has_personal_dashboard?
    # User has personal dashboard if they have a complete individual profile
    # Organization-only accounts (registered only for org management) don't have personal dashboard
    # For now, all users have personal dashboard unless explicitly flagged otherwise
    true
    # Future: could add `organization_only` boolean to User model if needed
  end
end
```

**rswag Spec:**
```ruby
# spec/requests/api/v1/users_spec.rb
require 'swagger_helper'

RSpec.describe 'API V1 Users', type: :request do
  path '/api/v1/users/me' do
    get 'Get current user profile' do
      tags 'Users'
      security [Bearer: []]
      produces 'application/json'
      
      response '200', 'successful' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            email: { type: :string },
            first_name: { type: :string },
            last_name: { type: :string },
            full_name: { type: :string },
            role: { type: :string },
            avatar_url: { type: :string, nullable: true },
            skills: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  name: { type: :string }
                }
              }
            }
          }
        
        let(:user) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{generate_jwt(user)}" }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['id']).to eq(user.id)
          expect(json['full_name']).to eq(user.full_name)
        end
      end
      
      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid-token' }
        run_test!
      end
    end
  end
  
  path '/api/v1/users/me' do
    patch 'Update current user profile' do
      tags 'Users'
      security [Bearer: []]
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          first_name: { type: :string },
          last_name: { type: :string },
          job: { type: :string },
          take_trainee: { type: :boolean },
          skill_ids: { type: :array, items: { type: :integer } }
        }
      }
      
      response '200', 'successful' do
        let(:user) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{generate_jwt(user)}" }
        let(:user_params) { { user: { first_name: 'Updated' } } }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['first_name']).to eq('Updated')
        end
      end
    end
  end
end
```

---

## 20. React Dashboard Example

### Example: User Dashboard with React Query

```typescript
// apps/user-dashboard/src/pages/Profile.tsx
import { useQuery, useMutation } from '@tanstack/react-query';
import { useCurrentUser, useUpdateUser } from '@kinship/api-client';

export const ProfilePage = () => {
  const { data: user, isLoading } = useCurrentUser();
  const updateUser = useUpdateUser();
  
  const handleSubmit = async (formData) => {
    try {
      await updateUser.mutateAsync(formData);
      toast.success('Profile updated!');
    } catch (error) {
      toast.error('Update failed');
    }
  };
  
  if (isLoading) return <Spinner />;
  
  return (
    <div>
      <h1>My Profile</h1>
      <ProfileForm 
        user={user} 
        onSubmit={handleSubmit}
        isLoading={updateUser.isLoading}
      />
      
      <BadgesList badges={user.badges_received} />
      <SkillsList skills={user.skills} />
      <AvailabilityEditor availability={user.availability} />
    </div>
  );
};
```

---

## 21. Monitoring & Observability

### 21.1 API Monitoring

```ruby
# Gemfile
gem 'skylight'  # Performance monitoring
gem 'sentry-ruby', '~> 5.0'  # Error tracking
gem 'sentry-rails'

# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.traces_sample_rate = 0.1
end
```

### 21.2 API Metrics

**Track:**
- Response times per endpoint
- Error rates
- Authentication failures
- Most used endpoints
- Slow queries (via Bullet)

---

## 22. Documentation for Frontend Team

### 22.1 Generate TypeScript Types

**Tool:** openapi-typescript

```bash
npm install -D openapi-typescript

# Generate types from swagger
npx openapi-typescript swagger/v1/swagger.json -o src/types/api.ts
```

**Result:**
```typescript
// Automatically generated types
export interface User {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  role: 'teacher' | 'tutor' | 'voluntary' | 'children';
  // ... all fields
}

export interface Project {
  id: number;
  title: string;
  // ... all fields
}
```

### 22.2 API Documentation Site

**Use rswag-ui:**
- Already configured at `/api-docs`
- Frontend team can browse all endpoints
- Try requests directly from browser
- See request/response examples

---

## 23. Final Recommendations

### DO:
✅ Start with authentication and user profile API  
✅ Use JWT for stateless authentication  
✅ Implement serializers for consistent JSON  
✅ Write rswag specs for every endpoint  
✅ Use feature flags for gradual rollout  
✅ Keep existing Rails views during transition  
✅ Implement proper error handling  
✅ Add rate limiting  
✅ Monitor API performance  

### DON'T:
❌ Remove Rails views until React is stable  
❌ Skip authentication/authorization  
❌ Forget CORS configuration  
❌ Ignore N+1 queries  
❌ Skip API versioning  
❌ Deploy without testing  
❌ Forget about file uploads  

---

## 24. Estimated Effort

### Backend API Development
- Foundation & Auth: 2 weeks
- Serializers: 1 week
- Company Dashboard API: 1 week
- School Dashboard API: 1 week
- User Dashboard API: 1 week
- Teacher Dashboard API: 1 week
- Testing & Documentation: 1 week

**Total Backend: 8 weeks**

### Frontend Development (Parallel)
- Setup & Authentication: 1 week
- User Dashboard: 2 weeks
- Teacher Dashboard: 2 weeks
- School Dashboard: 2 weeks
- Company Dashboard: 2 weeks
- Testing & Polish: 1 week

**Total Frontend: 10 weeks**

**Overall Timeline: 10-12 weeks with parallel development**

---

## Ready to Start?

I can guide you through:

1. **Setting up JWT authentication** (first priority)
2. **Creating the serializer layer** (second priority)
3. **Building specific dashboard APIs** (your choice which first)
4. **Writing comprehensive tests** (ongoing)
5. **React integration examples** (when ready)

**What would you like to tackle first?** 

I recommend we start with:
1. Add JWT authentication
2. Create AuthController
3. Test login/logout flow
4. Then move to User API

**Shall we begin with Step 1: JWT Authentication Setup?** 🚀

---

## 25. Context Switching - Implementation Summary

### 25.1 Backend Requirements

**1. Enhanced UserSerializer with `available_contexts`:**
```ruby
def available_contexts
  {
    user_dashboard: has_personal_dashboard?,
    teacher_dashboard: object.teacher?,
    schools: [...],  # All confirmed schools with permissions
    companies: [...]  # All confirmed companies with permissions
  }
end
```

**2. Login Response includes contexts:**
```json
{
  "token": "eyJhbGc...",
  "user": {
    "id": 123,
    "name": "Marie Dupont",
    "available_contexts": {
      "user_dashboard": true,
      "teacher_dashboard": true,
      "schools": [{"id": 1, "name": "Lycée Hugo", "permissions": {...}}],
      "companies": [{"id": 5, "name": "Tech Corp", "permissions": {...}}]
    }
  }
}
```

**3. Context Validation in Controllers:**
```ruby
before_action :verify_company_access!  # Checks user is member
before_action :verify_school_access!   # Checks user is member
```

**4. No Database Changes Needed:** ✅
- Existing relationships already support this
- UserSchool and UserCompany have all needed data

### 25.2 Frontend Requirements

**1. Single Unified React App:**
- All dashboards in one application
- Shared authentication state
- Context-based routing

**2. Context Provider:**
- Manages current context (user/teacher/company/school)
- Persists to localStorage
- Determines default context on login

**3. Context Switcher Component:**
- Dropdown in header/sidebar
- Shows all available contexts
- Indicates admin/owner roles
- One-click context switching

**4. Default Context Logic:**
```
Priority 1: User Dashboard (if available)
Priority 2: First School (if admin)
Priority 3: First Company (if admin)
Priority 4: First available organization
```

**5. Organization-Only Accounts:**
- Detected via `available_contexts.user_dashboard: false`
- Skip user dashboard, go to first organization
- Context switcher hides personal option

### 25.3 Key Benefits

✅ **Seamless UX** - No re-authentication needed  
✅ **Fast Switching** - Instant context changes  
✅ **Persistent State** - Remembers last context  
✅ **Smart Defaults** - User dashboard first (if available)  
✅ **Permission-Aware** - Shows admin badges  
✅ **Flexible** - Supports any number of organizations  
✅ **Backward Compatible** - Matches existing Kinship behavior  

### 25.4 Implementation Checklist

**Backend:**
- [ ] Add `available_contexts` method to UserSerializer
- [ ] Include contexts in login response
- [ ] Add context validation in organization controllers
- [ ] Test context switching with multiple organizations
- [ ] Document in rswag specs

**Frontend:**
- [ ] Create DashboardContext provider
- [ ] Implement context persistence (localStorage)
- [ ] Build ContextSwitcher component
- [ ] Add default context logic
- [ ] Create context-aware routing
- [ ] Build ContextGuard component
- [ ] Test with organization-only accounts

### 25.5 Example User Scenarios

**Scenario 1: Teacher with Personal Profile**
```
Marie (teacher) logs in
→ Has: User Dashboard, Teacher Dashboard, School Admin
→ Default: User Dashboard
→ Can switch to: Teacher Dashboard, "Lycée Hugo" School Dashboard
→ Context persisted: Returns to last used dashboard
```

**Scenario 2: Company-Only Admin**
```
Jean (company admin only) logs in
→ Has: Company Admin for "Tech Solutions"
→ No personal dashboard
→ Default: "Tech Solutions" Company Dashboard
→ Context switcher: Only shows company option
```

**Scenario 3: Multi-Organization Admin**
```
Sophie (super user) logs in
→ Has: User Dashboard, Admin of 2 schools, Admin of 3 companies
→ Default: User Dashboard
→ Context switcher shows:
  - Personal Dashboard
  - École Primaire (Admin)
  - Collège Central (Admin)
  - Tech Corp (Owner)
  - Innovation Assoc (Admin)
  - Digital Partners (Member)
→ Can switch between all 6 contexts instantly
```

---

## 26. Ready to Implement!

All documentation is complete. You now have:

✅ **Complete Architecture Understanding** (ARCHITECTURE_DEEP_DIVE.md)  
✅ **React Integration Strategy** (REACT_INTEGRATION_STRATEGY.md)  
✅ **Context Switching Explanation** (CONTEXT_SWITCHING_EXPLANATION.md)  
✅ **API Documentation** (swagger.yaml + postman_collection.json)  
✅ **Working rswag Specs** (18 passing tests)  

**Next Step:** Begin implementation with JWT Authentication

**Shall we start implementing?** 🚀

