# Context Switching - Multi-Dashboard User Experience

## The Requirement

A single user (e.g., `john@example.com`) can have **multiple contexts/roles simultaneously**:

**Example User Journey:**
```
John Doe (john@example.com)
├─ Individual User Context
│  └─ View: User Dashboard (personal profile, my projects, badges)
│
├─ Teacher at "Lycée Victor Hugo"
│  └─ View: Teacher Dashboard (my classes, my students, create projects)
│
├─ Admin of "Tech Solutions Company"
│  └─ View: Company Dashboard (manage company, members, partnerships)
│
└─ Admin of "Innovation Association" (another company)
   └─ View: Company Dashboard (different company context)
```

**Key Point:** John should **switch contexts without re-authenticating** - the JWT token remains the same, but the UI context changes.

---

## What This Implies

### 1. Single Authentication, Multiple Contexts
```javascript
// User logs in once
POST /api/v1/auth/login
→ Returns JWT token

// Token contains user identity
JWT payload: { user_id: 123, exp: ... }

// User switches dashboard
// Same token, different API calls based on context
```

### 2. Context-Aware API Calls

**Current User Endpoint:**
```javascript
GET /api/v1/users/me
→ Returns user with ALL contexts:
{
  id: 123,
  name: "John Doe",
  role: "teacher",
  contexts: {
    schools: [
      { id: 1, name: "Lycée Victor Hugo", role: "teacher", admin: true }
    ],
    companies: [
      { id: 5, name: "Tech Solutions", role: "admin", admin: true },
      { id: 8, name: "Innovation Assoc", role: "member", admin: true }
    ]
  }
}
```

**Context-Specific Endpoints:**
```javascript
// When in Company Dashboard for company_id=5
GET /api/v1/companies/5/dashboard
GET /api/v1/companies/5/members
GET /api/v1/companies/5/projects

// When in School Dashboard for school_id=1
GET /api/v1/schools/1/dashboard
GET /api/v1/schools/1/members
GET /api/v1/schools/1/levels

// When in User Dashboard (personal context)
GET /api/v1/users/me/projects
GET /api/v1/users/me/badges
```

### 3. Frontend State Management

**React Context/State:**
```typescript
interface UserContext {
  user: User;
  currentContext: 'user' | 'teacher' | 'company' | 'school';
  currentOrganizationId?: number; // If in org context
  availableContexts: {
    schools: School[];      // Schools where user is member
    companies: Company[];   // Companies where user is member
  };
}

// Context switcher component
<ContextSwitcher 
  contexts={user.availableContexts}
  currentContext={currentContext}
  onSwitch={(newContext) => navigate(`/${newContext}-dashboard`)}
/>
```

---

## How We Achieve This

### Backend Changes

#### 1. Enhanced User Serializer
```ruby
class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :first_name, :last_name, :role,
             :available_contexts
  
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
            can_access_badges: us.can_access_badges?
          }
        }
      end,
      companies: object.user_company.confirmed.map do |uc|
        {
          id: uc.company.id,
          name: uc.company.name,
          role: uc.admin? ? 'admin' : 'member',
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
    # User has personal dashboard if they have individual profile
    # (not just organization-only account)
    object.role.present? && !organization_only_account?
  end
  
  def organization_only_account?
    # Check if this is an organization-only account
    # (registered only for company/school management, no personal profile)
    false # Most users have personal dashboard
    # Could add a flag to User model if needed: organization_only boolean
  end
end
```

#### 2. Context Validation in Controllers
```ruby
# app/controllers/api/v1/companies_controller.rb
class Api::V1::CompaniesController < Api::V1::BaseController
  before_action :set_company
  before_action :verify_company_access!
  
  def show
    render json: @company, serializer: CompanySerializer
  end
  
  private
  
  def set_company
    @company = Company.find(params[:id])
  end
  
  def verify_company_access!
    # Check if current_user is member of this company
    user_company = current_user.user_company.find_by(company: @company)
    
    unless user_company&.confirmed?
      render json: { 
        error: 'Not a member of this company',
        available_companies: current_user.confirmed_companies.pluck(:id)
      }, status: :forbidden
    end
    
    # Store context for authorization
    @current_user_company = user_company
  end
end
```

#### 3. Context-Aware Policies
```ruby
# app/policies/company_policy.rb
class CompanyPolicy < ApplicationPolicy
  def show?
    # User must be member of this company
    user.user_company.exists?(company: record, status: :confirmed)
  end
  
  def update?
    # User must be admin of this company
    user.company_admin?(record)
  end
  
  def manage_members?
    user.company_admin?(record)
  end
  
  class Scope < Scope
    def resolve
      # Only return companies where user is confirmed member
      scope.joins(:user_companies)
           .where(user_companies: { user_id: user.id, status: :confirmed })
    end
  end
end
```

### Frontend Changes

#### 1. Context Provider
```typescript
// apps/shared/contexts/UserContext.tsx
interface UserContextType {
  user: User;
  currentContext: DashboardContext;
  currentOrganization?: Organization;
  switchContext: (context: DashboardContext, orgId?: number) => void;
  availableContexts: AvailableContexts;
}

export const UserProvider = ({ children }) => {
  const [currentContext, setCurrentContext] = useState<DashboardContext>('user');
  const [currentOrgId, setCurrentOrgId] = useState<number>();
  
  const { data: user } = useCurrentUser();
  
  const switchContext = (context: DashboardContext, orgId?: number) => {
    setCurrentContext(context);
    setCurrentOrgId(orgId);
    
    // Navigate to appropriate dashboard
    if (context === 'company' && orgId) {
      navigate(`/company-dashboard/${orgId}`);
    } else if (context === 'school' && orgId) {
      navigate(`/school-dashboard/${orgId}`);
    } else if (context === 'teacher') {
      navigate('/teacher-dashboard');
    } else {
      navigate('/user-dashboard');
    }
  };
  
  return (
    <UserContext.Provider value={{
      user,
      currentContext,
      currentOrganization: getCurrentOrg(user, currentContext, currentOrgId),
      switchContext,
      availableContexts: user?.available_contexts
    }}>
      {children}
    </UserContext.Provider>
  );
};
```

#### 2. Context Switcher Component
```typescript
// apps/shared/components/ContextSwitcher.tsx
export const ContextSwitcher = () => {
  const { user, currentContext, switchContext, availableContexts } = useUserContext();
  
  return (
    <Menu>
      {availableContexts.user_dashboard && (
        <MenuItem onClick={() => switchContext('user')}>
          <PersonIcon />
          Personal Dashboard
        </MenuItem>
      )}
      
      {availableContexts.teacher_dashboard && (
        <MenuItem onClick={() => switchContext('teacher')}>
          <SchoolIcon />
          Teacher Dashboard
        </MenuItem>
      )}
      
      {availableContexts.schools.map(school => (
        <MenuItem key={school.id} onClick={() => switchContext('school', school.id)}>
          <SchoolIcon />
          {school.name}
          {school.permissions.admin && <AdminBadge />}
        </MenuItem>
      ))}
      
      {availableContexts.companies.map(company => (
        <MenuItem key={company.id} onClick={() => switchContext('company', company.id)}>
          <BusinessIcon />
          {company.name}
          {company.permissions.admin && <AdminBadge />}
        </MenuItem>
      ))}
    </Menu>
  );
};
```

#### 3. Protected Routes with Context
```typescript
// apps/company-dashboard/src/App.tsx
export const CompanyDashboardApp = () => {
  const { currentContext, currentOrganization } = useUserContext();
  
  // Redirect if not in company context
  if (currentContext !== 'company') {
    return <Navigate to="/user-dashboard" />;
  }
  
  // Redirect if no company selected
  if (!currentOrganization) {
    return <CompanySelector />;
  }
  
  return (
    <Routes>
      <Route path="/" element={<CompanyDashboard company={currentOrganization} />} />
      <Route path="/members" element={<MemberManagement company={currentOrganization} />} />
      <Route path="/projects" element={<ProjectList company={currentOrganization} />} />
    </Routes>
  );
};
```

---

## What This Changes in Our Strategy

### 1. Authentication Response Enhancement
**Before:**
```json
POST /api/v1/auth/login
{
  "token": "eyJhbGc...",
  "user": { "id": 123, "name": "John" }
}
```

**After:**
```json
POST /api/v1/auth/login
{
  "token": "eyJhbGc...",
  "user": {
    "id": 123,
    "name": "John Doe",
    "role": "teacher",
    "available_contexts": {
      "user_dashboard": true,
      "teacher_dashboard": true,
      "schools": [
        {
          "id": 1,
          "name": "Lycée Victor Hugo",
          "role": "admin",
          "permissions": { "admin": true, "can_access_badges": true }
        }
      ],
      "companies": [
        {
          "id": 5,
          "name": "Tech Solutions",
          "role": "admin",
          "permissions": { "admin": true, "owner": false, "can_create_project": true }
        }
      ]
    }
  }
}
```

### 2. Dashboard Routing Structure
**Before (separate apps):**
```
/company-dashboard/
/school-dashboard/
/user-dashboard/
/teacher-dashboard/
```

**After (context-aware):**
```
/dashboard/user                    # Personal context
/dashboard/teacher                 # Teacher context
/dashboard/school/:school_id       # School context
/dashboard/company/:company_id     # Company context
```

### 3. API Authorization Pattern
**No change needed!** Your current authorization already supports this:
```ruby
# Existing code in User model already handles this:
def schools_admin
  user_schools.where(admin: true, status: :confirmed).map(&:school)
end

def companies_admin
  user_company.where(admin: true, status: :confirmed).map(&:company)
end
```

### 4. Frontend State Management
**Add to React Query cache:**
```typescript
// Cache user contexts
const { data: userContexts } = useQuery({
  queryKey: ['userContexts'],
  queryFn: () => api.get('/users/me'),
  staleTime: 5 * 60 * 1000, // 5 minutes
});

// Current context stored in local state or URL
const [currentContext, setCurrentContext] = useLocalStorage('current-context', 'user');
const [currentOrgId, setCurrentOrgId] = useLocalStorage('current-org-id', null);
```

---

## Good News: Minimal Strategy Changes!

### What Stays the Same
✅ JWT authentication approach  
✅ API endpoint structure  
✅ Serialization strategy  
✅ Authorization with Pundit  
✅ Timeline and phases  

### What Changes

#### 1. Add Context Switcher API
```ruby
# New endpoint
GET /api/v1/users/me/contexts
→ Returns all available contexts for current user
```

#### 2. Enhance User Serializer
```ruby
# Add available_contexts attribute
# (shown above)
```

#### 3. Frontend: Single App with Context Routing
**Instead of 4 separate apps, we could have:**
- **Option A:** 4 separate apps that share auth state (via localStorage)
- **Option B:** 1 unified app with context-based routing (cleaner) ✅ CHOSEN

**Unified App Structure:**
```
kinship-frontend/
├── src/
│   ├── contexts/
│   │   └── UserContext.tsx (manages current context)
│   ├── dashboards/
│   │   ├── user/
│   │   ├── teacher/
│   │   ├── company/
│   │   └── school/
│   ├── shared/
│   │   └── ContextSwitcher.tsx
│   └── App.tsx (routing based on context)
```

#### 4. Add Context Validation Middleware
```ruby
# app/controllers/concerns/context_validator.rb
module ContextValidator
  extend ActiveSupport::Concern
  
  def validate_company_context!(company_id)
    unless current_user.user_company.exists?(company_id: company_id, status: :confirmed)
      render json: { 
        error: 'Invalid company context',
        available_companies: current_user.confirmed_companies.pluck(:id)
      }, status: :forbidden
    end
  end
  
  def validate_school_context!(school_id)
    unless current_user.user_schools.exists?(school_id: school_id, status: :confirmed)
      render json: { 
        error: 'Invalid school context',
        available_schools: current_user.confirmed_schools.pluck(:id)
      }, status: :forbidden
    end
  end
end
```

---

## UX Flow Example

### User Login
```
1. User logs in → Receives JWT token
2. Frontend calls GET /api/v1/users/me
3. Response shows available contexts:
   - User Dashboard (if has personal profile)
   - Teacher Dashboard (if teacher role)
   - School: "Lycée Victor Hugo" (admin)
   - Company: "Tech Solutions" (admin)
   - Company: "Innovation Assoc" (member)

4. Frontend shows context switcher in header/sidebar
5. User selects "Tech Solutions Company"
6. Frontend navigates to /dashboard/company/5
7. All API calls use company_id=5 in URLs
8. Same JWT token, no re-authentication
```

### Context Switching
```
User in Company Dashboard (company_id=5)
  ↓ Clicks context switcher
  ↓ Selects "Personal Dashboard"
  ↓ Navigate to /dashboard/user
  ↓ API calls change to /api/v1/users/me/*
  ↓ Same JWT token still valid
```

### Special Case: Organization-Only Accounts
```
User registered only as company admin (no personal profile)
  ↓ Logs in
  ↓ GET /api/v1/users/me returns:
     {
       available_contexts: {
         user_dashboard: false,  ← No personal dashboard
         teacher_dashboard: false,
         companies: [{ id: 5, name: "Tech Solutions", ... }]
       }
     }
  ↓ Frontend detects no user_dashboard
  ↓ Redirects to first available context (company/school)
  ↓ Context switcher only shows organization contexts
```

---

## What I'll Update in the Strategy

### Sections to Add/Modify

1. **Strategy Overview:**
   - Add "Multi-Context User Experience" section
   - Explain single login, multiple contexts
   - Add special case for organization-only accounts

2. **Authentication Section:**
   - Enhance login response with contexts
   - Add context validation patterns
   - Add default context logic

3. **Frontend Architecture:**
   - Single unified app (Option B)
   - Context state management with persistence
   - Context switcher component
   - Default to user dashboard (if available)

4. **API Endpoints:**
   - Add `/users/me/contexts` endpoint
   - Context validation in all org endpoints
   - Return available contexts in login response

5. **React Examples:**
   - Context provider implementation
   - Context switcher component
   - Protected routes with context
   - Default context selection logic

6. **Testing:**
   - Test context switching
   - Test permission boundaries
   - Test organization-only accounts

---

## Implementation Decisions

### ✅ Confirmed Choices

1. **Frontend Structure:** Option B - Single unified React app
   - Cleaner architecture
   - Shared components and state
   - Easier maintenance

2. **Context Persistence:** Yes
   - Store last context in localStorage
   - Better UX on return visits

3. **Default Context:** User Dashboard (if available)
   - Fallback to first available organization if no personal dashboard
   - Most intuitive for majority of users

4. **Organization-Only Accounts:** Supported
   - Detect via `available_contexts.user_dashboard: false`
   - Redirect to first organization context
   - Hide personal dashboard option in switcher

---

## Implementation Impact

### Complexity: LOW ✅
- Your backend already supports this (user has multiple schools/companies)
- Just need to expose it properly in API
- Frontend handles context switching

### Timeline: No Change ✅
- Same 8-12 weeks
- Context switching is part of normal development

### Benefits
✅ Better UX (no re-login)  
✅ Faster context switching  
✅ Single token management  
✅ Unified user experience  
✅ Matches existing Kinship behavior  
✅ Supports organization-only accounts  

