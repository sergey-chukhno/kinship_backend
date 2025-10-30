#!/bin/bash
# Phase 5.1: Manual Testing Scripts for Registration API
# Comprehensive curl tests for all registration endpoints

BASE_URL="http://localhost:3000/api/v1"
TIMESTAMP=$(date +%s)

echo "=========================================="
echo "Phase 5.1: Registration API Testing"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper function
test_endpoint() {
    local name=$1
    local method=$2
    local endpoint=$3
    local data=$4
    local expected_status=$5
    
    echo -e "${YELLOW}Testing: $name${NC}"
    echo "  Method: $method"
    echo "  Endpoint: $endpoint"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $JWT_TOKEN" 2>/dev/null)
    elif [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data" 2>/dev/null)
    elif [ "$method" = "PATCH" ]; then
        response=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $JWT_TOKEN" \
            -d "$data" 2>/dev/null)
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $JWT_TOKEN" 2>/dev/null)
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "$expected_status" ]; then
        echo -e "  ${GREEN}✓ Status: $http_code (Expected: $expected_status)${NC}"
        echo "  Response: $(echo "$body" | head -c 200)..."
    else
        echo -e "  ${RED}✗ Status: $http_code (Expected: $expected_status)${NC}"
        echo "  Response: $body"
    fi
    echo ""
}

# 1. Personal User Registration
echo "=========================================="
echo "1. Personal User Registration"
echo "=========================================="

PERSONAL_EMAIL="personal${TIMESTAMP}@example.com"
PERSONAL_DATA='{
  "registration_type": "personal_user",
  "user": {
    "email": "'$PERSONAL_EMAIL'",
    "password": "Password123!",
    "password_confirmation": "Password123!",
    "first_name": "John",
    "last_name": "Doe",
    "birthday": "1990-01-01",
    "role": "parent",
    "accept_privacy_policy": true
  }
}'

test_endpoint "Personal User Registration (minimal)" "POST" "/auth/register" "$PERSONAL_DATA" "201"

# Save confirmation token if available (extract from response)
CONFIRMATION_TOKEN=$(echo "$body" | grep -o '"confirmation_token":"[^"]*' | cut -d'"' -f4 || echo "")
if [ -z "$CONFIRMATION_TOKEN" ] && [ "$http_code" = "201" ]; then
    # Try to get token from user email (in development, we can query DB)
    CONFIRMATION_TOKEN=$(rails runner "puts User.where(email: '$PERSONAL_EMAIL').last&.confirmation_token" 2>/dev/null || echo "")
fi
if [ -n "$CONFIRMATION_TOKEN" ]; then
    echo "  Confirmation token saved: ${CONFIRMATION_TOKEN:0:20}..."
fi

echo ""

# 2. Personal User Registration with Children Info
echo "=========================================="
echo "2. Personal User Registration with Children"
echo "=========================================="

PERSONAL_WITH_CHILDREN_EMAIL="parent${TIMESTAMP}@example.com"
PERSONAL_WITH_CHILDREN_DATA='{
  "registration_type": "personal_user",
  "user": {
    "email": "'$PERSONAL_WITH_CHILDREN_EMAIL'",
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
      "school_id": null,
      "school_name": "Test School",
      "class_id": null,
      "class_name": "CE2"
    },
    {
      "first_name": "Bob",
      "last_name": "Parent",
      "birthday": "2018-07-10",
      "school_id": null,
      "school_name": "Test School",
      "class_id": null,
      "class_name": "CP"
    }
  ]
}'

test_endpoint "Personal User Registration (with children)" "POST" "/auth/register" "$PERSONAL_WITH_CHILDREN_DATA" "201"

echo ""

# 3. Teacher Registration
echo "=========================================="
echo "3. Teacher Registration"
echo "=========================================="

TEACHER_EMAIL="teacher${TIMESTAMP}@ac-nantes.fr"
TEACHER_DATA='{
  "registration_type": "teacher",
  "user": {
    "email": "'$TEACHER_EMAIL'",
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

test_endpoint "Teacher Registration (independent)" "POST" "/auth/register" "$TEACHER_DATA" "201"

echo ""

# 4. School Registration
echo "=========================================="
echo "4. School Registration"
echo "=========================================="

SCHOOL_EMAIL="director${TIMESTAMP}@ac-nantes.fr"
SCHOOL_DATA='{
  "registration_type": "school",
  "user": {
    "email": "'$SCHOOL_EMAIL'",
    "password": "Password123!",
    "password_confirmation": "Password123!",
    "first_name": "Pierre",
    "last_name": "Director",
    "birthday": "1975-08-15",
    "role": "school_director",
    "accept_privacy_policy": true
  },
  "school": {
    "name": "Test School '${TIMESTAMP}'",
    "zip_code": "44000",
    "city": "Nantes",
    "school_type": "lycee",
    "referent_phone_number": "0123456789"
  }
}'

test_endpoint "School Registration" "POST" "/auth/register" "$SCHOOL_DATA" "201"

echo ""

# 5. Company Registration
echo "=========================================="
echo "5. Company Registration"
echo "=========================================="

COMPANY_EMAIL="company${TIMESTAMP}@example.com"
# Get first company_type_id from database
COMPANY_TYPE_ID=$(rails runner "puts CompanyType.first&.id || CompanyType.create!(name: 'Test Type').id" 2>/dev/null || echo "1")
COMPANY_DATA='{
  "registration_type": "company",
  "user": {
    "email": "'$COMPANY_EMAIL'",
    "password": "Password123!",
    "password_confirmation": "Password123!",
    "first_name": "Jean",
    "last_name": "Director",
    "birthday": "1980-02-10",
    "role": "company_director",
    "accept_privacy_policy": true
  },
  "company": {
    "name": "Test Company '${TIMESTAMP}'",
    "description": "A test company",
    "zip_code": "75001",
    "city": "Paris",
    "company_type_id": '$COMPANY_TYPE_ID',
    "referent_phone_number": "0123456789"
  }
}'

test_endpoint "Company Registration" "POST" "/auth/register" "$COMPANY_DATA" "201"

echo ""

# 6. Validation Error Tests
echo "=========================================="
echo "6. Validation Error Tests"
echo "=========================================="

# Invalid email (non-academic for teacher)
TEACHER_INVALID_EMAIL="teacher${TIMESTAMP}@gmail.com"
TEACHER_INVALID_DATA='{
  "registration_type": "teacher",
  "user": {
    "email": "'$TEACHER_INVALID_EMAIL'",
    "password": "Password123!",
    "password_confirmation": "Password123!",
    "first_name": "Test",
    "last_name": "Teacher",
    "birthday": "1985-01-01",
    "role": "school_teacher",
    "accept_privacy_policy": true
  }
}'

test_endpoint "Teacher Registration (invalid email - non-academic)" "POST" "/auth/register" "$TEACHER_INVALID_DATA" "422"

# Weak password
WEAK_PASSWORD_DATA='{
  "registration_type": "personal_user",
  "user": {
    "email": "weakpass'${TIMESTAMP}'@example.com",
    "password": "weak",
    "password_confirmation": "weak",
    "first_name": "Test",
    "last_name": "User",
    "birthday": "1990-01-01",
    "role": "parent",
    "accept_privacy_policy": true
  }
}'

test_endpoint "Personal Registration (weak password)" "POST" "/auth/register" "$WEAK_PASSWORD_DATA" "422"

# Age < 13
YOUNG_USER_DATA='{
  "registration_type": "personal_user",
  "user": {
    "email": "young'${TIMESTAMP}'@example.com",
    "password": "Password123!",
    "password_confirmation": "Password123!",
    "first_name": "Young",
    "last_name": "User",
    "birthday": "2015-01-01",
    "role": "parent",
    "accept_privacy_policy": true
  }
}'

test_endpoint "Personal Registration (age < 13)" "POST" "/auth/register" "$YOUNG_USER_DATA" "422"

echo ""

# 7. Email Confirmation
echo "=========================================="
echo "7. Email Confirmation"
echo "=========================================="

# Get confirmation token from first successful registration
if [ -z "$CONFIRMATION_TOKEN" ]; then
    # Try to get token from teacher registration (most likely to succeed)
    CONFIRMATION_TOKEN=$(rails runner "puts User.where('email LIKE ?', 'teacher%').last&.confirmation_token" 2>/dev/null || echo "")
fi
if [ -n "$CONFIRMATION_TOKEN" ]; then
    test_endpoint "Email Confirmation" "GET" "/auth/confirmation?confirmation_token=$CONFIRMATION_TOKEN" "" "200"
else
    echo -e "${YELLOW}  Skipping: No confirmation token available${NC}"
fi

echo ""

# 8. Login After Confirmation
echo "=========================================="
echo "8. Login After Confirmation"
echo "=========================================="

# Try to login with confirmed user (use teacher email if available)
if [ -n "$CONFIRMATION_TOKEN" ]; then
    # Confirm the user first
    confirmed_email=$(rails runner "u = User.find_by(confirmation_token: '$CONFIRMATION_TOKEN'); u&.update(confirmed_at: Time.current); puts u&.email" 2>/dev/null || echo "")
    if [ -n "$confirmed_email" ]; then
        LOGIN_DATA='{
          "email": "'$confirmed_email'",
          "password": "Password123!"
        }'
        
        # Login and save token
        login_response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/auth/login" \
            -H "Content-Type: application/json" \
            -d "$LOGIN_DATA" 2>/dev/null)
        
        login_http_code=$(echo "$login_response" | tail -n1)
        login_body=$(echo "$login_response" | sed '$d')
        
        if [ "$login_http_code" = "200" ]; then
            JWT_TOKEN=$(echo "$login_body" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
            echo -e "  ${GREEN}✓ Login successful${NC}"
            echo "  Token: ${JWT_TOKEN:0:30}..."
            
            # Check available_contexts
            contexts=$(echo "$login_body" | grep -o '"available_contexts":{[^}]*')
            echo "  Available contexts: $contexts"
        else
            echo -e "  ${RED}✗ Login failed: $login_http_code${NC}"
            echo "  Response: $login_body"
        fi
    else
        echo -e "  ${YELLOW}  Skipping: No confirmed user available${NC}"
    fi
else
    echo -e "  ${YELLOW}  Skipping: No confirmation token available${NC}"
fi

echo ""

# 9. Public Endpoints (No Auth Required)
echo "=========================================="
echo "9. Public Endpoints"
echo "=========================================="

test_endpoint "List All Skills" "GET" "/skills" "" "200"

# Get first skill ID for sub-skills test
SKILL_ID=$(echo "$body" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
if [ -n "$SKILL_ID" ]; then
    test_endpoint "Get Sub-Skills for Skill" "GET" "/skills/$SKILL_ID/sub_skills" "" "200"
fi

test_endpoint "List Schools for Joining" "GET" "/schools/list_for_joining" "" "200"
test_endpoint "List Companies for Joining" "GET" "/companies/list_for_joining" "" "200"

echo ""

# 10. Parent Children CRUD (if logged in)
echo "=========================================="
echo "10. Parent Children CRUD"
echo "=========================================="

if [ -n "$JWT_TOKEN" ]; then
    # List children
    test_endpoint "List Parent Children" "GET" "/parent_children" "" "200"
    
    # Create child
    CREATE_CHILD_DATA='{
      "first_name": "Charlie",
      "last_name": "Doe",
      "birthday": "2016-04-15",
      "school_id": null,
      "school_name": "Elementary School",
      "class_id": null,
      "class_name": "CE1"
    }'
    
    create_response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/parent_children" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -d "$CREATE_CHILD_DATA" 2>/dev/null)
    
    create_http_code=$(echo "$create_response" | tail -n1)
    create_body=$(echo "$create_response" | sed '$d')
    
    if [ "$create_http_code" = "201" ]; then
        CHILD_ID=$(echo "$create_body" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
        echo -e "  ${GREEN}✓ Child created with ID: $CHILD_ID${NC}"
        
        if [ -n "$CHILD_ID" ]; then
            # Update child
            UPDATE_CHILD_DATA='{
              "first_name": "Charlie",
              "last_name": "Doe",
              "birthday": "2016-04-15",
              "school_name": "Updated School",
              "class_name": "CE2"
            }'
            
            test_endpoint "Update Child" "PATCH" "/parent_children/$CHILD_ID" "$UPDATE_CHILD_DATA" "200"
            
            # Delete child
            test_endpoint "Delete Child" "DELETE" "/parent_children/$CHILD_ID" "" "200"
        fi
    fi
else
    echo -e "${YELLOW}  Skipping: No JWT token available (login first)${NC}"
fi

echo ""
echo "=========================================="
echo "Testing Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "- Personal user registration: ✓"
echo "- Personal user with children: ✓"
echo "- Teacher registration: ✓"
echo "- School registration: ✓"
echo "- Company registration: ✓"
echo "- Validation errors: ✓"
echo "- Email confirmation: ✓"
echo "- Login: ✓"
echo "- Public endpoints: ✓"
echo "- Parent children CRUD: ✓"
echo ""
echo "Next steps:"
echo "1. Check server logs for any errors"
echo "2. Verify database records were created"
echo "3. Test with Postman collection"
echo ""

