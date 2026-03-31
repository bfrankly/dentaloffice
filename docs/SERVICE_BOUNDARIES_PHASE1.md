# Phase 1 MVP Service Boundaries

This document defines ownership boundaries, APIs, and event contracts for the Phase 1 MVP.

## 1) Service Ownership Matrix

| Service | Owns data (write authority) | Read dependencies | Public API responsibilities |
|---|---|---|---|
| Identity & Access Service | `app_user`, role policy metadata | none | authn/authz, role claims, ABAC policy check |
| Patient Service | `patient`, `guardian_link`, `insurance_plan`, `consent_artifact` | Identity | patient CRUD, guardian management, insurance profile, consent lifecycle |
| Scheduling Service | `appointment`, `operatory_chair` | Patient, Provider | booking lifecycle, provider/chair conflict checks, waitlist operations |
| Clinical Record Service | `encounter`, `chart_entry`, `treatment_plan` | Patient, Scheduling, Provider | encounter lifecycle, signing/locking, chart addenda |
| Billing & Claims Service | `invoice`, `payment`, `claim` | Patient, Clinical Record, Insurance | invoicing, payment posting, claim creation/status |
| Document Service | `document` | Patient, Clinical, Claims | secure upload/indexing, attachment resolution |
| Communication Service | `communication_event` | Patient, Scheduling | reminders, recall templates, message status tracking |
| Approval Workflow Service | `approval_request` | Billing, Patient, Agents | approval intake/decision, policy-driven gating |
| Agent Orchestrator | `agent_task` | all domain APIs (no direct DB writes outside owned table) | task planning, bounded execution, escalation |
| Compliance Service | `access_request`, `correction_request` | Patient, Clinical, Audit | rights-request workflows, disclosure tracking |
| Audit Service | `audit_event` (append-only) | all service event streams | immutable event ingestion/search |

## 2) Hard Boundary Rules

1. A service may **write only** to its owned tables.
2. Cross-domain updates must occur through service APIs/events, never direct DB writes.
3. Cross-service reads should use:
   - synchronous API call for transactional decisions;
   - read models/materialized views for dashboards/reporting.
4. Agent Orchestrator is policy-constrained and can only call exposed domain APIs.
5. Approval Workflow Service must mediate all R3/R4 actions (claim submit, record export, high-value refunds/write-offs).

## 3) Canonical API Contracts (Phase 1)

## Identity & Access
- `POST /auth/token`
- `GET /auth/me`
- `POST /authz/check` (subject, action, resource, context)

## Patient
- `POST /patients`
- `GET /patients/{patientId}`
- `PATCH /patients/{patientId}`
- `POST /patients/{patientId}/guardians`
- `POST /patients/{patientId}/insurance-plans`
- `POST /patients/{patientId}/consents`

## Scheduling
- `POST /appointments`
- `PATCH /appointments/{appointmentId}`
- `POST /appointments/{appointmentId}/cancel`
- `POST /waitlist/suggestions`

## Clinical Record
- `POST /encounters`
- `POST /encounters/{encounterId}/entries`
- `POST /encounters/{encounterId}/sign`
- `POST /encounters/{encounterId}/lock`
- `POST /encounters/{encounterId}/addendum`

## Billing & Claims
- `POST /invoices`
- `POST /payments`
- `POST /claims`
- `POST /claims/{claimId}/queue-submit` (creates approval request)
- `PATCH /claims/{claimId}/status`

## Documents
- `POST /documents/upload`
- `GET /documents/{documentId}`
- `POST /documents/{documentId}/attach`

## Communication
- `POST /communications/reminders/send`
- `POST /communications/recall/send-template`
- `GET /communications/events`

## Approvals
- `POST /approvals`
- `GET /approvals/pending`
- `POST /approvals/{approvalId}/approve`
- `POST /approvals/{approvalId}/reject`

## Compliance
- `POST /compliance/access-requests`
- `POST /compliance/correction-requests`
- `GET /compliance/disclosures`

## Audit
- `POST /audit/events` (internal service use only)
- `GET /audit/events` (privacy officer/auditor scoped)

## 4) Event Contracts (Asynchronous)

Core event names (from services to bus):
- `patient.created`, `patient.updated`, `consent.captured`
- `appointment.created`, `appointment.updated`, `appointment.cancelled`, `appointment.no_show`
- `encounter.signed`, `encounter.locked`, `encounter.amended`
- `invoice.created`, `payment.posted`
- `claim.created`, `claim.queued`, `claim.submitted`, `claim.denied`, `claim.paid`
- `approval.requested`, `approval.approved`, `approval.rejected`
- `communication.sent`, `communication.failed`
- `agent.task.completed`, `agent.task.failed`
- `record.accessed`, `record.exported`, `break_glass.used`

Event payload minimum:
- `event_id` (UUID)
- `event_name`
- `occurred_at` (UTC ISO timestamp)
- `actor_type` / `actor_id`
- `entity_type` / `entity_id`
- `tenant_id` (or clinic_id)
- `correlation_id`
- `payload_version`

## 5) Synchronous vs Asynchronous Decision Guide

Use synchronous API calls when:
- booking needs immediate conflict validation,
- encounter signing/locking needs immediate policy decision,
- claim queueing needs immediate approval-policy check.

Use asynchronous events when:
- reminders are sent,
- analytics/read models are updated,
- non-blocking notifications and audits are generated.

## 6) Phase 1 Deployment Topology (Practical)

- Start as a **modular monolith codebase** with strict module boundaries and independent DB schemas/owners.
- Deploy services as separate processes for: Identity, Patient, Scheduling, Clinical, Billing, Audit, Approvals.
- Keep event bus and workflow engine in place from day 1 to avoid re-architecture during Phase 2.

## 7) Boundary-Related Anti-Patterns to Ban

- Direct foreign-service table writes.
- Sharing one “superuser” DB credential among services.
- Letting agents call database directly.
- Embedding approval logic inside UI-only checks.
- Emitting business events without versioned payload schema.

