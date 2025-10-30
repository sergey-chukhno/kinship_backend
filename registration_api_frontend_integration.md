# Registration API - Frontend Integration Guide

## Overview

This document provides comprehensive information for React frontend developers working on the Kinship platform registration system. It covers user roles, registration flow, dashboard access, and API endpoints.

---

## Table of Contents

1. [User Roles](#user-roles)
2. [Registration Flow](#registration-flow)
3. [Dashboard Access](#dashboard-access)
4. [API Endpoints](#api-endpoints)
5. [Context Switching](#context-switching)
6. [Example Requests](#example-requests)
7. [Error Handling](#error-handling)

---

## 1. User Roles

### 1.1 Role Categories

The Kinship platform uses **16 informative user roles** organized into 4 categories:

#### Personal User Roles
These roles indicate personal users who primarily use the platform for personal engagement:

- **`parent`** (0) - Parent of a child
- **`grand_parent`** (1) - Grandparent
- **`children`** (2) - Child user
- **`voluntary`** (3) - Volunteer (default role)
- **`tutor`** (4) - Tutor
- **`employee`** (5) - Employee

#### Teacher Roles
These roles indicate users who teach or work in educational settings:

- **`school_teacher`** (6) - School teacher
- **`college_lycee_professor`** (7) - College/Lycee professor
- **`teaching_staff`** (8) - Teaching staff member

#### School Admin Roles
These roles indicate users who administer schools:

- **`school_director`** (9) - School director
- **`principal`** (10) - Principal
- **`education_director`** (11) - Education director

#### Company Admin Roles
These roles indicate users who administer companies/organizations:

- **`association_president`** (12) - Association president
- **`company_director`** (13) - Company director
- **`organization_head`** (14) - Organization head

#### Special Role
- **`other`** (15) - Other (requires `role_additional_information` field)

### 1.2 Role Groups

The backend provides helper methods to check role categories:

```javascript
// Check if user has personal user role
const isPersonalUser = user.role && ['parent', 'grand_parent', 'children', 'voluntary', 'tutor', 'employee', 'other'].includes(user.role);

// Check if user has teacher role
const isTeacher = user.role && ['school_teacher', 'college_lycee_professor', 'teaching_staff', 'other'].includes(user.role);

// Check if user has school admin role
const isSchoolAdmin = user.role && ['school_director', 'principal', 'education_director', 'other'].includes(user.role);

// Check if user has company admin role
const isCompanyAdmin = user.role && ['association_president', 'company_director', 'organization_head', 'other'].includes(user.role);
```

---

## 2. Registration Flow

### 2.1 Registration Types

The platform supports **4 registration types**:

1. **Personal User** (`registration_type: "personal"`)
   - Creates a personal user account
   - Optionally accepts `children_info` array for children data
   - Can optionally join existing schools/companies

2. **Teacher** (`registration_type: "teacher"`)
   - Creates a teacher account
   - **Requires academic email** (e.g., `@ac-nantes.fr`)
   - Can join existing school or register as independent teacher

3. **School** (`registration_type: "school"`)
   - Creates a new school organization
   - **Requires academic email** for the admin user
   - Creates `UserSchool` with `role: "superadmin"` and `status: "pending"`

4. **Company** (`registration_type: "company"`)
   - Creates a new company organization
   - Creates `UserCompany` with `role: "superadmin"` and `status: "pending"`
   - Can optionally create branch request

### 2.2 Registration Steps

```
1. User fills registration form
   ↓
2. Frontend sends POST /api/v1/auth/register
   ↓
3. Backend validates data and creates records
   ↓
4. Backend sends confirmation email
   ↓
5. User receives email with confirmation link
   ↓
6. User clicks link → GET /api/v1/auth/confirmation
   ↓
7. User account confirmed
   ↓
8. If school/company admin: Organization auto-confirmed
   ↓
9. User can now login
```

### 2.3 Email Confirmation

**Important:** Users **cannot login** until they confirm their email address.

- Confirmation email is sent automatically after registration
- Confirmation link format: `/api/v1/auth/confirmation?confirmation_token={token}`
- After confirmation, organizations (schools/companies) are auto-confirmed if user is superadmin

### 2.4 Validation Rules

#### Email Validation
- **Personal Users**: Cannot use academic emails (e.g., `@ac-nantes.fr`)
- **Teachers**: Must use academic email
- **School Admins**: Must use academic email

#### Password Requirements
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 special character

#### Age Validation
- Users must be at least 13 years old (`birthday` validation)

#### Required Fields
- `email` - User email address
- `password` - User password
- `password_confirmation` - Must match password
- `first_name` - User first name
- `last_name` - User last name
- `birthday` - User birthday (YYYY-MM-DD format)
- `role` - User role (one of the 16 roles)
- `accept_privacy_policy` - Must be `true`

---

## 3. Dashboard Access

### 3.1 Dashboard Types

The platform has **4 main dashboards**:

1. **Personal User Dashboard** (`user_dashboard: true`)
   - Available to: Personal user roles only
   - Features: Profile, projects, badges, skills, availability, children info

2. **Teacher Dashboard** (`teacher_dashboard: true`)
   - Available to: Teacher roles only
   - Features: Classes, students, projects, badge assignment

3. **School Dashboard** (`schools` array)
   - Available to: Users with confirmed `UserSchool` memberships
   - Features: School profile, members, classes, projects, partnerships

4. **Company Dashboard** (`companies` array)
   - Available to: Users with confirmed `UserCompany` memberships
   - Features: Company profile, members, projects, partnerships, branches

### 3.2 Available Contexts

After login, the API returns `available_contexts` in the user object:

```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "parent",
    "available_contexts": {
      "user_dashboard": true,
      "teacher_dashboard": false,
      "independent_teacher": null,
      "schools": [],
      "companies": []
    }
  }
}
```

#### Context Structure

```typescript
interface AvailableContexts {
  user_dashboard: boolean;        // Personal dashboard access
  teacher_dashboard: boolean;     // Teacher dashboard access
  independent_teacher: {           // Independent teacher info (if applicable)
    id: number;
    school_id: number | null;
    // ... other fields
  } | null;
  schools: Array<{                // Confirmed school memberships
    id: number;
    name: string;
    city: string;
    school_type: string;
    role: string;                  // "member" | "intervenant" | "referent" | "admin" | "superadmin"
    permissions: {
      superadmin: boolean;
      admin: boolean;
      referent: boolean;
      intervenant: boolean;
      can_manage_members: boolean;
      can_manage_projects: boolean;
      can_assign_badges: boolean;
      can_manage_partnerships: boolean;
      can_manage_branches: boolean;
    };
  }>;
  companies: Array<{              // Confirmed company memberships
    id: number;
    name: string;
    city: string;
    company_type: string;
    role: string;                  // Same as schools
    permissions: {
      // Same structure as schools
    };
  }>;
}
```

### 3.3 Dashboard Access Logic

**Personal Dashboard:**
- Returns `true` only if user has a personal user role (`parent`, `grand_parent`, `children`, `voluntary`, `tutor`, `employee`, `other`)

**Teacher Dashboard:**
- Returns `true` only if user has a teacher role (`school_teacher`, `college_lycee_professor`, `teaching_staff`, `other`)

**School Dashboard:**
- Returns array of schools where user has `UserSchool` with `status: "confirmed"`
- Includes role and permissions for each school

**Company Dashboard:**
- Returns array of companies where user has `UserCompany` with `status: "confirmed"`
- Includes role and permissions for each company

---

## 4. API Endpoints

### 4.1 Registration Endpoint

**POST** `/api/v1/auth/register`

**Content-Type:** `multipart/form-data` (for file uploads) or `application/json`

**Request Body:**

```json
{
  "registration_type": "personal" | "teacher" | "school" | "company",
  "user": {
    "email": "user@example.com",
    "password": "Password123!",
    "password_confirmation": "Password123!",
    "first_name": "John",
    "last_name": "Doe",
    "birthday": "1990-01-01",
    "role": "parent",
    "role_additional_information": "optional, required if role is 'other'",
    "accept_privacy_policy": true
  },
  // Optional fields based on registration_type:
  "children_info": [...],           // For personal users
  "join_school_id": 123,            // For teachers/personal users
  "join_company_id": 456,           // For personal users
  "school": {...},                  // For school registration
  "company": {...},                 // For company registration
  "branch_request_to_company_id": 789 // For company branch requests
}
```

**File Uploads:**
- `avatar` - User avatar image (optional, all registration types)
- `company_logo` - Company logo (optional, company registration only)

**Response (201 Created):**

```json
{
  "message": "Registration successful. Please check your email for confirmation.",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "parent",
    "avatar_url": "http://localhost:3000/rails/active_storage/blobs/...",
    "confirmation_token": "abc123..." // Only in development
  },
  "company": {                         // Only for company registration
    "id": 1,
    "name": "Test Company",
    "logo_url": "http://localhost:3000/rails/active_storage/blobs/..."
  },
  "warnings": []                       // File upload warnings (if any)
}
```

**Error Response (422 Unprocessable Entity):**

```json
{
  "errors": [
    "Email is invalid",
    "Password must contain at least 8 characters"
  ]
}
```

### 4.2 Email Confirmation Endpoint

**GET** `/api/v1/auth/confirmation?confirmation_token={token}`

**No Authentication Required**

**Response (200 OK):**

```json
{
  "message": "Email confirmed successfully",
  "confirmed": true,
  "email": "user@example.com"
}
```

**Error Response (422 Unprocessable Entity):**

```json
{
  "error": "Confirmation Failed",
  "message": "Confirmation token is invalid",
  "confirmed": false
}
```

### 4.3 Login Endpoint

**POST** `/api/v1/auth/login`

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "Password123!"
}
```

**Response (200 OK):**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "parent",
    "available_contexts": {
      "user_dashboard": true,
      "teacher_dashboard": false,
      "independent_teacher": null,
      "schools": [],
      "companies": []
    }
  }
}
```

**Error Response (401 Unauthorized):**

```json
{
  "error": "Invalid email or password"
}
```

### 4.4 Parent Children Endpoints

**GET** `/api/v1/parent_children`
- List all children info for the authenticated parent

**POST** `/api/v1/parent_children`
- Create new child info

**GET** `/api/v1/parent_children/:id`
- Get specific child info

**PATCH** `/api/v1/parent_children/:id`
- Update child info

**DELETE** `/api/v1/parent_children/:id`
- Delete child info

**Request Body (POST/PATCH):**

```json
{
  "first_name": "Alice",
  "last_name": "Doe",
  "birthday": "2015-03-20",
  "school_id": 123,              // Optional: ID of existing school
  "school_name": "Elementary School", // Optional: Name if school_id not provided
  "class_id": 456,               // Optional: ID of existing school level
  "class_name": "CE2"            // Optional: Name if class_id not provided
}
```

### 4.5 Public Endpoints

**GET** `/api/v1/skills`
- List all available skills (no authentication required)

**GET** `/api/v1/skills/:id/sub_skills`
- List sub-skills for a specific skill (no authentication required)

**GET** `/api/v1/schools/list_for_joining`
- List confirmed schools available for joining (no authentication required)

**GET** `/api/v1/companies/list_for_joining`
- List confirmed companies available for joining (no authentication required)

---

## 5. Context Switching

### 5.1 Multi-Role Users

Users can have **multiple roles** and **multiple organizational memberships**:

**Example:** A user who is both a teacher and a school admin:
- Can access **Teacher Dashboard** (based on role)
- Can access **School Dashboard** (based on `UserSchool` membership)
- Can switch between dashboards using context switching

### 5.2 Context Switching Logic

1. **User logs in** → Receives `available_contexts`
2. **Frontend determines available dashboards**:
   - If `user_dashboard: true` → Show Personal Dashboard
   - If `teacher_dashboard: true` → Show Teacher Dashboard
   - If `schools.length > 0` → Show School Dashboard selector
   - If `companies.length > 0` → Show Company Dashboard selector
3. **User selects context** → Frontend stores selected context
4. **API requests include context** → Backend uses context for data filtering

### 5.3 Implementation Example

```javascript
// After login
const { user } = loginResponse;
const { available_contexts } = user;

// Determine available dashboards
const availableDashboards = [];

if (available_contexts.user_dashboard) {
  availableDashboards.push({ type: 'user', name: 'Personal Dashboard' });
}

if (available_contexts.teacher_dashboard) {
  availableDashboards.push({ type: 'teacher', name: 'Teacher Dashboard' });
}

if (available_contexts.schools.length > 0) {
  available_contexts.schools.forEach(school => {
    availableDashboards.push({
      type: 'school',
      id: school.id,
      name: school.name,
      role: school.role
    });
  });
}

if (available_contexts.companies.length > 0) {
  available_contexts.companies.forEach(company => {
    availableDashboards.push({
      type: 'company',
      id: company.id,
      name: company.name,
      role: company.role
    });
  });
}

// Store in state/context
setAvailableDashboards(availableDashboards);
```

---

## 6. Example Requests

### 6.1 Personal User Registration

```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "registration_type": "personal",
    "user": {
      "email": "parent@example.com",
      "password": "Password123!",
      "password_confirmation": "Password123!",
      "first_name": "Jane",
      "last_name": "Parent",
      "birthday": "1985-05-15",
      "role": "parent",
      "accept_privacy_policy": true
    },
    "children_info": [
      {
        "first_name": "Alice",
        "last_name": "Parent",
        "birthday": "2015-03-20",
        "school_name": "Elementary School",
        "class_name": "CE2"
      }
    ]
  }'
```

### 6.2 Teacher Registration

```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "registration_type": "teacher",
    "user": {
      "email": "teacher@ac-nantes.fr",
      "password": "Password123!",
      "password_confirmation": "Password123!",
      "first_name": "Marie",
      "last_name": "Teacher",
      "birthday": "1985-06-20",
      "role": "school_teacher",
      "accept_privacy_policy": true
    },
    "join_school_id": null
  }'
```

### 6.3 School Registration

```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "registration_type": "school",
    "user": {
      "email": "director@ac-nantes.fr",
      "password": "Password123!",
      "password_confirmation": "Password123!",
      "first_name": "Pierre",
      "last_name": "Director",
      "birthday": "1975-08-15",
      "role": "school_director",
      "accept_privacy_policy": true
    },
    "school": {
      "name": "Test School",
      "zip_code": "44000",
      "city": "Nantes",
      "school_type": "lycee",
      "referent_phone_number": "0123456789"
    }
  }'
```

### 6.4 Company Registration with Logo

```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: multipart/form-data" \
  -F "registration_type=company" \
  -F "user[email]=company@example.com" \
  -F "user[password]=Password123!" \
  -F "user[password_confirmation]=Password123!" \
  -F "user[first_name]=Jean" \
  -F "user[last_name]=Director" \
  -F "user[birthday]=1980-02-10" \
  -F "user[role]=company_director" \
  -F "user[accept_privacy_policy]=true" \
  -F "company[name]=Test Company" \
  -F "company[description]=A test company" \
  -F "company[zip_code]=75001" \
  -F "company[city]=Paris" \
  -F "company[company_type_id]=1" \
  -F "company[referent_phone_number]=0123456789" \
  -F "avatar=@/path/to/avatar.jpg" \
  -F "company_logo=@/path/to/logo.png"
```

### 6.5 Email Confirmation

```bash
curl -X GET "http://localhost:3000/api/v1/auth/confirmation?confirmation_token=abc123..."
```

### 6.6 Login

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "Password123!"
  }'
```

---

## 7. Error Handling

### 7.1 Common Error Codes

- **400 Bad Request** - Invalid request format
- **401 Unauthorized** - Authentication required or invalid credentials
- **422 Unprocessable Entity** - Validation errors
- **500 Internal Server Error** - Server error

### 7.2 Validation Error Format

```json
{
  "errors": [
    "Email is invalid",
    "Password must contain at least 8 characters",
    "L'email doit être votre mail académique"
  ]
}
```

### 7.3 File Upload Warnings

If file upload fails but registration succeeds, the response includes a `warnings` array:

```json
{
  "message": "Registration successful. Please check your email for confirmation.",
  "user": {...},
  "warnings": [
    "Avatar upload failed: File size too large (max 5MB)"
  ]
}
```

### 7.4 Error Handling Best Practices

1. **Always check response status** before processing data
2. **Display user-friendly error messages** from the `errors` array
3. **Handle file upload warnings** gracefully (show warning but don't block flow)
4. **Validate email confirmation** before allowing login
5. **Check `available_contexts`** to determine which dashboards to show

---

## 8. Frontend Implementation Checklist

- [ ] Implement registration form with all 4 registration types
- [ ] Add email validation based on registration type
- [ ] Add password strength validation
- [ ] Add age validation (13+)
- [ ] Handle file uploads (avatar, company_logo)
- [ ] Show email confirmation message after registration
- [ ] Implement email confirmation flow
- [ ] Handle login with email confirmation check
- [ ] Parse `available_contexts` after login
- [ ] Implement context switching UI
- [ ] Handle multi-role users
- [ ] Display appropriate dashboards based on contexts
- [ ] Implement parent children CRUD
- [ ] Add error handling for all endpoints
- [ ] Show file upload warnings if present

---

## 9. Additional Resources

- **Postman Collection**: `postman_collection.json` - Complete API collection with examples
- **Backend Documentation**: See `REGISTRATION_API_IMPLEMENTATION_PLAN.md`
- **React Integration Strategy**: See `REACT_INTEGRATION_STRATEGY.md`

---

## 10. Support

For questions or issues:
1. Check the Postman collection for working examples
2. Review the backend implementation plan
3. Check server logs for detailed error messages
4. Contact the backend team for API-related questions

---

**Last Updated:** Phase 5 - Registration API Implementation  
**Version:** 1.0.0

