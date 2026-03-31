# Dental Office App v2 — Phase 1 MVP Architecture (BC Clinic)

## 1) MVP Boundary (What We Are Building Now)

### In Scope (Phase 1 Only)
- Patient administration (registration, demographics, guardians, insurance profile, communication preferences, consent capture).
- Scheduling core (provider/chair scheduling, recurring appointments, basic waitlist, cancellation/no-show handling).
- Clinical minimum record (odontogram + progress notes + encounter signing/locking + amendment addenda).
- Billing/claims minimum (ledger, invoices, payments, claim creation, claim aging, payment posting, exception queue).
- Patient communication baseline (appointment reminders, basic recalls from approved templates).
- Patient portal v1 (appointments, forms, statements, secure messaging).
- Security/privacy baseline (RBAC + ABAC-lite, MFA, audit trail, disclosure/access request workflows).
- AI assist-only mode (drafting, triage, queue prioritization; no autonomous irreversible actions).

### Explicitly Out of Scope (Phase 1)
- CBCT advanced workflows.
- Multi-location scheduling/governance.
- Autonomous claim submission.
- Computer-use agent submitting irreversible portal actions.
- AI-assisted diagnostics/clinical recommendations.
- Advanced marketing attribution and campaign automation.

### Design Assumptions
- Single BC clinic initial deployment, 5–30 staff users.
- Existing imaging and accounting tools remain integrated via adapters (not replaced in Phase 1).
- BC PIPA-aligned governance is mandatory at launch.

---

## 2) Phase 1 User Personas and Jobs-to-be-Done

| Persona | Core jobs in MVP | Success metric |
|---|---|---|
| Receptionist | Register patients, maintain schedules, confirmations | Fewer booking errors, reduced no-shows |
| Hygienist | Complete perio/hygiene charting, document notes | Faster chart completion, better rebook rate |
| Dentist | Finalize treatment notes, sign encounters | Same-day encounter closure |
| Finance/Admin | Post payments, manage AR/claims queue | AR>30 reduction, fewer denied claims |
| Practice Manager | Monitor KPIs and exceptions | Higher schedule utilization |
| Privacy Officer | Review access/disclosures/incidents | On-time access request handling |
| Patient/Guardian | Book/view appointments, complete forms, view statements | Portal adoption, lower call volume |

---

## 3) Phase 1 Functional Modules (MVP Detail)

### A. Patient Administration
| Capability | MVP behavior | Human approval required? |
|---|---|---|
| Registration | Create patient profile with dedupe check | No |
| Guardian linking | Link dependent to verified guardian | Yes (if legal docs unclear) |
| Insurance profile | Store primary + secondary payer details | No |
| Consent capture | Capture digital consent with version/time stamp | No |
| Medical alerts | Flag contraindications/allergies | Clinician verification required |
| Document intake | Upload and index intake docs | Yes for sensitive doc final filing |

### B. Scheduling Core
| Capability | MVP behavior | Automation suitability |
|---|---|---|
| Provider/chair scheduling | Conflict-free booking by provider/chair | Good candidate |
| Recurring appointments | Pattern-based follow-up booking | Good candidate |
| Waitlist fill | Suggest top candidates for open slots | Good candidate (approval optional) |
| No-show controls | Confirmation workflows + status tracking | Good candidate |
| Coverage handling | Rebook when provider unavailable | Human approval required if provider changes |

### C. Clinical Minimum Record
| Capability | MVP behavior | Risk |
|---|---|---|
| Odontogram/progress notes | Structured chart + free-text note templates | Medium |
| Encounter signing | Dentist/hygienist sign with timestamp | Medium |
| Encounter lock | Signed encounter immutable; addendum only | Low |
| Amendment/addenda | Late-entry preserved with author/time | Low |
| Consent linkage | Consent artifact linked to treatment entry | Medium |

### D. Billing/Claims Minimum
| Capability | MVP behavior | Human approval required? |
|---|---|---|
| Ledger | Immutable financial transaction history | No |
| Invoices/statements | Generate patient statements | No |
| Payment posting | Manual + remittance-assisted posting | No |
| Claim creation | Draft claim from completed procedures | No |
| Claim submission | Submit via clearinghouse queue | **Yes** |
| Exception queue | Missing fields/attachments/denials queue | No |

### E. Patient Communication + Portal
| Capability | MVP behavior | Risk class |
|---|---|---|
| Reminders | SMS/email reminders from templates | Low |
| Recall basics | Approved recall templates only | Medium |
| Secure messaging | Portal-authenticated messaging | Medium |
| Portal records | View appointments/forms/statements | Low |
| Portal downloads | Restricted, scoped exports only | High (approval-gated) |

---

## 4) Phase 1 Architecture (Production-Ready MVP)

## 4.1 Logical Components
1. **Staff Web App** (React/TS): scheduling, charting, billing, ops queues.
2. **Patient Portal** (web responsive): forms, statements, messages, bookings.
3. **API Gateway**: authn/authz, rate limiting, request tracing.
4. **Identity & Access Service**: RBAC roles + ABAC attributes (clinic, role, relationship, purpose).
5. **Patient Service**: demographics, guardians, preferences, consents.
6. **Scheduling Service**: appointments, provider/chair allocation, waitlist logic.
7. **Clinical Record Service**: encounters, chart entries, signatures, lock/addenda.
8. **Billing & Claims Service**: ledger, invoices, payments, claims, exceptions.
9. **Communication Service**: template engine + SMS/email providers.
10. **Document Service**: intake, indexing, secure object storage.
11. **Audit Service (append-only)**: all material actions/events.
12. **Workflow/Approvals Service**: approval queues for high-risk actions.
13. **Integration Adapters**: clearinghouse, payment processor, imaging links.
14. **Analytics Mart (MVP)**: daily ETL for owner dashboard KPIs.
15. **Agent Orchestrator (Assist Mode)**: bounded task execution only.

## 4.2 Data Stores
- **Primary relational DB (PostgreSQL):** SoR transactional entities.
- **Object storage (encrypted):** documents/attachments and portal artifacts.
- **Event/Audit store (immutable/WORM-capable):** tamper-evident audit logs.
- **Cache (Redis):** short-lived sessions, queue acceleration.

## 4.3 Eventing and Integration Pattern
- **Synchronous APIs:** booking, charting save/sign, payment posting.
- **Asynchronous events:** reminder dispatch, ETL loads, claim status refresh, alerting.

**Core event topics**
- `appointment.created|updated|cancelled`
- `encounter.signed|locked|amended`
- `claim.created|queued|submitted|denied|paid`
- `payment.posted`
- `consent.captured`
- `record.accessed`
- `approval.requested|approved|rejected`

---

## 5) Phase 1 AI/Automation Policy (Assist-Only)

### Allowed Autonomous Actions
- Draft reminder messages from approved templates.
- Prioritize waitlist and claim exception queues.
- Triage inbound portal messages into categories.
- Extract draft fields from intake documents (OCR assist).

### Approval-Gated Actions
- Claim submission to payer.
- Any write-off, refund above threshold.
- Any external message with custom free-text generated by AI.
- Any record export/release containing PHI documents.

### Prohibited in Phase 1
- Autonomous clinical advice/diagnosis messaging.
- Deletion of clinical records.
- Bulk PHI export.
- Policy/retention changes by agent.

---

## 6) Phase 1 Security and Privacy Controls (BC PIPA-Oriented)

### Identity/Access
- MFA mandatory for all staff.
- Role templates: owner, manager, receptionist, hygienist, dentist, assistant, finance, privacy officer, patient.
- ABAC-lite checks: clinic site, treatment relationship, purpose-of-use.

### Data Protection
- TLS in transit; AES-256-equivalent encryption at rest.
- KMS-managed encryption keys with rotation.
- Malware scanning for inbound documents.

### Audit & Governance
- Log every material create/update/view/export action.
- Break-glass flow requires reason + immediate alert to privacy officer.
- Monthly privileged access review; quarterly role recertification.

### Patient Rights Workflow (MVP)
- **Access requests:** intake → identity verification → scoped release package → delivery log.
- **Correction requests:** intake → clinician review → addendum/correction decision → response recorded.
- **Disclosure logging:** every third-party disclosure logged with legal basis and scope.

---

## 7) Phase 1 Owner/Manager Interface (Teams First)

### Supported Commands (MVP)
- `/kpi today`
- `/schedule hygiene next_week`
- `/claims aging over_30`
- `/approvals pending`
- `/incidents open`
- `/pause automation [domain] [duration]`

### Response Design
- KPI cards with trend arrows and thresholds.
- Exception queue cards with deep links.
- Approval cards with risk tag (`R1-R4`), impact summary, and rollback note.

### Kill Switch
- Single command pauses all agent actions immediately.
- Requires manager or owner role + MFA step-up.

---

## 8) Phase 1 Data Model (Minimum Viable SoR)

### Core Entities
- Patient
- GuardianLink
- Provider
- Appointment
- OperatoryChair
- Encounter
- ChartEntry
- TreatmentPlan (minimal)
- InsurancePlan
- Claim
- Invoice
- Payment
- ConsentArtifact
- Document
- CommunicationEvent
- ApprovalRequest
- AgentTask
- AuditEvent
- AccessRequest
- CorrectionRequest

### Record Classifications
- **System of Record:** Patient, Appointment, Encounter, ChartEntry, Claim, Invoice, Payment, ConsentArtifact, AuditEvent.
- **Derived:** KPI aggregates, schedule utilization metrics.
- **Ephemeral:** AI prompt context/task scratchpad (time-limited).

---

## 9) Phase 1 Non-Functional Requirements

### Reliability & Performance
- Availability target: 99.9% monthly.
- p95 API latency target: <400ms for core transactional APIs.
- RPO: 15 minutes; RTO: 4 hours.

### Observability
- Distributed tracing across gateway/services.
- Security/audit dashboards.
- Alerting on failed claim submissions, reminder provider failures, suspicious access spikes.

### Backup/DR
- Encrypted backups with daily restore validation in lower environment.
- Immutable backup snapshots for ransomware resilience.

---

## 10) Phase 1 Implementation Plan (24 Weeks)

### Sprint Group A (Weeks 1–6): Foundation
- Identity, RBAC/ABAC-lite, audit service, API gateway.
- Patient admin service and base UI.

### Sprint Group B (Weeks 7–12): Scheduling + Clinical Minimum
- Scheduling service/UI + recurring + waitlist.
- Clinical record service with signing/locking/addenda.

### Sprint Group C (Weeks 13–18): Billing/Claims + Portal
- Ledger/invoices/payments + claim queue.
- Portal v1 + secure messaging + reminders.

### Sprint Group D (Weeks 19–24): Integrations + Hardening
- Clearinghouse/payment integrations.
- Approval workflows and assistive agents.
- Security hardening, DR tests, pilot launch readiness.

---

## 11) Phase 1 Go-Live Readiness Checklist

### Product/Operations
- [ ] Front desk workflows UAT signed off.
- [ ] Clinical signing/locking UAT signed off.
- [ ] Billing closeout and claim queue validated.

### Compliance
- [ ] Privacy impact assessment completed.
- [ ] Access/correction/disclosure SOPs approved.
- [ ] Staff training and attestation complete.

### Security
- [ ] MFA and session policies enforced.
- [ ] Audit logs immutable and queryable.
- [ ] Backup restore drill passed.

### Launch
- [ ] Pilot clinic cutover plan approved.
- [ ] Hypercare staffing (2–4 weeks) assigned.
- [ ] Rollback plan documented and tested.

---

## 12) Phase 1 KPI Set (First 90 Days)
- Schedule utilization % (overall and hygiene).
- No-show rate.
- Claim first-pass acceptance rate.
- AR > 30 days amount and trend.
- Encounter closure within 24 hours.
- Patient portal adoption rate.
- Access request turnaround time.
- Agent-assisted task time saved (minutes/day).

