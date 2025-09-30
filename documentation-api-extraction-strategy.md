# Kinship Backend API Documentation & Extraction Strategy

## **PROJECT EXPLANATION & API EXTRACTION STRATEGY**

### **Section A — Executive Summary**

**Kinship** is a Rails 7.1.3.4 application built on Ruby 3.3.7 that facilitates educational partnerships between schools, companies, and volunteers. The platform enables project-based learning where students, teachers, and company mentors collaborate on educational projects, with a sophisticated badge system for recognizing achievements.

**Core Domains:**
- **User Management**: Multi-role users (teachers, tutors, volunteers, children) with complex relationships and permissions
- **Educational Institutions**: Schools with multiple levels, company partnerships, and contract management
- **Project Management**: Collaborative projects with team formation, skill matching, and progress tracking
- **Badge System**: Achievement recognition with skill-based categorization and approval workflows
- **Partnership Management**: School-company relationships with sponsorship and collaboration features

**Key Flows:**
1. **Registration**: Multi-step onboarding for different user types with skill and availability setup
2. **Project Creation**: Teachers/companies create projects with skill requirements and participant matching
3. **Badge Assignment**: Achievement recognition system with skill validation and approval workflows
4. **Partnership Management**: School-company relationship management with contract tracking

### **Section B — Architecture & Entities**

**Architecture Overview:**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Layer     │    │  Service Layer  │    │   Data Layer    │
│                 │    │                 │    │                 │
│ • Controllers   │◄──►│ • Policies      │◄──►│ • PostgreSQL    │
│ • Views (ERB)   │    │ • Services      │    │ • Redis         │
│ • Components    │    │ • Jobs (Sidekiq)│    │ • ActiveStorage │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  External APIs  │    │  Background      │    │  File Storage   │
│                 │    │  Processing     │    │                 │
│ • Postmark      │    │ • Email Jobs    │    │ • Cloudinary    │
│ • HTTParty      │    │ • Cleanup Jobs  │    │ • PDFs          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Entity Relationship Map:**

| **Model** | **Key Attributes** | **Relationships** |
|-----------|-------------------|-------------------|
| **User** | email, first_name, last_name, role, admin, super_admin | belongs_to :parent, has_many :children, has_many :projects, has_many :companies, has_many :schools, has_many :badges_received |
| **Company** | name, zip_code, city, status, company_type_id | belongs_to :company_type, has_many :users, has_many :projects, has_many :contracts |
| **School** | name, zip_code, city, school_type, status | has_many :users, has_many :school_levels, has_many :companies, has_many :contracts |
| **Project** | title, description, start_date, end_date, status, owner_id | belongs_to :owner (User), has_many :companies, has_many :school_levels, has_many :project_members, has_many :teams |
| **Badge** | name, description, level, icon | has_many :user_badges, has_many :badge_skills |
| **UserBadge** | project_title, status, sender_id, receiver_id, badge_id | belongs_to :sender (User), belongs_to :receiver (User), belongs_to :badge |
| **ApiAccess** | token, name | has_many :companies (through company_api_accesses) |

### **Section C — API Surface Summary**

**Current API Endpoints:**

| **Method** | **Path** | **Controller#Action** | **Auth Required** | **Purpose** |
|------------|----------|----------------------|-------------------|-------------|
| GET | `/api/v1/companies` | Api::V1::CompaniesController#index | No (admin param) | List companies with filtering |
| GET | `/api/v1/schools` | Api::V1::SchoolsController#index | No (admin param) | List schools with filtering |
| GET | `/api/v2/users` | Api::V2::UsersController#index | API Token | List users with pagination |
| GET | `/api/v2/users/:id` | Api::V2::UsersController#show | API Token | Get user details with skills/badges |

**Authentication Mechanisms:**
- **Web App**: Devise-based session authentication with role-based authorization (Pundit)
- **API V1**: Optional admin parameter for elevated access
- **API V2**: Token-based authentication via `ApiAccess` model

### **Section D — Proposed Step-by-Step Strategy**

**Phase 1: Environment Setup & Analysis**
1. **Verify rswag installation**: Confirm `rswag` gem is properly installed and configured
2. **Check existing specs**: Review current request specs in `spec/requests/api/` directory
3. **Validate swagger_helper.rb**: Ensure configuration matches project structure
4. **Test rswag generation**: Run `bundle exec rake rswag:specs:swaggerize` to verify setup

**Phase 2: API Documentation Generation**
5. **Create comprehensive rswag specs**: Write detailed request specs for all API endpoints
6. **Add authentication examples**: Document token-based auth for V2 endpoints
7. **Include response examples**: Add realistic JSON response examples
8. **Generate OpenAPI JSON**: Run rswag generation to create `swagger/v1/swagger.json`

**Phase 3: Postman Collection Creation**
9. **Convert to Postman format**: Use OpenAPI-to-Postman converter or manual creation
10. **Add authentication setup**: Configure API token authentication in Postman
11. **Create environment variables**: Set up base URLs and test tokens
12. **Add test scenarios**: Include positive/negative test cases

**Phase 4: Testing & Validation**
13. **Test API endpoints**: Verify all documented endpoints work correctly
14. **Validate authentication**: Test both public and protected endpoints
15. **Check response formats**: Ensure JSON responses match documentation
16. **Generate final artifacts**: Create production-ready OpenAPI JSON and Postman collection

### **Section E — Example OpenAPI Fragment**

**GET /api/v2/users endpoint documentation:**

```yaml
/api/v2/users:
  get:
    summary: List users with pagination
    description: Returns paginated list of users accessible to the API token holder
    parameters:
      - name: token
        in: query
        required: true
        schema:
          type: string
        description: API access token
      - name: query
        in: query
        required: false
        schema:
          type: string
        description: Search query for user names
    responses:
      '200':
        description: Successful response
        content:
          application/json:
            schema:
              type: object
              properties:
                data:
                  type: array
                  items:
                    type: object
                    properties:
                      id:
                        type: integer
                      first_name:
                        type: string
                      last_name:
                        type: string
                      email:
                        type: string
                      role:
                        type: string
                meta:
                  type: object
                  properties:
                    count:
                      type: integer
                    pages:
                      type: integer
                    page:
                      type: integer
            example:
              data:
                - id: 1
                  first_name: "John"
                  last_name: "Doe"
                  email: "john@example.com"
                  role: "teacher"
              meta:
                count: 25
                pages: 2
                page: 1
      '401':
        description: Unauthorized - Invalid API token
        content:
          application/json:
            schema:
              type: object
              properties:
                error:
                  type: string
            example:
              error: "Invalid API token"
```

### **Section F — Required Inputs/Credentials**

**Before proceeding with implementation, I need:**

1. **Test API Access Tokens**: 
   - Valid API access token for testing V2 endpoints
   - Instructions for creating new API access tokens via admin panel

2. **Test Data Requirements**:
   - Confirmation of test database state (seeded data, factories)
   - Any specific test users/companies/schools needed for realistic examples

3. **Environment Configuration**:
   - Base URL for API testing (development/staging)
   - Any environment-specific configurations needed

4. **Approval for Changes**:
   - Confirmation to proceed with creating rswag specs
   - Approval for any necessary test data setup
   - Preferred approach for handling missing test fixtures

## **Key Observations & Risks**

- **Limited API Surface**: Only 4 API endpoints currently exist, suggesting this is primarily a web application
- **Mixed Authentication**: V1 endpoints are public with optional admin params, V2 requires token auth
- **No Existing rswag Specs**: Current request specs are empty, requiring full documentation creation
- **Complex Authorization**: V2 endpoints have company-scoped access control that needs careful documentation
- **JSON Serialization**: Controllers use `as_json` with custom includes, requiring detailed response documentation

The project is well-structured for API documentation generation, with rswag already installed and configured. The main work will be creating comprehensive request specs and ensuring proper authentication documentation for the token-based V2 endpoints.

## **Technical Stack Summary**

- **Ruby**: 3.3.7
- **Rails**: 7.1.3.4
- **Database**: PostgreSQL with Redis for caching
- **Authentication**: Devise + Pundit for authorization
- **API Documentation**: rswag (rswag-api, rswag-ui, rswag-specs)
- **Background Jobs**: Sidekiq
- **File Storage**: Cloudinary
- **Email**: Postmark
- **Testing**: RSpec with FactoryBot

## **Next Steps**

1. **Review and approve** this analysis
2. **Provide test credentials** and environment details
3. **Approve implementation plan** for rswag spec creation
4. **Begin Phase 1** of the step-by-step strategy
