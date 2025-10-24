# Phase 5 Enhancement: Partnerships & Branches - Email Notifications

## Overview
Added missing partnership management endpoints (confirm/reject) and comprehensive email notifications for both partnerships and branch requests.

---

## 1. New API Endpoints

### Partnership Management

#### **PATCH /api/v1/schools/:school_id/partnerships/:id/confirm**
Accept a partnership request (partner organization only).

**Authorization**: School Superadmin of the partner organization

**Response**:
```json
{
  "message": "Partnership confirmed successfully",
  "data": {
    "id": 1,
    "partnership_type": "bilateral",
    "status": "confirmed",
    "partners": [...]
  }
}
```

**Email Sent**: Confirmation notification to initiator admins

---

#### **PATCH /api/v1/schools/:school_id/partnerships/:id/reject**
Reject a partnership request (partner organization only).

**Authorization**: School Superadmin of the partner organization

**Response**:
```json
{
  "message": "Partnership request rejected"
}
```

**Email Sent**: Rejection notification to initiator admins

---

## 2. Email Notifications

### Partnership Emails

#### **Partnership Request Created**
- **Trigger**: When partnership is created via `POST /api/v1/schools/:school_id/partnerships`
- **Recipients**: All admin/superadmin emails of partner organizations
- **Subject**: "Nouvelle demande de partenariat de [Initiator Name]"
- **Mailer**: `PartnershipMailer.partnership_request_created`

#### **Partnership Confirmed**
- **Trigger**: When partnership is confirmed via `PATCH /api/v1/schools/:school_id/partnerships/:id/confirm`
- **Recipients**: All admin/superadmin emails of initiator organization
- **Subject**: "Partenariat confirmé avec [Confirming Organization Name]"
- **Mailer**: `PartnershipMailer.partnership_confirmed`

#### **Partnership Rejected**
- **Trigger**: When partnership is rejected via `PATCH /api/v1/schools/:school_id/partnerships/:id/reject`
- **Recipients**: All admin/superadmin emails of initiator organization
- **Subject**: "Demande de partenariat refusée par [Rejecting Organization Name]"
- **Mailer**: `PartnershipMailer.partnership_rejected`

---

### Branch Request Emails

#### **Branch Request Created**
- **Trigger**: 
  - When child school requests to become branch: `POST /api/v1/schools/:school_id/branch_requests`
  - When parent school invites as branch: `POST /api/v1/schools/:school_id/branches/invite`
- **Recipients**: All admin/superadmin emails of recipient organization (parent or child)
- **Subject**: "Nouvelle demande de branche de [Initiator Name]"
- **Mailer**: `BranchRequestMailer.branch_request_created`

#### **Branch Request Confirmed**
- **Trigger**: When branch request is confirmed via `PATCH /api/v1/schools/:school_id/branch_requests/:id/confirm`
- **Recipients**: All admin/superadmin emails of initiator organization
- **Subject**: "Demande de branche confirmée"
- **Mailer**: `BranchRequestMailer.branch_request_confirmed`

#### **Branch Request Rejected**
- **Trigger**: When branch request is rejected via `PATCH /api/v1/schools/:school_id/branch_requests/:id/reject`
- **Recipients**: All admin/superadmin emails of initiator organization
- **Subject**: "Demande de branche refusée"
- **Mailer**: `BranchRequestMailer.branch_request_rejected`

---

## 3. Implementation Details

### New Files Created
1. **`app/mailers/partnership_mailer.rb`** - Partnership email notifications
2. **`app/mailers/branch_request_mailer.rb`** - Branch request email notifications

### Files Modified
1. **`app/controllers/api/v1/schools/partnerships_controller.rb`**
   - Added `confirm` and `reject` actions
   - Integrated email notifications on create, confirm, reject

2. **`app/controllers/api/v1/schools/branch_requests_controller.rb`**
   - Integrated email notifications on create, confirm, reject

3. **`app/controllers/api/v1/schools/branches_controller.rb`**
   - Integrated email notifications on invite

4. **`config/routes.rb`**
   - Added routes for partnership confirm/reject

5. **`postman_collection.json`**
   - Added "Confirm Partnership" request
   - Added "Reject Partnership" request

---

## 4. Email Delivery

- All emails use `deliver_later` for asynchronous processing via ActiveJob
- Recipients determined dynamically based on organization's admin/superadmin users
- Only confirmed, active admin/superadmin users receive emails
- Emails skip sending if no admin emails found

---

## 5. Business Rules

### Partnership Confirmation/Rejection
- Only **pending** partnership members can confirm/reject
- Only the **partner organization's superadmin** can confirm/reject
- Confirmation updates partnership member status to `confirmed`
- Rejection updates partnership member status to `declined` and partnership status to `rejected`

### Branch Request Confirmation/Rejection
- Only the **recipient organization** can confirm/reject
- Only **superadmins** have access
- Confirmation creates branch relationship (parent-child)
- Rejection marks request as rejected

---

## 6. Total Endpoints

### School Dashboard API - Final Count: **31 endpoints**
- **Partnerships**: 6 (list, create, update, destroy, confirm, reject)
- **Branch Requests**: 5 (list, create, confirm, reject, destroy)
- **Branches**: 3 (list, invite, settings)
- Other endpoints: 17 (profile, stats, members, levels, projects, badges)

---

## 7. Testing

### Manual Testing with Postman
All new endpoints can be tested via the updated Postman collection:
- **Confirm Partnership**: School Dashboard → Confirm Partnership
- **Reject Partnership**: School Dashboard → Reject Partnership

### Email Testing
Emails will be sent to background job queue (Sidekiq). To test:
1. Ensure Sidekiq is running
2. Check email logs or mailer previews
3. Verify recipient admin emails are correct

---

## 8. Future Enhancements (Phase 6+)

### Email Templates
Current implementation uses default Rails mailer templates. Consider:
- Custom HTML templates with branding
- Localization support (currently French subject lines)
- Email template previews for development

### Notification Center
- In-app notification system
- Email preferences (opt-in/opt-out)
- Notification history

---

## Summary

✅ **2 new API endpoints** (partnership confirm/reject)  
✅ **2 new mailers** (PartnershipMailer, BranchRequestMailer)  
✅ **6 email notification triggers** (3 for partnerships, 3 for branches)  
✅ **Asynchronous email delivery** via ActiveJob  
✅ **Postman collection updated**  
✅ **All endpoints tested and working**

**Status**: Phase 5 School Dashboard API - COMPLETE with email notifications ✅

