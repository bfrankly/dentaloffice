# BC Privacy/Governance Gap Analysis (Phase 1 MVP)

**Date:** 2026-03-27  
**Scope assessed:**
- `BLUEPRINT_V2.md`
- `db/schema_phase1.sql`
- `docs/SERVICE_BOUNDARIES_PHASE1.md`
- `docs/AGENT_APPROVAL_MATRIX_AND_HIGH_RISK_WORKFLOWS.md`

**Purpose:** Identify BC private-sector privacy and governance gaps (PIPA-oriented) between current architecture artifacts and minimum launch-ready controls for a dental clinic.

> This is an implementation gap analysis, not legal advice. BC counsel should validate legal interpretations and deadlines.

---

## 1) Assessment Method

### 1.1 Maturity Scale
- **0 = Missing** (not defined)
- **1 = Partial** (defined conceptually, not enforceable)
- **2 = Implementing** (control design exists and is testable)
- **3 = Operational** (implemented, monitored, evidenced)

### 1.2 Risk Rating
- **Critical:** likely non-compliance or high patient harm/exposure risk.
- **High:** major governance weakness requiring pre-launch mitigation.
- **Medium:** meaningful deficiency; can be time-boxed with compensating controls.
- **Low:** improvement opportunity; can be post-launch hardening.

---

## 2) Executive Gap Summary

| Domain | Current score | Target at go-live | Gap severity | Go-live status |
|---|---:|---:|---|---|
| Privacy management program | 1 | 3 | High | Blocked until program artifacts complete |
| Purpose/consent governance | 2 | 3 | Medium | Conditionally ready with policy engine tests |
| Access controls/least privilege | 2 | 3 | Medium | Conditionally ready with role recertification process |
| Patient access/correction rights | 2 | 3 | Medium | Conditionally ready with SLA workflow evidence |
| Disclosure governance/logging | 2 | 3 | Medium | Conditionally ready with release-of-record SOP |
| Retention/destruction controls | 1 | 3 | **Critical** | **Blocked** |
| Breach response readiness | 1 | 3 | High | Blocked until runbook + drills complete |
| Vendor/processor oversight | 1 | 3 | High | Blocked until contract/control register complete |
| Agent governance + approvals | 2 | 3 | Medium | Conditionally ready with policy-as-code enforcement |
| Auditability + monitoring | 2 | 3 | Medium | Conditionally ready with integrity verification |

**Top blockers before pilot launch:**
1. Retention/destruction rule implementation + legal hold handling.
2. Breach response runbook with assigned roles and simulation drill.
3. Vendor/subprocessor governance package (agreements + transfer mapping).
4. Privacy management program artifacts (policy suite, training attestations, review cadence).

---

## 3) Detailed Gap Register

| # | Control area | Expected control (BC private-sector practical baseline) | Current state | Gap | Severity | Recommended remediation | Owner | Target date |
|---:|---|---|---|---|---|---|---|---|
| 1 | Privacy management program | Formal privacy policy suite, designated privacy officer authority, review cadence, staff attestations | Privacy officer role noted; no full operating program package | Missing governance evidence set | High | Create privacy management program binder: policies, procedures, annual review schedule, attestation tracker | Privacy Officer | Pre-pilot |
| 2 | Purpose specification | Purpose-of-use codes enforced in access and workflows | Purpose codes appear in design; enforcement not yet defined end-to-end | Partial runtime enforcement | Medium | Add mandatory `purpose_of_use` field validation in APIs and audit events; block null purpose on PHI reads | Engineering Lead | Sprint 2 |
| 3 | Consent lifecycle | Capture/revoke/version consent by purpose and timestamp | Consent table exists; revocation propagation behavior not defined | Revocation may not stop downstream automation fast enough | Medium | Implement consent decision service and cache invalidation SLA (<5 min) | Product + Backend | Sprint 3 |
| 4 | Least privilege | RBAC + ABAC + periodic access review | RBAC/ABAC-lite defined; recertification process not operational | Governance process gap | Medium | Add monthly privileged review workflow and quarterly role recertification evidence report | IT Admin + Privacy Officer | Pre-pilot |
| 5 | Patient access rights | Request intake, verification, timeline tracking, secure fulfillment | Access request entity exists; SLA and notice templates absent | Operational completeness gap | Medium | Build access request SOP + SLA dashboard + fulfillment templates | Compliance Lead | Sprint 4 |
| 6 | Correction rights | Intake, clinical review, addendum decision, response tracking | Correction entity exists; adjudication policy not formalized | Inconsistent handling risk | Medium | Publish correction adjudication rubric and clinician review routing | Clinical Lead | Sprint 4 |
| 7 | Disclosure logging | Log legal basis, recipient, scope, timestamp for every disclosure | Audit model supports metadata; release workflow evidence not standardized | Incomplete disclosure traceability | Medium | Create disclosure event schema contract and mandatory checklist in release workflow | Compliance Lead | Sprint 5 |
| 8 | Retention/destruction | Rule-based retention periods, legal hold override, destruction evidence | Mentioned in blueprint but no implemented table/engine in schema | Missing enforceable mechanism | **Critical** | Add `retention_rule` + `legal_hold` data model and destruction job with evidence receipts | Data Platform Lead | Sprint 5 |
| 9 | Breach response | Incident triage, containment, notification decision tree, post-incident review | Incident concepts documented; no executable runbook/drills | Readiness gap | High | Create breach runbook, severity matrix, 24h/72h action checklists; run tabletop quarterly | Security Lead + Privacy Officer | Pre-pilot |
| 10 | Vendor governance | Contractual controls, subprocessor register, due diligence cadence, cross-border mapping | Integration docs exist; vendor governance artifacts not present | Third-party risk unmanaged | High | Build vendor register, DPA checklist, annual reassessment schedule, data flow maps | Procurement + Privacy Officer | Pre-pilot |
| 11 | Cross-border processing transparency | Declare storage/access locations and safeguards | Architecture mentions options; no tenant-level data residency enforcement rule | Potential transparency gap | Medium | Add tenant data-residency flag and cross-border exception approval workflow | Platform Lead | Sprint 6 |
| 12 | Sensitive record segmentation | Additional controls for specially sensitive attachments | Concept present in workflows, not modeled as data tags/policies | Overexposure risk | Medium | Add document sensitivity labels + policy checks (view-only, dual-approval export) | Backend Lead | Sprint 6 |
| 13 | Break-glass governance | Step-up auth, reason code, time-limited access, mandatory review | Defined in high-risk workflow doc; no measurable SLA metrics pipeline yet | Review completion risk | Medium | Add break-glass SLA monitor and auto-escalation for overdue reviews | Security Ops | Sprint 6 |
| 14 | Employee monitoring boundaries | Monitoring for security/compliance without excessive surveillance | Principle stated; no policy text distinguishing allowed monitoring | HR/privacy policy ambiguity | Medium | Publish employee monitoring policy and notice language aligned to purpose limitation | Privacy Officer + HR | Pre-pilot |
| 15 | Audit integrity | Immutable logs with integrity verification and access controls | Append-only model defined; cryptographic verification cadence not specified | Tamper detection incompleteness | Medium | Add hash-chain/day-seal verification and monthly integrity report | Security Engineering | Sprint 5 |
| 16 | Agent policy-as-code | Enforce R0–R4 matrix at runtime, not documentation only | Matrix documented; enforcement service not yet implemented | Drift between policy and execution | High | Implement centralized policy engine + signed policy bundles + CI tests | Agent Platform Lead | Sprint 5 |
| 17 | AI training/data minimization | Restrict PHI in model prompts/logs; define retention TTLs | Ephemeral context intent exists; log redaction controls unspecified | PHI overexposure risk | High | Add prompt redaction layer, PHI classifier, prompt log TTL and purge jobs | AI Safety Lead | Sprint 4 |
| 18 | Patient transparency | Provide patient-visible log of file access/disclosures | Mentioned in blueprint; no portal feature spec and API contract yet | Trust/transparency gap | Medium | Add portal endpoint for “recent access to your file” with purpose codes | Product + Portal Team | Sprint 6 |

---

## 4) Legal/Compliance Review Required (Priority)

The following items should be explicitly reviewed by BC counsel/privacy counsel before launch:
1. Record retention schedule by record class (clinical, financial, communication, audit, backups).
2. Release-of-record decision criteria and required proofs for third-party requests.
3. Cross-border processing notices, consent language, and contractual protections.
4. Breach notification thresholds and external communications workflow.
5. Employee monitoring policy language and workforce notices.

---

## 5) Control Additions Recommended for Schema/Services

## 5.1 Schema Additions (next migration)
Add tables:
- `retention_rule` (entity_type, retention_period, legal_basis, destroy_method, active_flag)
- `legal_hold` (scope_type, scope_id, reason, placed_by, placed_at, released_at)
- `disclosure_log` (patient_id, request_id, recipient, legal_basis, scope, disclosed_at)
- `privacy_incident` (severity, status, detected_at, contained_at, root_cause, report_refs)
- `vendor_processor` (name, jurisdiction, data_categories, contract_status, review_due_at)

## 5.2 Service/Workflow Additions
- Compliance Service: retention decision engine + destruction scheduler + legal-hold checks.
- Document Service: sensitivity label enforcement and export watermark service.
- Approval Service: policy conditions for cross-border export and sensitive bundles.
- Audit Service: integrity verification job + evidence export for compliance review.

---

## 6) 90-Day Remediation Plan (Before and After Pilot)

| Window | Must complete | Deliverables |
|---|---|---|
| Days 0–30 | Close blockers: retention model, breach runbook, vendor register skeleton | DB migration scripts, incident playbook v1, vendor inventory v1 |
| Days 31–60 | Operationalize rights workflows and role reviews | Access/correction SOPs, SLA dashboard, recertification reports |
| Days 61–90 | Harden audit and agent governance | Policy-as-code engine, audit integrity checks, break-glass SLA monitor |

---

## 7) Evidence Pack Required for Go-Live Sign-Off

1. Privacy management program document set and revision history.
2. PIA report with residual risk log and mitigation owners.
3. Access/correction/disclosure SOPs with training completion records.
4. Retention/destruction policy implementation evidence (including legal hold test cases).
5. Breach runbook test report (tabletop outcome + corrective actions).
6. Vendor risk register and executed contract checklist.
7. Agent approval policy tests (R0–R4) and blocked-action test evidence.
8. Audit immutability/integrity verification report.

---

## 8) Residual Risk Statement (If launching with compensating controls)

If pilot must launch before all medium gaps are closed:
- Keep all R2+ external agent actions under manager approval.
- Disable record export automation (manual privacy officer workflow only).
- Freeze cross-border processing unless explicitly approved per vendor.
- Increase privacy/security monitoring cadence to weekly until controls are fully operational.

