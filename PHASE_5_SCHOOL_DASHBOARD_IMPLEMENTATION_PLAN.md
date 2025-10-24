# Phase 5: School Dashboard API - Complete Implementation Plan

**Date:** October 24, 2025  
**Status:** 📋 Awaiting Approval  
**Estimated Time:** 12-16 hours (Week 7)

---

## 🎯 Executive Summary

Implement a comprehensive School Dashboard API following our established patterns from User Dashboard (Phase 3) and Teacher Dashboard (Phase 4). The School Dashboard will enable school administrators and staff to manage their institution, including:

- School profile and settings
- Member management (teachers, staff)
- Class/level management  
- Project management
- Partnership management (with companies/schools)
- **Branch management (parent/child school relationships)**
- Badge assignment
- Statistics and dashboard overview

---

## 📋 Prerequisites

### ✅ Already Implemented:
- JWT Authentication (Phase 1)
- Base API Controllers (Phase 1)
- Core Serializers (Phase 2)
- Role-based permissions (`UserSchool` with roles)
- Branch System (Change #4)
- Partnership System (Change #5)
- Policy framework (Pundit)

### 🔍 Key Models:
- `School` - Main school entity with branch support
- `UserSchool` - Membership with roles: `member`, `intervenant`, `referent`, `admin`, `superadmin`
- `SchoolLevel` - Classes/levels
- `BranchRequest` - Branch invitation/request workflow
- `Partnership` - Multi-party partnership system
- `Contract` - Active contract required for badge assignment

---

## 🏗️ Architecture Overview

### Controller Structure (Following Established Pattern):

```ruby
# Main school controller
Api::V1::SchoolsController
  - show          # GET /api/v1/schools/:id
  - update        # PATCH /api/v1/schools/:id
  - stats         # GET /api/v1/schools/:id/stats

# Nested resource controllers
Api::V1::Schools::BaseController (for authorization)

Api::V1::Schools::MembersController
  - index         # GET /api/v1/schools/:id/members
  - create        # POST /api/v1/schools/:id/members
  - update        # PATCH /api/v1/schools/:id/members/:user_id
  - destroy       # DELETE /api/v1/schools/:id/members/:user_id

Api::V1::Schools::LevelsController
  - index         # GET /api/v1/schools/:id/levels
  - create        # POST /api/v1/schools/:id/levels
  - update        # PATCH /api/v1/schools/:id/levels/:level_id
  - destroy       # DELETE /api/v1/schools/:id/levels/:level_id
  - students      # GET /api/v1/schools/:id/levels/:level_id/students

Api::V1::Schools::ProjectsController
  - index         # GET /api/v1/schools/:id/projects
  - create        # POST /api/v1/schools/:id/projects

Api::V1::Schools::PartnershipsController
  - index         # GET /api/v1/schools/:id/partnerships
  - create        # POST /api/v1/schools/:id/partnerships
  - update        # PATCH /api/v1/schools/:id/partnerships/:partnership_id
  - destroy       # DELETE /api/v1/schools/:id/partnerships/:partnership_id

Api::V1::Schools::BranchesController (NEW - Branch System)
  - index         # GET /api/v1/schools/:id/branches
  - create        # POST /api/v1/schools/:id/branches/invite
  - settings      # PATCH /api/v1/schools/:id/branches/settings

Api::V1::Schools::BranchRequestsController (NEW - Branch System)
  - index         # GET /api/v1/schools/:id/branch-requests
  - create        # POST /api/v1/schools/:id/branch-requests
  - confirm       # PATCH /api/v1/schools/:id/branch-requests/:id/confirm
  - reject        # PATCH /api/v1/schools/:id/branch-requests/:id/reject
  - destroy       # DELETE /api/v1/schools/:id/branch-requests/:id

Api::V1::Schools::BadgesController
  - assign        # POST /api/v1/schools/:id/badges/assign
  - assigned      # GET /api/v1/schools/:id/badges/assigned
```

---

## 📊 Permission Matrix

### UserSchool Role Hierarchy:

**⚠️ CRITICAL: Only Admin and Superadmin can access School Dashboard!**

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

**Note:** Referents and Intervenants use **Teacher Dashboard** for their operations (projects/badges), not School Dashboard.

---

## 🔧 Implementation Plan

### **Step 1: Create Base Controller & Routes** (1 hour)

#### File: `app/controllers/api/v1/schools/base_controller.rb`

```ruby
# Base controller for all school-scoped endpoints
# Handles authorization and school context
class Api::V1::Schools::BaseController < Api::V1::BaseController
  before_action :set_school
  before_action :ensure_school_member
  
  private
  
  def set_school
    @school = School.find(params[:school_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: 'Not Found',
      message: 'School not found'
    }, status: :not_found
  end
  
  def ensure_school_member
    # CRITICAL: Only admin/superadmin can access School Dashboard
    user_school = current_user.user_schools.find_by(
      school: @school, 
      status: :confirmed,
      role: [:admin, :superadmin]
    )
    
    unless user_school
      return render json: {
        error: 'Forbidden',
        message: 'School Dashboard access requires Admin or Superadmin role'
      }, status: :forbidden
    end
    
    @current_user_school = user_school
  end
  
  def ensure_admin_or_superadmin
    unless @current_user_school.admin? || @current_user_school.superadmin?
      render json: {
        error: 'Forbidden',
        message: 'Admin or Superadmin role required'
      }, status: :forbidden
    end
  end
  
  def ensure_superadmin
    unless @current_user_school.superadmin?
      render json: {
        error: 'Forbidden',
        message: 'Superadmin role required'
      }, status: :forbidden
    end
  end
  
  def ensure_can_manage_projects
    unless @current_user_school.can_manage_projects?
      render json: {
        error: 'Forbidden',
        message: 'Referent, Admin, or Superadmin role required'
      }, status: :forbidden
    end
  end
  
  def ensure_can_assign_badges
    unless @current_user_school.can_assign_badges?
      render json: {
        error: 'Forbidden',
        message: 'Insufficient permissions to assign badges'
      }, status: :forbidden
    end
  end
end
```

#### File: `config/routes.rb` (Add to existing `api/v1` namespace)

```ruby
namespace :api do
  namespace :v1 do
    # ... existing routes ...
    
    # School Dashboard API
    resources :schools, only: [:show, :update] do
      member do
        get :stats
      end
      
      # Members
      resources :members, controller: 'schools/members', only: [:index, :create, :update, :destroy]
      
      # Levels (Classes)
      resources :levels, controller: 'schools/levels', only: [:index, :create, :update, :destroy] do
        member do
          get :students
        end
      end
      
      # Projects
      resources :projects, controller: 'schools/projects', only: [:index, :create]
      
      # Partnerships
      resources :partnerships, controller: 'schools/partnerships', only: [:index, :create, :update, :destroy]
      
      # Branches (NEW)
      namespace :branches, controller: 'schools/branches' do
        get '/', action: :index
        post :invite
        patch :settings
      end
      
      # Branch Requests (NEW)
      resources :branch_requests, controller: 'schools/branch_requests', only: [:index, :create, :destroy] do
        member do
          patch :confirm
          patch :reject
        end
      end
      
      # Badges
      namespace :badges, controller: 'schools/badges' do
        post :assign
        get :assigned
      end
    end
  end
end
```

---

### **Step 2: Schools Controller - Profile & Stats** (2 hours)

#### File: `app/controllers/api/v1/schools_controller.rb`

```ruby
# Main Schools API controller
# Handles school profile and dashboard stats
class Api::V1::SchoolsController < Api::V1::Schools::BaseController
  skip_before_action :set_school, only: []
  skip_before_action :ensure_school_member, only: []
  
  # GET /api/v1/schools/:id
  # View school profile
  def show
    render json: {
      data: serialize_school(@school, @current_user_school)
    }
  end
  
  # PATCH /api/v1/schools/:id
  # Update school profile (admin/superadmin only)
  def update
    ensure_admin_or_superadmin
    
    if @school.update(school_params)
      render json: {
        message: 'School updated successfully',
        data: serialize_school(@school, @current_user_school)
      }
    else
      render json: {
        error: 'Validation Failed',
        details: @school.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # GET /api/v1/schools/:id/stats
  # Dashboard statistics
  def stats
    # Base stats
    stats_data = {
      overview: {
        total_members: @school.users.count,
        total_teachers: @school.users.where(role: :teacher).count,
        total_students: @school.school_levels.joins(:students).distinct.count('users.id'),
        total_levels: @school.school_levels.count,
        total_projects: @school.projects.count,
        active_contract: @school.active_contract?,
        is_branch: @school.branch?,
        is_main_school: @school.main_school?
      },
      members_by_role: {
        superadmin: @school.user_schools.where(role: :superadmin, status: :confirmed).count,
        admin: @school.user_schools.where(role: :admin, status: :confirmed).count,
        referent: @school.user_schools.where(role: :referent, status: :confirmed).count,
        intervenant: @school.user_schools.where(role: :intervenant, status: :confirmed).count,
        member: @school.user_schools.where(role: :member, status: :confirmed).count
      },
      pending_approvals: {
        members: @school.user_schools.where(status: :pending).count,
        partnerships: @school.partnerships.where(status: :pending).count,
        branch_requests: BranchRequest.for_organization(@school).where(status: :pending).count
      }
    }
    
    # Add branch stats if superadmin
    if @current_user_school.superadmin?
      stats_data[:branches] = {
        total_branches: @school.branch_schools.count,
        branch_members: @school.main_school? ? @school.all_members_including_branches.count : nil,
        branch_projects: @school.main_school? ? @school.all_projects_including_branches.count : nil,
        parent_school: @school.parent_school ? {
          id: @school.parent_school.id,
          name: @school.parent_school.name
        } : nil
      }
    end
    
    render json: stats_data
  end
  
  private
  
  def school_params
    params.require(:school).permit(
      :name, :city, :zip_code, :school_type, :referent_phone_number
    )
  end
  
  def serialize_school(school, user_school)
    {
      id: school.id,
      name: school.name,
      city: school.city,
      zip_code: school.zip_code,
      school_type: school.school_type,
      referent_phone_number: school.referent_phone_number,
      status: school.status,
      logo_url: school.logo.attached? ? 
        Rails.application.routes.url_helpers.rails_blob_url(school.logo, only_path: false) : nil,
      my_role: user_school.role,
      my_permissions: {
        can_manage_members: user_school.can_manage_members?,
        can_manage_levels: user_school.admin? || user_school.superadmin?,
        can_manage_projects: user_school.can_manage_projects?,
        can_assign_badges: user_school.can_assign_badges?,
        can_manage_partnerships: user_school.can_manage_partnerships?,
        can_manage_branches: user_school.can_manage_branches?
      },
      branch_info: {
        is_branch: school.branch?,
        is_main_school: school.main_school?,
        parent_school_id: school.parent_school_id,
        branches_count: school.branch_schools.count,
        share_members_with_branches: school.share_members_with_branches
      },
      created_at: school.created_at,
      updated_at: school.updated_at
    }
  end
end
```

---

### **Step 3: Members Controller** (2 hours)

#### File: `app/controllers/api/v1/schools/members_controller.rb`

```ruby
# School Members API controller
# Handles teacher/staff management
class Api::V1::Schools::MembersController < Api::V1::Schools::BaseController
  include Pagy::Backend
  
  before_action :ensure_admin_or_superadmin, only: [:create, :update, :destroy]
  
  # GET /api/v1/schools/:school_id/members
  # List all school members
  def index
    @members = @school.user_schools.includes(:user)
    
    # Filters
    @members = @members.where(status: params[:status]) if params[:status].present?
    @members = @members.where(role: params[:role]) if params[:role].present?
    
    # Search by name
    if params[:search].present?
      @members = @members.joins(:user).where(
        "users.first_name ILIKE ? OR users.last_name ILIKE ? OR users.email ILIKE ?",
        "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"
      )
    end
    
    @pagy, @members = pagy(@members.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: @members.map { |member| serialize_member(member) },
      meta: pagination_meta(@pagy)
    }
  end
  
  # POST /api/v1/schools/:school_id/members
  # Invite/add a member to school
  def create
    # Find user by email (existing) or create params (new user)
    user = find_or_identify_user
    
    return render json: user[:error], status: user[:status] if user[:error]
    
    existing_user = user[:user]
    is_new_user = user[:is_new]
    
    # Check if already a member
    if @school.user_schools.exists?(user: existing_user)
      return render json: {
        error: 'Conflict',
        message: 'User is already a member of this school'
      }, status: :conflict
    end
    
    # Validate role permissions
    requested_role = params[:role]&.to_sym || :member
    
    # Check superadmin creation rules
    if requested_role == :superadmin
      # Rule 1: Only superadmins can assign superadmin role
      unless @current_user_school.superadmin?
        return render json: {
          error: 'Forbidden',
          message: 'Only superadmins can assign the superadmin role'
        }, status: :forbidden
      end
      
      # Rule 2: Only ONE superadmin per school
      if @school.user_schools.exists?(role: :superadmin)
        return render json: {
          error: 'Forbidden',
          message: 'This school already has a superadmin. There can only be one superadmin per school.'
        }, status: :forbidden
      end
    end
    
    # Create membership
    user_school = @school.user_schools.build(
      user: existing_user,
      role: requested_role,
      status: :pending  # Always pending for invitation workflow
    )
    
    if user_school.save
      # Send appropriate notification based on user existence
      if is_new_user
        if existing_user.has_temporary_email?
          # TODO: Send claim link invitation
          # UserSchoolMailer.claim_invitation(user_school).deliver_later
        else
          # TODO: Send registration invitation (known email)
          # UserSchoolMailer.registration_invitation(user_school).deliver_later
        end
      else
        # TODO: Send membership notification (existing user)
        # UserSchoolMailer.membership_invitation(user_school).deliver_later
      end
      
      render json: {
        message: is_new_user ? 'Invitation sent successfully' : 'Member invited successfully',
        data: serialize_member(user_school),
        invitation_method: existing_user.has_temporary_email? ? 'claim_link' : 'email'
      }, status: :created
    else
      render json: {
        error: 'Validation Failed',
        details: user_school.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/schools/:school_id/members/:id
  # Update member role
  def update
    user = User.find(params[:id])
    user_school = @school.user_schools.find_by!(user: user)
    
    requested_role = params[:role]&.to_sym
    
    # Superadmin role management
    if requested_role == :superadmin
      # Rule 1: Only superadmins can assign superadmin role
      unless @current_user_school.superadmin?
        return render json: {
          error: 'Forbidden',
          message: 'Only superadmins can assign the superadmin role'
        }, status: :forbidden
      end
      
      # Rule 2: Only ONE superadmin per school
      existing_superadmin = @school.user_schools.find_by(role: :superadmin)
      if existing_superadmin && existing_superadmin != user_school
        return render json: {
          error: 'Forbidden',
          message: 'This school already has a superadmin. There can only be one superadmin per school.'
        }, status: :forbidden
      end
    end
    
    # Prevent modifying superadmin by non-superadmin
    if user_school.superadmin? && !@current_user_school.superadmin?
      return render json: {
        error: 'Forbidden',
        message: 'Only superadmins can modify superadmin role'
      }, status: :forbidden
    end
    
    if user_school.update(member_params)
      render json: {
        message: 'Member updated successfully',
        data: serialize_member(user_school)
      }
    else
      render json: {
        error: 'Validation Failed',
        details: user_school.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/schools/:school_id/members/:id
  # Remove member from school
  def destroy
    user = User.find(params[:id])
    user_school = @school.user_schools.find_by!(user: user)
    
    # Rule: Superadmin CANNOT be deleted
    if user_school.superadmin?
      return render json: {
        error: 'Forbidden',
        message: 'Superadmin cannot be removed from the school. Transfer superadmin role first.'
      }, status: :forbidden
    end
    
    # Only superadmin can remove other admins
    if user_school.admin? && !@current_user_school.superadmin?
      return render json: {
        error: 'Forbidden',
        message: 'Only superadmins can remove admins'
      }, status: :forbidden
    end
    
    if user_school.destroy
      render json: {
        message: 'Member removed successfully'
      }
    else
      render json: {
        error: 'Failed to remove member',
        details: user_school.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def member_params
    params.permit(:role, :status)
  end
  
  def find_or_identify_user
    # Try to find existing user by email
    if params[:email].present?
      existing_user = User.find_by(email: params[:email])
      
      if existing_user
        return { user: existing_user, is_new: false }
      else
        # Create new user with known email (will receive registration invitation)
        new_user = User.new(
          email: params[:email],
          first_name: params[:first_name] || 'New',
          last_name: params[:last_name] || 'Member',
          role: params[:user_role] || :voluntary,  # Default role for new users
          password: SecureRandom.hex(16),  # Temporary password
          confirmed_at: nil  # Will confirm via invitation link
        )
        
        if new_user.save(validate: false)  # Skip validation for invitation flow
          return { user: new_user, is_new: true }
        else
          return {
            error: {
              error: 'User Creation Failed',
              details: new_user.errors.full_messages
            },
            status: :unprocessable_entity
          }
        end
      end
    elsif params[:first_name].present? && params[:last_name].present? && params[:birthday].present?
      # Create user without email (temporary email + claim link)
      birthday = Date.parse(params[:birthday]) rescue nil
      
      unless birthday
        return {
          error: {
            error: 'Bad Request',
            message: 'Valid birthday is required for users without email'
          },
          status: :bad_request
        }
      end
      
      # Check for duplicate by name + birthday
      existing = User.where(
        first_name: params[:first_name],
        last_name: params[:last_name],
        birthday: birthday
      ).first
      
      if existing
        return {
          error: {
            error: 'Conflict',
            message: 'A user with this name and birthday already exists. Use their email instead.'
          },
          status: :conflict
        }
      end
      
      # Create user with temporary email
      temp_email = "temp_#{SecureRandom.hex(8)}@kinship-temp.local"
      claim_token = SecureRandom.urlsafe_base64(32)
      
      new_user = User.new(
        email: temp_email,
        first_name: params[:first_name],
        last_name: params[:last_name],
        birthday: birthday,
        role: params[:user_role] || :voluntary,
        password: SecureRandom.hex(16),
        has_temporary_email: true,
        claim_token: claim_token,
        claim_token_expires_at: 30.days.from_now,
        confirmed_at: Time.current  # Auto-confirm temporary email accounts
      )
      
      if new_user.save(validate: false)
        return { user: new_user, is_new: true }
      else
        return {
          error: {
            error: 'User Creation Failed',
            details: new_user.errors.full_messages
          },
          status: :unprocessable_entity
        }
      end
    else
      return {
        error: {
          error: 'Bad Request',
          message: 'Either email OR (first_name + last_name + birthday) is required'
        },
        status: :bad_request
      }
    end
  end
  
  def serialize_member(user_school)
    user = user_school.user
    {
      id: user.id,
      full_name: user.full_name,
      first_name: user.first_name,
      last_name: user.last_name,
      email: user.email,
      role_in_system: user.role,
      role_in_school: user_school.role,
      status: user_school.status,
      avatar_url: user.avatar.attached? ? 
        Rails.application.routes.url_helpers.rails_blob_url(user.avatar, only_path: false) : nil,
      joined_at: user_school.created_at
    }
  end
  
  def pagination_meta(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.items
    }
  end
end
```

---

### **Step 4: Levels (Classes) Controller** (2 hours)

#### File: `app/controllers/api/v1/schools/levels_controller.rb`

```ruby
# School Levels (Classes) API controller
# Handles class management
class Api::V1::Schools::LevelsController < Api::V1::Schools::BaseController
  include Pagy::Backend
  
  before_action :ensure_admin_or_superadmin, only: [:create, :update, :destroy]
  before_action :set_level, only: [:update, :destroy, :students]
  
  # GET /api/v1/schools/:school_id/levels
  # List all school classes
  def index
    @levels = @school.school_levels.includes(:students, :teachers)
    
    # Filters
    @levels = @levels.where(level: params[:level]) if params[:level].present?
    @levels = @levels.where(name: params[:name]) if params[:name].present?
    
    @pagy, @levels = pagy(@levels.order(level: :asc, name: :asc), items: params[:per_page] || 12)
    
    render json: {
      data: @levels.map { |level| serialize_level(level) },
      meta: pagination_meta(@pagy)
    }
  end
  
  # POST /api/v1/schools/:school_id/levels
  # Create a new class
  def create
    @level = @school.school_levels.build(level_params)
    
    if @level.save
      render json: {
        message: 'Class created successfully',
        data: serialize_level(@level)
      }, status: :created
    else
      render json: {
        error: 'Validation Failed',
        details: @level.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/schools/:school_id/levels/:id
  # Update class
  def update
    if @level.update(level_params)
      render json: {
        message: 'Class updated successfully',
        data: serialize_level(@level)
      }
    else
      render json: {
        error: 'Validation Failed',
        details: @level.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/schools/:school_id/levels/:id
  # Delete class
  def destroy
    if @level.destroy
      render json: {
        message: 'Class deleted successfully'
      }
    else
      render json: {
        error: 'Failed to delete class',
        details: @level.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # GET /api/v1/schools/:school_id/levels/:id/students
  # List students in class
  def students
    @students = @level.students.includes(:user_school_levels)
    
    @pagy, @students = pagy(@students, items: params[:per_page] || 20)
    
    render json: {
      data: @students.map { |student| serialize_student(student) },
      meta: pagination_meta(@pagy)
    }
  end
  
  private
  
  def set_level
    @level = @school.school_levels.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: 'Not Found',
      message: 'Class not found'
    }, status: :not_found
  end
  
  def level_params
    params.require(:level).permit(:name, :level)
  end
  
  def serialize_level(level)
    {
      id: level.id,
      name: level.name,
      level: level.level,
      students_count: level.students.count,
      teachers_count: level.teachers.count,
      projects_count: level.projects.count,
      created_at: level.created_at,
      updated_at: level.updated_at
    }
  end
  
  def serialize_student(student)
    {
      id: student.id,
      full_name: student.full_name,
      first_name: student.first_name,
      last_name: student.last_name,
      email: student.email,
      birthday: student.birthday,
      has_temporary_email: student.has_temporary_email,
      avatar_url: student.avatar.attached? ? 
        Rails.application.routes.url_helpers.rails_blob_url(student.avatar, only_path: false) : nil
    }
  end
  
  def pagination_meta(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.items
    }
  end
end
```

---

### **Step 5: Projects Controller** (1.5 hours)

#### File: `app/controllers/api/v1/schools/projects_controller.rb`

```ruby
# School Projects API controller
# Handles school project management
class Api::V1::Schools::ProjectsController < Api::V1::Schools::BaseController
  include Pagy::Backend
  
  before_action :ensure_can_manage_projects, only: [:create]
  
  # GET /api/v1/schools/:school_id/projects
  # List school projects (own + branch projects if main school)
  def index
    if @school.main_school? && params[:include_branches] == 'true'
      # Main school can see branch projects
      @projects = @school.all_projects_including_branches
    else
      # Branch school or main school without branch filter
      @projects = @school.projects
    end
    
    @projects = @projects.includes(:owner, :skills, :tags, :school_levels, :companies)
    
    # Filters
    @projects = @projects.where(status: params[:status]) if params[:status].present?
    @projects = @projects.where(private: params[:private]) if params[:private].present?
    
    @pagy, @projects = pagy(@projects.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: ActiveModelSerializers::SerializableResource.new(@projects, each_serializer: ProjectSerializer).as_json,
      meta: pagination_meta(@pagy)
    }
  end
  
  # POST /api/v1/schools/:school_id/projects
  # Create a school project
  def create
    @project = Project.new(project_params)
    @project.owner = current_user
    @project.private ||= false
    @project.status ||= :in_progress
    
    # Validate: school_levels must belong to this school
    if params[:project][:school_level_ids].present?
      school_level_ids = params[:project][:school_level_ids].map(&:to_i)
      valid_ids = @school.school_levels.pluck(:id)
      
      unless (school_level_ids - valid_ids).empty?
        return render json: {
          error: 'Forbidden',
          message: 'All school levels must belong to this school'
        }, status: :forbidden
      end
    end
    
    if @project.save
      render json: @project, serializer: ProjectSerializer, status: :created
    else
      render json: {
        error: 'Validation Failed',
        details: @project.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def project_params
    params.require(:project).permit(
      :title, :description, :start_date, :end_date, :private, :status,
      :participants_number, skill_ids: [], tag_ids: [], school_level_ids: [], company_ids: []
    )
  end
  
  def pagination_meta(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.items
    }
  end
end
```

---

### **Step 6: Branches Controller (NEW)** (2.5 hours)

#### File: `app/controllers/api/v1/schools/branches_controller.rb`

```ruby
# School Branches API controller
# Handles branch school management (superadmin only)
class Api::V1::Schools::BranchesController < Api::V1::Schools::BaseController
  include Pagy::Backend
  
  before_action :ensure_superadmin
  
  # GET /api/v1/schools/:school_id/branches
  # List all branch schools
  def index
    unless @school.main_school?
      return render json: {
        error: 'Bad Request',
        message: 'Only main schools can have branches'
      }, status: :bad_request
    end
    
    @branches = @school.branch_schools.includes(:user_schools, :school_levels)
    
    @pagy, @branches = pagy(@branches.order(name: :asc), items: params[:per_page] || 12)
    
    render json: {
      data: @branches.map { |branch| serialize_branch(branch) },
      meta: {
        **pagination_meta(@pagy),
        share_members_with_branches: @school.share_members_with_branches
      }
    }
  end
  
  # POST /api/v1/schools/:school_id/branches/invite
  # Invite another school to become a branch
  def create
    unless @school.main_school?
      return render json: {
        error: 'Forbidden',
        message: 'Only main schools can invite branches'
      }, status: :forbidden
    end
    
    child_school = School.find_by(id: params[:child_school_id])
    
    unless child_school
      return render json: {
        error: 'Not Found',
        message: 'Target school not found'
      }, status: :not_found
    end
    
    # Use model method to create branch request
    branch_request = @school.invite_as_branch(child_school)
    
    if branch_request.persisted?
      # TODO: Send notification email
      # BranchRequestMailer.invitation(branch_request).deliver_later
      
      render json: {
        message: 'Branch invitation sent successfully',
        data: serialize_branch_request(branch_request)
      }, status: :created
    else
      render json: {
        error: 'Validation Failed',
        details: branch_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/schools/:school_id/branches/settings
  # Update branch settings (e.g., member sharing)
  def settings
    unless @school.main_school?
      return render json: {
        error: 'Forbidden',
        message: 'Only main schools can manage branch settings'
      }, status: :forbidden
    end
    
    if @school.update(branch_settings_params)
      render json: {
        message: 'Branch settings updated successfully',
        data: {
          share_members_with_branches: @school.share_members_with_branches
        }
      }
    else
      render json: {
        error: 'Validation Failed',
        details: @school.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def branch_settings_params
    params.permit(:share_members_with_branches)
  end
  
  def serialize_branch(branch)
    {
      id: branch.id,
      name: branch.name,
      city: branch.city,
      zip_code: branch.zip_code,
      school_type: branch.school_type,
      members_count: branch.users.count,
      levels_count: branch.school_levels.count,
      projects_count: branch.projects.count,
      created_at: branch.created_at
    }
  end
  
  def serialize_branch_request(request)
    {
      id: request.id,
      parent_school: {
        id: request.parent.id,
        name: request.parent.name
      },
      child_school: {
        id: request.child.id,
        name: request.child.name
      },
      initiator_type: request.initiator_type,
      status: request.status,
      created_at: request.created_at
    }
  end
  
  def pagination_meta(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.items
    }
  end
end
```

---

### **Step 7: Branch Requests Controller (NEW)** (2 hours)

#### File: `app/controllers/api/v1/schools/branch_requests_controller.rb`

```ruby
# School Branch Requests API controller
# Handles branch invitation/request workflow (superadmin only)
class Api::V1::Schools::BranchRequestsController < Api::V1::Schools::BaseController
  include Pagy::Backend
  
  before_action :ensure_superadmin
  before_action :set_branch_request, only: [:confirm, :reject, :destroy]
  
  # GET /api/v1/schools/:school_id/branch-requests
  # List all branch requests (sent + received)
  def index
    @requests = BranchRequest.for_organization(@school)
    
    # Filter by status
    @requests = @requests.where(status: params[:status]) if params[:status].present?
    
    # Filter by direction
    case params[:direction]
    when 'sent'
      @requests = @requests.where(initiator: @school)
    when 'received'
      @requests = @requests.where.not(initiator: @school)
    end
    
    @pagy, @requests = pagy(@requests.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: @requests.map { |req| serialize_branch_request(req) },
      meta: pagination_meta(@pagy)
    }
  end
  
  # POST /api/v1/schools/:school_id/branch-requests
  # Request to become a branch of another school
  def create
    if @school.branch?
      return render json: {
        error: 'Forbidden',
        message: 'Branch schools cannot create branch requests'
      }, status: :forbidden
    end
    
    parent_school = School.find_by(id: params[:parent_school_id])
    
    unless parent_school
      return render json: {
        error: 'Not Found',
        message: 'Parent school not found'
      }, status: :not_found
    end
    
    # Use model method to create request
    branch_request = @school.request_to_become_branch_of(parent_school)
    
    if branch_request.persisted?
      # TODO: Send notification email to parent school admins
      # BranchRequestMailer.request(branch_request).deliver_later
      
      render json: {
        message: 'Branch request sent successfully',
        data: serialize_branch_request(branch_request)
      }, status: :created
    else
      render json: {
        error: 'Validation Failed',
        details: branch_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/schools/:school_id/branch-requests/:id/confirm
  # Accept branch request (recipient only)
  def confirm
    unless can_manage_request?(@branch_request)
      return render json: {
        error: 'Forbidden',
        message: 'Only the recipient can confirm this request'
      }, status: :forbidden
    end
    
    @branch_request.confirm!
    
    render json: {
      message: 'Branch request confirmed successfully',
      data: serialize_branch_request(@branch_request)
    }
  end
  
  # PATCH /api/v1/schools/:school_id/branch-requests/:id/reject
  # Reject branch request (recipient only)
  def reject
    unless can_manage_request?(@branch_request)
      return render json: {
        error: 'Forbidden',
        message: 'Only the recipient can reject this request'
      }, status: :forbidden
    end
    
    @branch_request.reject!
    
    render json: {
      message: 'Branch request rejected successfully',
      data: serialize_branch_request(@branch_request)
    }
  end
  
  # DELETE /api/v1/schools/:school_id/branch-requests/:id
  # Cancel branch request (initiator only, pending only)
  def destroy
    unless @branch_request.initiator == @school
      return render json: {
        error: 'Forbidden',
        message: 'Only the initiator can cancel this request'
      }, status: :forbidden
    end
    
    unless @branch_request.pending?
      return render json: {
        error: 'Bad Request',
        message: 'Only pending requests can be cancelled'
      }, status: :bad_request
    end
    
    if @branch_request.destroy
      render json: {
        message: 'Branch request cancelled successfully'
      }
    else
      render json: {
        error: 'Failed to cancel request',
        details: @branch_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_branch_request
    @branch_request = BranchRequest.for_organization(@school).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: 'Not Found',
      message: 'Branch request not found'
    }, status: :not_found
  end
  
  def can_manage_request?(request)
    request.recipient == @school && request.pending?
  end
  
  def serialize_branch_request(request)
    {
      id: request.id,
      parent_school: {
        id: request.parent.id,
        name: request.parent.name
      },
      child_school: {
        id: request.child.id,
        name: request.child.name
      },
      initiator: request.initiated_by_parent? ? 'parent' : 'child',
      recipient: request.initiated_by_parent? ? 'child' : 'parent',
      status: request.status,
      confirmed_at: request.confirmed_at,
      created_at: request.created_at,
      updated_at: request.updated_at
    }
  end
  
  def pagination_meta(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.items
    }
  end
end
```

---

### **Step 8: Partnerships Controller** (1.5 hours)

#### File: `app/controllers/api/v1/schools/partnerships_controller.rb`

```ruby
# School Partnerships API controller
# Handles partnership management with companies/schools (superadmin only)
class Api::V1::Schools::PartnershipsController < Api::V1::Schools::BaseController
  include Pagy::Backend
  
  before_action :ensure_superadmin
  before_action :set_partnership, only: [:update, :destroy]
  
  # GET /api/v1/schools/:school_id/partnerships
  # List all partnerships
  def index
    @partnerships = @school.partnerships.includes(:partnership_members)
    
    # Filters
    @partnerships = @partnerships.where(status: params[:status]) if params[:status].present?
    @partnerships = @partnerships.where(partnership_type: params[:partnership_type]) if params[:partnership_type].present?
    
    @pagy, @partnerships = pagy(@partnerships.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: @partnerships.map { |partnership| serialize_partnership(partnership) },
      meta: pagination_meta(@pagy)
    }
  end
  
  # POST /api/v1/schools/:school_id/partnerships
  # Create a new partnership
  def create
    # For Phase 5, we'll keep it simple - just list partnerships
    # Full partnership creation is complex and will be handled in a dedicated Partnerships API
    render json: {
      error: 'Not Implemented',
      message: 'Partnership creation will be available in a future update. Please use the web interface.'
    }, status: :not_implemented
  end
  
  # PATCH /api/v1/schools/:school_id/partnerships/:id
  # Update partnership settings
  def update
    if @partnership.update(partnership_params)
      render json: {
        message: 'Partnership updated successfully',
        data: serialize_partnership(@partnership)
      }
    else
      render json: {
        error: 'Validation Failed',
        details: @partnership.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/schools/:school_id/partnerships/:id
  # Leave/delete partnership
  def destroy
    if @partnership.destroy
      render json: {
        message: 'Partnership removed successfully'
      }
    else
      render json: {
        error: 'Failed to remove partnership',
        details: @partnership.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_partnership
    @partnership = @school.partnerships.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: 'Not Found',
      message: 'Partnership not found'
    }, status: :not_found
  end
  
  def partnership_params
    params.require(:partnership).permit(:share_members, :share_projects)
  end
  
  def serialize_partnership(partnership)
    partner_members = partnership.partnership_members.where.not(participant: @school)
    
    {
      id: partnership.id,
      partnership_type: partnership.partnership_type,
      status: partnership.status,
      share_members: partnership.share_members,
      share_projects: partnership.share_projects,
      partners: partner_members.map do |pm|
        {
          id: pm.participant.id,
          name: pm.participant.name,
          type: pm.participant_type,
          role_in_partnership: pm.role_in_partnership,
          member_status: pm.member_status
        }
      end,
      created_at: partnership.created_at,
      updated_at: partnership.updated_at
    }
  end
  
  def pagination_meta(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.items
    }
  end
end
```

---

### **Step 9: Badges Controller** (1 hour)

#### File: `app/controllers/api/v1/schools/badges_controller.rb`

```ruby
# School Badges API controller
# Handles badge assignment by school members
class Api::V1::Schools::BadgesController < Api::V1::Schools::BaseController
  include Pagy::Backend
  
  before_action :ensure_can_assign_badges
  
  # POST /api/v1/schools/:school_id/badges/assign
  # Assign badge (delegates to main badges controller logic)
  def assign
    # Verify school has active contract
    unless @school.active_contract?
      return render json: {
        error: 'Forbidden',
        message: 'School must have an active contract to assign badges'
      }, status: :forbidden
    end
    
    # Delegate to existing badge assignment logic
    badge = Badge.find_by(id: params[:badge_id])
    unless badge
      return render json: {
        error: 'Not Found',
        message: 'Badge not found'
      }, status: :not_found
    end
    
    recipient_ids = params[:recipient_ids] || []
    if recipient_ids.empty?
      return render json: {
        error: 'Bad Request',
        message: 'At least one recipient is required'
      }, status: :bad_request
    end
    
    # Assign badges to recipients
    assignments = []
    errors = []
    
    recipient_ids.each do |recipient_id|
      begin
        recipient = User.find(recipient_id)
        
        user_badge = UserBadge.create!(
          receiver: recipient,
          badge: badge,
          sender: current_user,
          organization: @school,
          project_title: params[:project_title] || "Badge assigned via School Dashboard",
          project_description: params[:project_description] || "Badge assigned by #{current_user.full_name}",
          comment: params[:comment]
        )
        
        # Add badge skills if provided
        if params[:badge_skill_ids].present?
          params[:badge_skill_ids].each do |badge_skill_id|
            user_badge.user_badge_skills.create!(badge_skill_id: badge_skill_id)
          end
        end
        
        assignments << {
          user_id: recipient.id,
          user_name: recipient.full_name,
          badge_id: badge.id,
          badge_name: badge.name
        }
        
      rescue ActiveRecord::RecordNotFound
        errors << "User #{recipient_id} not found"
      rescue ActiveRecord::RecordInvalid => e
        errors << "User #{recipient_id}: #{e.message}"
      end
    end
    
    if assignments.any?
      render json: {
        message: 'Badges assigned successfully',
        assigned_count: assignments.count,
        assignments: assignments,
        errors: errors.any? ? errors : nil
      }, status: :created
    else
      render json: {
        error: 'Assignment failed',
        message: 'No badges were assigned',
        details: errors
      }, status: :unprocessable_entity
    end
  end
  
  # GET /api/v1/schools/:school_id/badges/assigned
  # List badges assigned by school members
  def assigned
    @user_badges = UserBadge.where(organization: @school, sender: current_user)
                            .includes(:receiver, :badge, :project)
    
    # Filters
    if params[:project_id].present?
      @user_badges = @user_badges.where(project_id: params[:project_id])
    end
    
    if params[:badge_series].present?
      @user_badges = @user_badges.joins(:badge).where(badges: {series: params[:badge_series]})
    end
    
    if params[:badge_level].present?
      @user_badges = @user_badges.joins(:badge).where(badges: {level: params[:badge_level]})
    end
    
    @pagy, @user_badges = pagy(@user_badges.order(created_at: :desc), items: params[:per_page] || 12)
    
    render json: {
      data: @user_badges.map { |user_badge| serialize_user_badge(user_badge) },
      meta: pagination_meta(@pagy)
    }
  end
  
  private
  
  def serialize_user_badge(user_badge)
    {
      id: user_badge.id,
      receiver: {
        id: user_badge.receiver.id,
        full_name: user_badge.receiver.full_name,
        email: user_badge.receiver.email
      },
      badge: {
        id: user_badge.badge.id,
        name: user_badge.badge.name,
        series: user_badge.badge.series,
        level: user_badge.badge.level
      },
      project: user_badge.project ? {
        id: user_badge.project.id,
        title: user_badge.project.title
      } : nil,
      status: user_badge.status,
      comment: user_badge.comment,
      assigned_at: user_badge.created_at
    }
  end
  
  def pagination_meta(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.items
    }
  end
end
```

---

## 📋 Testing Strategy

### Manual Testing with `curl` (Following Phase 4 Pattern):

**Test Sequence:**
1. Login as school superadmin
2. Get school profile
3. Get dashboard stats
4. List members
5. Create/update member
6. List classes
7. Create class
8. List students in class
9. List projects
10. Create project
11. List branches (if main school)
12. Invite branch school
13. List branch requests
14. Confirm branch request
15. Update branch settings
16. List partnerships
17. Assign badge

### Update Postman Collection:

Add all new School Dashboard endpoints to `postman_collection.json` following the existing structure.

---

## ⚠️ Important Notes

### Authorization Checks:
- All endpoints require confirmed school membership
- Role-based permissions enforced via `before_action` filters
- Superadmin-only actions clearly marked

### Branch System:
- Only superadmins can manage branches
- 1-level hierarchy enforced (no sub-branches)
- Member sharing controlled by parent school setting
- Parent can always see branch projects

### Badge Assignment:
- Requires active school contract
- Only users with `can_assign_badges?` permission
- Validates recipient existence

### Performance:
- Pagination on all list endpoints (default 12 items)
- Eager loading with `includes` to avoid N+1 queries
- Use of scopes for complex queries

---

## 🚀 Next Steps After Approval

1. **Create controllers** (Steps 1-9)
2. **Manual testing** with `curl`
3. **Update Postman collection**
4. **Update documentation** (`REACT_INTEGRATION_STRATEGY.md`)
5. **Commit and push** changes
6. **Proceed to Phase 6** (Company Dashboard API)

---

## ✅ Ready for Implementation?

This implementation plan follows our established patterns from Phases 3 & 4, with careful attention to:
- **Branch system integration** (the feature you reminded me about!)
- **Role-based authorization** 
- **Consistent API design**
- **Comprehensive error handling**
- **Performance optimization**

**Please review and approve to proceed with implementation.**

