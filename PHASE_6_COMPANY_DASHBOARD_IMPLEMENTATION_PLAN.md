# Phase 6: Company Dashboard API - Implementation Plan

## Executive Summary
Comprehensive implementation plan for Company Dashboard API, mirroring the School Dashboard structure with company-specific adaptations. This document outlines all controllers, endpoints, business rules, and implementation steps.

---

## 1. Architecture Overview

### Dashboard Access Control
**CRITICAL RULE**: Only **admin** and **superadmin** roles can access the Company Dashboard.

- ✅ **Dashboard Access**: admin, superadmin
- ❌ **NO Dashboard Access**: member, intervenant, referent (they use project/badge features directly)

### Controller Structure
```
Api::V1::Companies::BaseController (authorization)
├── Api::V1::CompaniesController (profile, stats)
├── Api::V1::Companies::MembersController (member management)
├── Api::V1::Companies::ProjectsController (project CRUD)
├── Api::V1::Companies::PartnershipsController (partnership management)
├── Api::V1::Companies::BranchesController (branch management)
├── Api::V1::Companies::BranchRequestsController (branch invitation workflow)
└── Api::V1::Companies::BadgesController (badge assignment)
```

---

## 2. Detailed Controller Specifications

### 2.1 Base Controller
**File**: `app/controllers/api/v1/companies/base_controller.rb`

**Purpose**: Shared authorization and helper methods

**Before Actions**:
- `set_company` - Load company from params[:company_id]
- `ensure_admin_or_superadmin` - Verify user is admin/superadmin

```ruby
class Api::V1::Companies::BaseController < Api::V1::BaseController
  before_action :set_company
  before_action :ensure_admin_or_superadmin
  
  private
  
  def set_company
    @company = Company.find(params[:company_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Not Found', message: 'Company not found' }, status: :not_found
  end
  
  def ensure_admin_or_superadmin
    user_company = current_user.user_companies.find_by(
      company: @company,
      status: :confirmed,
      role: [:admin, :superadmin]
    )
    
    unless user_company
      return render json: {
        error: 'Forbidden',
        message: 'Company Dashboard access requires Admin or Superadmin role'
      }, status: :forbidden
    end
    
    @current_user_company = user_company
  end
  
  def ensure_superadmin
    unless @current_user_company.superadmin?
      return render json: {
        error: 'Forbidden',
        message: 'This action requires Superadmin role'
      }, status: :forbidden
    end
  end
end
```

---

### 2.2 Companies Controller
**File**: `app/controllers/api/v1/companies_controller.rb`

#### Endpoints

##### **GET /api/v1/companies/:id**
Get company profile

**Response**:
```json
{
  "id": 1,
  "name": "Acme Corp",
  "siret_number": "12345678901234",
  "city": "Paris",
  "zip_code": "75001",
  "address": "123 Main St",
  "email": "contact@acme.com",
  "website": "https://acme.com",
  "referent_phone_number": "0123456789",
  "description": "Leading tech company",
  "company_type": "PME",
  "logo_url": "https://...",
  "status": "confirmed",
  "is_branch": false,
  "is_main_company": true,
  "parent_company": null,
  "share_members_with_branches": false,
  "created_at": "2025-01-01T00:00:00.000Z"
}
```

---

##### **PATCH /api/v1/companies/:id**
Update company profile

**Request Body**:
```json
{
  "company": {
    "name": "Acme Corporation",
    "city": "Lyon",
    "zip_code": "69001",
    "address": "456 New St",
    "email": "info@acme.com",
    "website": "https://acme.com",
    "referent_phone_number": "0198765432",
    "description": "Updated description"
  }
}
```

**Business Rules**:
- Only admin/superadmin can update
- Cannot update `siret_number`, `status`, `parent_company_id` via this endpoint
- Logo update handled separately via ActiveStorage

---

##### **GET /api/v1/companies/:id/stats**
Get dashboard statistics

**Response**:
```json
{
  "overview": {
    "total_members": 50,
    "total_projects": 25,
    "active_partnerships": 8,
    "active_contract": true,
    "is_branch": false,
    "is_main_company": true
  },
  "members_by_role": {
    "superadmin": 1,
    "admin": 2,
    "referent": 10,
    "intervenant": 15,
    "member": 22
  },
  "projects_by_status": {
    "in_progress": 15,
    "completed": 8,
    "cancelled": 2
  },
  "badges_assigned": {
    "total": 120,
    "this_month": 15
  },
  "branches": {
    "total_branches": 3,
    "branch_members": 80,
    "branch_projects": 15
  }
}
```

**Business Rules**:
- If main company, include branch statistics
- Count only confirmed members
- Badge stats require active contract

---

### 2.3 Members Controller
**File**: `app/controllers/api/v1/companies/members_controller.rb`

#### Endpoints

##### **GET /api/v1/companies/:company_id/members**
List all company members

**Query Parameters**:
- `page` (default: 1)
- `per_page` (default: 12)
- `role` (member, intervenant, referent, admin, superadmin)
- `status` (pending, confirmed)
- `search` (name or email)

**Response**:
```json
{
  "data": [
    {
      "id": 1,
      "full_name": "John Doe",
      "email": "john@example.com",
      "role_in_system": "teacher",
      "role_in_company": "referent",
      "status": "confirmed",
      "avatar_url": "https://...",
      "joined_at": "2025-01-01T00:00:00.000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 50,
    "per_page": 12
  }
}
```

---

##### **POST /api/v1/companies/:company_id/members**
Invite/add a member to company

**Superadmin Only**

**Request Body (3 scenarios)**:

**Scenario 1: Existing User**
```json
{
  "email": "existing@example.com",
  "role": "referent"
}
```

**Scenario 2: New User with Email**
```json
{
  "email": "newuser@example.com",
  "first_name": "Marie",
  "last_name": "Dupont",
  "user_role": "teacher",
  "role": "intervenant"
}
```

**Scenario 3: New User without Email (Claim Link)**
```json
{
  "first_name": "Pierre",
  "last_name": "Martin",
  "birthday": "1990-05-15",
  "user_role": "voluntary",
  "role": "member"
}
```

**Response**:
```json
{
  "message": "Invitation sent successfully",
  "data": {
    "id": 10,
    "full_name": "Marie Dupont",
    "email": "newuser@example.com",
    "role_in_system": "teacher",
    "role_in_company": "intervenant",
    "status": "pending",
    "avatar_url": null,
    "joined_at": "2025-10-24T12:00:00.000Z"
  },
  "invitation_method": "email" 
}
```

**Business Rules**:
- **Superadmin Only**: Only superadmins can assign roles
- **One Superadmin Rule**: Cannot assign superadmin role (only one per company)
- **Email Notifications**: Send appropriate email based on scenario
- **Claim Link**: Generate for users without email (30-day expiry)

---

##### **PATCH /api/v1/companies/:company_id/members/:id**
Update member role

**Superadmin Only**

**Request Body**:
```json
{
  "role": "admin"
}
```

**Business Rules**:
- Cannot change own role
- Cannot assign superadmin role
- Cannot change superadmin's role

---

##### **DELETE /api/v1/companies/:company_id/members/:id**
Remove member from company

**Superadmin Only**

**Business Rules**:
- Cannot remove superadmin
- Cannot remove self
- Cascade behavior: member loses access to company projects

---

### 2.4 Projects Controller
**File**: `app/controllers/api/v1/companies/projects_controller.rb`

#### Endpoints

##### **GET /api/v1/companies/:company_id/projects**
List company projects

**Query Parameters**:
- `include_branches` (true/false) - Include branch projects (main companies only)
- `status` (in_progress, completed, cancelled)
- `search` (project title)

**Response**:
```json
{
  "data": [
    {
      "id": 1,
      "title": "Innovation Project",
      "description": "...",
      "status": "in_progress",
      "start_date": "2025-01-01",
      "end_date": "2025-12-31",
      "private": false,
      "owner": {
        "id": 5,
        "name": "John Doe"
      },
      "companies": [
        {"id": 1, "name": "Acme Corp"}
      ],
      "members_count": 15,
      "created_at": "2025-01-01T00:00:00.000Z"
    }
  ]
}
```

---

##### **POST /api/v1/companies/:company_id/projects**
Create a new project

**Roles**: referent, admin, superadmin

**Request Body**:
```json
{
  "project": {
    "title": "New Project",
    "description": "Project description",
    "start_date": "2025-11-01",
    "end_date": "2025-12-31",
    "status": "in_progress",
    "private": false,
    "participants_number": 20
  }
}
```

**Business Rules**:
- Automatically associates with the company
- Creator becomes project owner
- Default: `private: false`, `status: in_progress`

---

### 2.5 Partnerships Controller
**File**: `app/controllers/api/v1/companies/partnerships_controller.rb`

**Superadmin Only** for all actions

#### Endpoints

##### **GET /api/v1/companies/:company_id/partnerships**
List partnerships

**Query Parameters**:
- `status` (pending, confirmed, rejected)
- `partnership_type` (bilateral, multilateral)

---

##### **POST /api/v1/companies/:company_id/partnerships**
Create partnership request

**Request Body**:
```json
{
  "partnership_type": "bilateral",
  "name": "Tech Partnership",
  "description": "Collaboration for innovation",
  "partner_company_ids": [2],
  "partner_school_ids": [1],
  "share_members": false,
  "share_projects": true,
  "has_sponsorship": true,
  "initiator_role": "sponsor",
  "partner_role": "beneficiary"
}
```

**Email Sent**: Partnership request to partner admins

---

##### **PATCH /api/v1/companies/:company_id/partnerships/:id**
Update partnership settings

---

##### **PATCH /api/v1/companies/:company_id/partnerships/:id/confirm**
Confirm partnership request

**Email Sent**: Confirmation to initiator admins

---

##### **PATCH /api/v1/companies/:company_id/partnerships/:id/reject**
Reject partnership request

**Email Sent**: Rejection to initiator admins

---

##### **DELETE /api/v1/companies/:company_id/partnerships/:id**
Leave/delete partnership

---

### 2.6 Branches Controller
**File**: `app/controllers/api/v1/companies/branches_controller.rb`

**Superadmin Only** for all actions

#### Endpoints

##### **GET /api/v1/companies/:company_id/branches**
List branches

**Response**:
```json
{
  "data": [
    {
      "id": 5,
      "name": "Acme Branch Lyon",
      "city": "Lyon",
      "zip_code": "69001",
      "members_count": 15,
      "projects_count": 8,
      "created_at": "2025-01-01T00:00:00.000Z"
    }
  ],
  "parent_company": {
    "id": 1,
    "name": "Acme Corp"
  },
  "share_members_with_branches": false
}
```

---

##### **POST /api/v1/companies/:company_id/branches/invite**
Invite company to become a branch

**Request Body**:
```json
{
  "child_company_id": 5
}
```

**Email Sent**: Branch invitation to child company admins

---

##### **PATCH /api/v1/companies/:company_id/branches/settings**
Update branch settings

**Request Body**:
```json
{
  "share_members_with_branches": true
}
```

---

### 2.7 Branch Requests Controller
**File**: `app/controllers/api/v1/companies/branch_requests_controller.rb`

**Superadmin Only** for all actions

#### Endpoints

##### **GET /api/v1/companies/:company_id/branch_requests**
List branch requests

**Query Parameters**:
- `status` (pending, confirmed, rejected)
- `direction` (sent, received)

---

##### **POST /api/v1/companies/:company_id/branch_requests**
Request to become a branch

**Request Body**:
```json
{
  "parent_company_id": 1
}
```

**Email Sent**: Branch request to parent company admins

---

##### **PATCH /api/v1/companies/:company_id/branch_requests/:id/confirm**
Confirm branch request

**Email Sent**: Confirmation to initiator admins

---

##### **PATCH /api/v1/companies/:company_id/branch_requests/:id/reject**
Reject branch request

**Email Sent**: Rejection to initiator admins

---

##### **DELETE /api/v1/companies/:company_id/branch_requests/:id**
Cancel branch request (initiator only, pending only)

---

### 2.8 Badges Controller
**File**: `app/controllers/api/v1/companies/badges_controller.rb`

#### Endpoints

##### **POST /api/v1/companies/:company_id/badges/assign**
Assign badges to users

**Roles**: intervenant, referent, admin, superadmin

**Request Body**:
```json
{
  "badge_id": 1,
  "recipient_ids": [4, 5, 6],
  "project_title": "Innovation Challenge",
  "project_description": "Excellence in innovation",
  "comment": "Outstanding performance",
  "badge_skill_ids": [1, 2]
}
```

**Business Rules**:
- **Active Contract Required**: Company must have active contract
- Sender must be intervenant/referent/admin/superadmin
- Comment required for level 3+ badges
- Document proof required for level 2+ badges

---

##### **GET /api/v1/companies/:company_id/badges/assigned**
List badges assigned by company members

**Query Parameters**:
- `sender_id` (filter by assigner)
- `badge_series` (filter by badge series)

---

## 3. Routes Configuration

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    # Company Dashboard API (Phase 6)
    resources :companies, only: [:show, :update] do
      member do
        get :stats
      end
      
      # Members
      resources :members, controller: 'companies/members', only: [:index, :create, :update, :destroy]
      
      # Projects
      resources :projects, controller: 'companies/projects', only: [:index, :create]
      
      # Partnerships
      resources :partnerships, controller: 'companies/partnerships', only: [:index, :create, :update, :destroy] do
        member do
          patch :confirm
          patch :reject
        end
      end
      
      # Branches
      member do
        get 'branches', to: 'companies/branches#index'
        post 'branches/invite', to: 'companies/branches#invite'
        patch 'branches/settings', to: 'companies/branches#settings'
      end
      
      # Branch Requests
      resources :branch_requests, controller: 'companies/branch_requests', only: [:index, :create, :destroy] do
        member do
          patch :confirm
          patch :reject
        end
      end
      
      # Badges
      member do
        post 'badges/assign', to: 'companies/badges#assign'
        get 'badges/assigned', to: 'companies/badges#assigned'
      end
    end
  end
end
```

---

## 4. Email Notifications

### Existing Mailers to Use
- **PartnershipMailer** (already created in Phase 5)
  - `partnership_request_created`
  - `partnership_confirmed`
  - `partnership_rejected`

- **BranchRequestMailer** (already created in Phase 5)
  - `branch_request_created`
  - `branch_request_confirmed`
  - `branch_request_rejected`

### Integration Points
All company controllers will use the same mailers as schools, since the mailers are already designed to work with polymorphic organizations.

---

## 5. Business Rules Summary

### Access Control
1. **Dashboard Access**: admin, superadmin ONLY
2. **Member Management**: superadmin ONLY
3. **Project Creation**: referent, admin, superadmin
4. **Badge Assignment**: intervenant, referent, admin, superadmin (with active contract)
5. **Partnership Management**: superadmin ONLY
6. **Branch Management**: superadmin ONLY

### Superadmin Rules
1. **One Superadmin**: Only one superadmin per company
2. **Cannot Delete**: Superadmin cannot be removed
3. **Cannot Assign**: Regular admins cannot assign superadmin role
4. **Self-Protection**: Superadmin cannot change own role or remove self

### Branch Rules
1. **Hierarchy**: 1-level only (main company → branch companies)
2. **Main Company Visibility**: Can see all branch projects
3. **Member Sharing**: Controlled by `share_members_with_branches` flag (default: false)
4. **Bidirectional Requests**: Either parent or child can initiate

### Contract Rules
1. **Badge Assignment**: Requires active contract
2. **Contract Check**: Validate before allowing badge operations

---

## 6. Implementation Steps

### Step 1: Base Controller & Routes
- [ ] Create `Companies::BaseController`
- [ ] Add routes in `config/routes.rb`
- [ ] Test authorization logic

### Step 2: Companies Controller
- [ ] Implement `show`, `update`, `stats`
- [ ] Add branch statistics for main companies
- [ ] Test with curl

### Step 3: Members Controller
- [ ] Implement `index`, `create`, `update`, `destroy`
- [ ] Add 3 invitation scenarios
- [ ] Integrate email notifications
- [ ] Test with curl

### Step 4: Projects Controller
- [ ] Implement `index`, `create`
- [ ] Add branch-aware queries
- [ ] Test with curl

### Step 5: Partnerships Controller
- [ ] Implement all CRUD + confirm/reject
- [ ] Integrate existing PartnershipMailer
- [ ] Test with curl

### Step 6: Branches & Branch Requests Controllers
- [ ] Implement all endpoints
- [ ] Integrate existing BranchRequestMailer
- [ ] Test with curl

### Step 7: Badges Controller
- [ ] Implement assign & assigned
- [ ] Add active contract validation
- [ ] Test with curl

### Step 8: Testing & Documentation
- [ ] Create comprehensive test data
- [ ] Test all endpoints with Postman
- [ ] Update Postman collection
- [ ] Create completion summary
- [ ] Commit and push

---

## 7. Differences from School Dashboard

### Similarities
- Same authorization pattern (admin/superadmin only)
- Same branch system
- Same partnership system
- Same email notifications
- Same member invitation workflows

### Key Differences
1. **No Classes/Levels**: Companies don't have school levels
2. **Different Roles**: member, intervenant, referent, admin, superadmin (vs. school roles)
3. **SIRET Number**: Company-specific field
4. **Company Type**: Linked to `company_types` table
5. **Project Association**: Direct via `project_companies` (no intermediate school_levels)

---

## 8. Questions for Clarification

### Question 1: Project Creation Roles
**Current Plan**: referent, admin, superadmin can create projects (based on `UserCompany#can_create_project?`)

**Confirm**: Is this correct, or should we restrict to admin/superadmin only?

### Question 2: Badge Assignment Roles
**Current Plan**: intervenant, referent, admin, superadmin can assign badges (based on `UserCompany#can_assign_badges?`)

**Confirm**: Is this correct for the Company Dashboard?

### Question 3: Member Invitation Email
**Current Plan**: Use the same 3-scenario invitation workflow as School Dashboard

**Confirm**: Is this appropriate for companies, or do companies have different onboarding requirements?

### Question 4: Default Project Values
**Current Plan**: Same as schools (`private: false`, `status: in_progress`)

**Confirm**: Are company projects public by default, or should they default to private?

---

## 9. Total Endpoints

### Company Dashboard API: **31 endpoints**
- **Profile & Stats**: 2 (show, stats)
- **Members**: 4 (index, create, update, destroy)
- **Projects**: 2 (index, create)
- **Partnerships**: 6 (list, create, update, destroy, confirm, reject)
- **Branches**: 3 (list, invite, settings)
- **Branch Requests**: 5 (list, create, confirm, reject, destroy)
- **Badges**: 2 (assign, assigned)
- **Company Update**: 1 (update profile)

---

## 10. Success Criteria

✅ All 31 endpoints implemented and tested  
✅ Admin/Superadmin access control enforced  
✅ Email notifications integrated  
✅ Branch system working  
✅ Partnership system working  
✅ Badge assignment with contract validation  
✅ Postman collection updated  
✅ Documentation completed  
✅ All changes committed and pushed  

---

## Next Steps

1. **Review this plan** and answer the 4 clarification questions
2. **Approve implementation** to proceed
3. **Create test data** for comprehensive testing
4. **Implement controllers** following the plan
5. **Test all endpoints** with curl and Postman
6. **Update documentation** and commit

**Estimated Time**: 4-6 hours for full implementation and testing

---

**Status**: ⏳ Awaiting approval and clarification

