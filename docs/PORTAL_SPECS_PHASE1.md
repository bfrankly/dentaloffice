# Phase 1 MVP Portal Specifications

This document defines implementation-ready portal specs for:
- Front Desk Portal
- Hygienist Portal
- Dentist Portal
- Owner Portal
- Patient Portal

Scope is strictly Phase 1 MVP for a single BC clinic.

---

## 1) Shared UX and Platform Requirements (All Portals)

## 1.1 Authentication and Session
- Staff portals: SSO + MFA mandatory.
- Patient portal: passwordless email/SMS OTP + optional MFA for sensitive actions.
- Session timeout:
  - staff: idle 15 min, absolute 8 hours;
  - patient: idle 20 min, absolute 12 hours.
- Step-up auth required for: record export, break-glass, high-value financial actions.

## 1.2 Design System and Accessibility
- Responsive design (desktop-first for staff, mobile-first for patient).
- WCAG 2.1 AA baseline (contrast, focus states, keyboard navigation, form labels).
- Locale support: English baseline, architecture for multilingual content.

## 1.3 Auditability and Privacy UX
- Every material action emits audit event with `purpose_of_use`.
- PHI-sensitive screens show “purpose reminder” banner.
- Print/download actions require reason code and are watermarked.

## 1.4 Performance SLOs
- p95 page load <= 2.5s on clinic broadband.
- p95 interactive API action <= 800ms.
- Schedule board update latency <= 3s.

---

## 2) Front Desk Portal Spec

### 2.1 Primary Users
- Receptionists, treatment coordinators, practice managers (limited views).

### 2.2 Navigation
1. Today Board
2. Appointments
3. Patients
4. Insurance
5. Communications
6. Claims Exceptions (read/write for authorized roles)
7. Tasks

### 2.3 Key Screens and Functional Requirements

| Screen | Required capabilities | Data dependencies | Permissions |
|---|---|---|---|
| Today Board | check-in/out, arrival state, no-show mark, quick reschedule | appointment, patient, provider | receptionist+
| Appointment Book | day/week view by provider/chair, conflict detection, drag-drop reschedule | appointment, operatory_chair, provider | receptionist+
| Patient Quick Intake | register patient, guardian link, insurance capture, consent capture | patient, guardian_link, insurance_plan, consent_artifact | receptionist+
| Communication Center | reminder status, resend template, opt-out management | communication_event, patient prefs | receptionist+ (template-locked)
| Waitlist Fill Panel | ranked candidate list for cancellation fill | appointment, patient preferences, waitlist logic | receptionist+ (auto-fill policy gated)
| Claims Exception List | view missing info/denials; assign to billing | claim, document, approval_request | billing/admin + manager |

### 2.4 Critical Workflows

#### Workflow FD-1: New Patient Registration
1. Search dedupe by name + DOB + phone.
2. Create patient profile.
3. Add guardian (if dependent).
4. Capture insurance details.
5. Capture consent artifacts (treatment + communication).
6. Schedule initial appointment.

**Acceptance criteria**
- No duplicate chart number.
- Consent record version and timestamp stored.
- Audit emitted for create events.

#### Workflow FD-2: Cancellation Slot Fill
1. Slot marked open.
2. System suggests top candidates.
3. Front desk confirms outreach/send.
4. Booking created on acceptance.

**Human approval required** if provider change or policy conflict.

### 2.5 Non-Functional/UX Constraints
- Schedule interactions must not require page reload.
- Visible warning when booking uninsured/high-risk financial cases.
- Bulk patient export not available in this portal.

---

## 3) Hygienist Portal Spec

### 3.1 Primary Users
- Hygienists, hygiene leads.

### 3.2 Navigation
1. My Day
2. Patient Chart (hygiene view)
3. Perio Chart
4. Recare Queue
5. Clinical Notes

### 3.3 Key Screens and Functional Requirements

| Screen | Required capabilities | Data dependencies | Permissions |
|---|---|---|---|
| My Day | patient queue, status transitions, room assignment | appointment, encounter | hygienist |
| Perio Chart | chart pocket depths/bleeding, periodontal updates | chart_entry (perio), encounter | hygienist |
| Hygiene Clinical Note | structured templates + free-text addenda | chart_entry, encounter | hygienist (sign own notes) |
| Recare Queue | view overdue recare and suggest booking | appointment, communication_event | hygienist + coordinator |
| Patient Education | send approved post-visit instructions | communication templates, consent prefs | hygienist (template only) |

### 3.4 Critical Workflows

#### Workflow HY-1: Hygiene Encounter Close
1. Open encounter from My Day.
2. Record perio findings and hygiene notes.
3. Attach patient education note.
4. Sign encounter.
5. Trigger recare recommendation.

**Acceptance criteria**
- Encounter transitions to signed/locked policy path.
- Addendum (not overwrite) for late edits.
- Audit trail records signer, timestamp, purpose.

#### Workflow HY-2: Recare Follow-up Handoff
1. Mark patient as due/overdue.
2. Push candidate to front-desk queue.
3. Optional template reminder send.

### 3.5 Safety/Policy Constraints
- No diagnosis finalization by hygienist role (outside defined scope).
- Any medication/prescription suggestion routes to dentist queue.

---

## 4) Dentist Portal Spec

### 4.1 Primary Users
- Dentists, clinical leads.

### 4.2 Navigation
1. Provider Schedule
2. Encounter Workspace
3. Treatment Plan
4. Clinical Documents/Images
5. Sign/Lock Queue

### 4.3 Key Screens and Functional Requirements

| Screen | Required capabilities | Data dependencies | Permissions |
|---|---|---|---|
| Encounter Workspace | review history, add chart entries, finalize procedures | patient, encounter, chart_entry | dentist |
| Treatment Plan Builder | draft/present/accept plan, estimate values | treatment_plan, invoice estimate view | dentist + coordinator read |
| Sign & Lock Queue | pending encounters requiring signature | encounter status | dentist |
| Clinical Attachments | upload/view encounter-level docs/images | document, encounter | dentist + assistant upload |
| Contraindication Alerts | contextual warnings on chart open | patient medical alerts, chart data | dentist |

### 4.4 Critical Workflows

#### Workflow DE-1: Treatment Plan Finalization
1. Review encounter findings.
2. Create or update treatment plan.
3. Link required consent artifact.
4. Mark plan as presented/accepted.
5. Send to front desk for scheduling and estimate follow-up.

#### Workflow DE-2: Encounter Sign and Lock
1. Review chart entries for encounter.
2. Sign encounter with MFA-backed signature event.
3. Lock encounter.
4. Any future changes require addendum.

**Acceptance criteria**
- Locked encounter cannot be overwritten.
- Addenda are linked and versioned.

### 4.5 Safety/Policy Constraints
- AI-generated clinical text is draft-only; dentist must approve before saving.
- No outbound patient diagnosis messaging without clinician review.

---

## 5) Owner Portal Spec

### 5.1 Primary Users
- Owner, practice manager, regional operator (future).

### 5.2 Navigation
1. Executive Dashboard
2. Financials
3. Operational KPIs
4. Claims Aging
5. Incidents & Complaints
6. Agent/Approval Control Center

### 5.3 Key Screens and Functional Requirements

| Screen | Required capabilities | Data dependencies | Permissions |
|---|---|---|---|
| Executive Dashboard | production, collections, AR, no-show trend cards | analytics mart | owner/manager |
| Claims Aging | unpaid claims by payer/age bucket | claim, payment | owner/manager + billing drill-down |
| Agent Control Center | pending approvals, policy toggles, kill switch | approval_request, agent_task | owner/manager |
| Incident Console | privacy/security incidents and status | privacy incident records, audit signals | owner + privacy officer |
| Drill-down Cards | secure deep links into workflow queues | scoped service APIs | owner with purpose code |

### 5.4 Critical Workflows

#### Workflow OW-1: Approve High-Risk Action
1. Owner opens pending approval card.
2. Reviews risk class, evidence, rollback plan.
3. Approves/rejects with reason.
4. Decision event logged and action released or denied.

#### Workflow OW-2: Global Agent Pause
1. Owner triggers pause by domain/all.
2. System confirms scope + duration.
3. Agent tasks transition to paused state.
4. Notification sent to affected teams.

### 5.5 Policy Constraints
- Default owner access is aggregate; patient-level drill-down requires purpose code and enhanced logging.
- Owner cannot modify signed clinical records.

---

## 6) Patient Portal Spec

### 6.1 Primary Users
- Adult patient, guardian/proxy.

### 6.2 Navigation
1. Home
2. Appointments
3. Forms and Consents
4. Statements and Payments
5. Secure Messages
6. My Privacy (access log, requests)

### 6.3 Key Screens and Functional Requirements

| Screen | Required capabilities | Data dependencies | Permissions |
|---|---|---|---|
| Home | next appointment, outstanding balance, quick actions | appointment, invoice | patient/guardian |
| Appointments | view upcoming/past, request changes | appointment | patient/guardian |
| Forms & Consents | complete/update forms, view consent history | consent_artifact, form data | patient/guardian |
| Statements | view invoices, payment history, pay now | invoice, payment | patient/guardian |
| Secure Messaging | send/receive authenticated messages | communication_event | patient/guardian |
| My Privacy | submit access/correction requests; view recent access log | access_request, correction_request, audit excerpt | patient/guardian |

### 6.4 Critical Workflows

#### Workflow PT-1: Access Request Submission
1. Patient opens My Privacy.
2. Selects request type and scope.
3. Submits request.
4. Receives tracking ID and status updates.

#### Workflow PT-2: Online Payment
1. Patient selects open statement.
2. Completes payment via gateway.
3. Receives confirmation and updated balance.

### 6.5 Privacy and Safety Constraints
- Sensitive records are view-only by default.
- Download/export requires explicit approval path where policy requires.
- Guardian access must be relationship-verified and revocable.

---

## 7) Cross-Portal Role/Permission Matrix (MVP)

| Capability | Front Desk | Hygienist | Dentist | Owner | Patient |
|---|---|---|---|---|---|
| Register patient | ✅ | ❌ | ❌ | ❌ | ❌ |
| Book/reschedule | ✅ | Limited | Limited | View | Request only |
| Create clinical note | ❌ | ✅ | ✅ | ❌ | ❌ |
| Sign/lock encounter | ❌ | Sign own scope | ✅ | ❌ | ❌ |
| Submit claim | Billing role only | ❌ | ❌ | Approve only | ❌ |
| View financial dashboard | Limited | ❌ | Limited | ✅ | Own balance only |
| Approve high-risk agent action | Manager+ | ❌ | Role-specific | ✅ | ❌ |
| Submit access/correction request | Internal route | ❌ | ❌ | ❌ | ✅ |

---

## 8) API Surface by Portal (BFF-Oriented)

- **Front Desk BFF:** patient search/create, booking APIs, intake APIs, reminder APIs.
- **Hygienist BFF:** encounter open/close, perio chart APIs, recare handoff APIs.
- **Dentist BFF:** treatment plan APIs, sign/lock APIs, attachment APIs.
- **Owner BFF:** KPI read models, approvals APIs, agent control APIs.
- **Patient BFF:** appointment view, statements/payments, secure messaging, privacy requests.

BFF services must enforce role-scoped response shaping to minimize PHI exposure.

---

## 9) Telemetry and KPIs per Portal

| Portal | KPI set |
|---|---|
| Front Desk | check-in cycle time, no-show rate, schedule fill rate |
| Hygienist | encounter close time, recare rebook rate, overdue hygiene count |
| Dentist | same-day sign/lock %, treatment acceptance handoff rate |
| Owner | AR>30 trend, production vs target, approval turnaround time |
| Patient | portal adoption, online payment completion, privacy request SLA |

---

## 10) Acceptance Test Checklist (Phase 1)

### Front Desk
- [ ] Register new patient including guardian + insurance + consent in one flow.
- [ ] Reschedule appointment with conflict warning and audit emission.

### Hygienist
- [ ] Complete and sign hygiene encounter with perio chart.
- [ ] Add late-entry addendum without overwriting original note.

### Dentist
- [ ] Finalize treatment plan and sign/lock encounter.
- [ ] Verify contraindication alert appears on chart open.

### Owner
- [ ] Review and decide R3 approval request.
- [ ] Trigger and release global agent pause.

### Patient
- [ ] Submit access request and see status tracking.
- [ ] View/pay statement and receive confirmation.

