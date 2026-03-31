# Phase 1 Implementation Pack (Concrete)

Based on the current architecture set, this document provides:
1) Build-vs-buy matrix
2) 12-week roadmap
3) Normalized data model
4) API contracts for core services
5) BC privacy risk register
6) Human-approval matrix for all agent actions
7) Microsoft Teams owner interface spec
8) WhatsApp owner interface alternative
9) Highest-risk failure modes and safeguards

---

## 1) Build-vs-Buy Matrix

| Capability | Build/Buy | Recommendation | Rationale | Vendor-lock risk | Exit strategy | Phase |
|---|---|---|---|---|---|---|
| Core patient/clinical SoR | Build | Build | Clinic-specific workflows + audit constraints | Medium | Strict domain APIs + migration scripts | Week 1–12 start |
| Scheduling engine | Build | Build | Deep chair/provider logic is product differentiator | Low | Keep logic in service layer | Week 1–8 |
| Billing/claims domain | Build | Build | Requires policy control + local adaptations | Medium | Adapter layer around clearinghouse | Week 4–12 |
| Identity (SSO/OIDC) | Buy | Buy | Security maturity and reduced auth risk | Low | Standards-based OIDC/SAML abstraction | Week 1–3 |
| SMS/email delivery | Buy | Buy | Commodity infra, high deliverability ops burden | Low | Provider adapter with template neutrality | Week 5–8 |
| Payment gateway | Buy | Buy | PCI burden reduction | Medium | Gateway abstraction + tokenized refs only | Week 6–10 |
| Document e-sign | Buy | Buy | Faster legal/compliance readiness | Medium | Keep signed artifacts in internal document store | Week 6–10 |
| Event bus | Build on managed | Hybrid | Managed broker, internal schemas/contracts | Low | Versioned event contracts | Week 2–6 |
| BI/warehouse | Build on managed | Hybrid | Internal metric definitions, managed storage/compute | Low | dbt-like model portability | Week 8–12 |
| LLM/model endpoint | Buy + abstract | Hybrid | Need flexibility and safety controls | Medium | Model gateway with provider routing | Week 7–12 |
| OCR/doc extraction | Buy first | Buy->Build later | Faster intake MVP | Medium | Keep extracted schema internal | Week 7–10 |
| SIEM/log analytics | Buy | Buy | Security operations maturity | Low | Export raw logs to cold storage | Week 5–12 |

---

## 2) 12-Week Product Roadmap (Execution-Level)

| Week | Product goals | Engineering deliverables | Compliance/security deliverables | Exit criteria |
|---|---|---|---|---|
| 1 | Foundation setup | Repo modules, CI/CD, env baseline | Privacy officer assigned, control owners mapped | Environments + owners live |
| 2 | Identity baseline | OIDC integration, role claims, user provisioning | MFA policy drafted | Staff login with MFA works |
| 3 | Patient admin v1 | patient/guardian/insurance/consent APIs + UI | Consent language review | New patient intake E2E |
| 4 | Scheduling v1 | provider/chair booking, conflict checks | Audit event taxonomy finalized | Book/reschedule/cancel flow passes UAT |
| 5 | Clinical v1 | encounter + chart entries + addenda | Encounter lock/sign policy approved | Clinician can sign + lock encounters |
| 6 | Billing v1 | invoices/payments ledger core | Financial approval thresholds approved | Daily closeout report generated |
| 7 | Claims v1 | claim draft/queue + exception queue | Claim submission approval SOP | Claims reach approval queue reliably |
| 8 | Comms + portal basics | reminders + patient portal auth/home | Communication consent enforcement tests | Reminder send + opt-out verified |
| 9 | Owner visibility | owner KPI dashboard + pending approvals view | Owner access limitation policy tested | Owner sees aggregate dashboards only |
| 10 | Agent assist mode | triage/recall draft agents + approvals integration | Agent R0–R4 test suite | Agents perform draft-only actions |
| 11 | Privacy workflows | access/correction request workflows + disclosure log | PIA draft + breach runbook v1 | Rights-request lifecycle test passes |
| 12 | Hardening/pilot prep | performance, reliability fixes, cutover scripts | tabletop incident drill + go-live checklist | Pilot go/no-go sign-off |

---

## 3) Normalized Data Model (3NF-Oriented)

## 3.1 Core Entity Groups

| Domain | Tables (normalized) | Notes |
|---|---|---|
| Identity | `app_user`, `provider` | user identity separated from provider profile |
| Patient admin | `patient`, `guardian_link`, `insurance_plan`, `consent_artifact` | one-to-many links preserve history |
| Scheduling | `appointment`, `operatory_chair` | appointment references patient/provider/chair |
| Clinical | `encounter`, `chart_entry`, `treatment_plan` | chart entries separated from encounter header |
| Financial | `invoice`, `payment`, `claim` | payment references invoice; claim references plan/insurance |
| Workflow | `approval_request`, `agent_task` | approval links human/agent initiation |
| Compliance | `access_request`, `correction_request` | explicit patient-rights entities |
| Governance | `audit_event`, `document`, `communication_event` | immutable and evidence-oriented logging |

## 3.2 Key Normalization Decisions

| Decision | Why |
|---|---|
| Separate `patient` from `insurance_plan` | preserves multiple coverage records and priority sequencing |
| Separate `encounter` from `chart_entry` | allows multiple structured entries and addenda per encounter |
| Separate `invoice`, `payment`, `claim` | avoids update anomalies and supports independent lifecycle states |
| Keep `approval_request` independent | supports approvals for any action/entity via payload refs |
| Use `document` as shared evidence table | single index for clinical/claims/consent attachments |
| Store `audit_event` append-only | immutable trace without mutating business tables |

## 3.3 Missing Tables to Add (Next Migration)

| Table | Purpose | Priority |
|---|---|---|
| `retention_rule` | retention policy by entity class | P0 |
| `legal_hold` | overrides destruction and enforces holds | P0 |
| `disclosure_log` | explicit disclosure accounting ledger | P0 |
| `privacy_incident` | lifecycle of privacy/security incidents | P1 |
| `waitlist_item` | normalized waitlist candidates/state | P1 |
| `appointment_status_history` | immutable booking status trail | P1 |

---

## 4) API Contracts for Core Services

## 4.1 Identity & Access Service

| Endpoint | Method | Request (required fields) | Response | Error cases |
|---|---|---|---|---|
| `/auth/token` | POST | `grant_type`, credentials/assertion | access token + claims | 401 invalid auth |
| `/authz/check` | POST | `subject`, `action`, `resource`, `context.purpose_of_use` | `allow`, `policy_id`, `obligations` | 403 denied, 422 missing purpose |
| `/users/{id}/roles` | PATCH | `roles[]`, `effective_at` | updated role set | 409 conflicting role policy |

## 4.2 Patient Service

| Endpoint | Method | Request | Response | Notes |
|---|---|---|---|---|
| `/patients` | POST | demographic + contact | `patient_id`, chart number | dedupe pre-check required |
| `/patients/search` | GET | name/dob/phone/email | patient list | paginated |
| `/patients/{id}/guardians` | POST | guardian relationship + proof ref | guardian link | requires purpose code |
| `/patients/{id}/insurance-plans` | POST | payer fields + priority | plan id | priority uniqueness per patient |
| `/patients/{id}/consents` | POST | `consent_type`, version, status | consent id | immutable version history |

## 4.3 Scheduling Service

| Endpoint | Method | Request | Response | Notes |
|---|---|---|---|---|
| `/appointments` | POST | patient, provider, chair, start/end | appointment id + status | conflict check mandatory |
| `/appointments/{id}` | PATCH | start/end/chair/status | updated appointment | emits status event |
| `/appointments/{id}/cancel` | POST | reason code | cancelled state | records cancellation reason |
| `/waitlist/suggestions` | POST | slot + policy constraints | ranked candidates | includes confidence score |

## 4.4 Clinical Record Service

| Endpoint | Method | Request | Response | Notes |
|---|---|---|---|---|
| `/encounters` | POST | patient, appointment, provider | encounter id | one active encounter per appointment |
| `/encounters/{id}/entries` | POST | `entry_type`, body_json | entry id | schema-validated JSON |
| `/encounters/{id}/sign` | POST | signature context | signed encounter | step-up auth for signer |
| `/encounters/{id}/lock` | POST | lock reason | locked encounter | immutable after lock |
| `/encounters/{id}/addendum` | POST | addendum payload + reference | new linked entry | no overwrite allowed |

## 4.5 Billing & Claims Service

| Endpoint | Method | Request | Response | Notes |
|---|---|---|---|---|
| `/invoices` | POST | patient, lines, totals | invoice id | totals validated server-side |
| `/payments` | POST | invoice, method, amount | payment id | checks overpayment policy |
| `/claims` | POST | invoice, insurance plan, amount | claim id draft | scrub precheck attached |
| `/claims/{id}/queue-submit` | POST | approval reason | approval request id | R3 approval required |
| `/claims/{id}/status` | PATCH | target status + evidence | updated claim | controlled transitions only |

## 4.6 Compliance Service

| Endpoint | Method | Request | Response | Notes |
|---|---|---|---|---|
| `/compliance/access-requests` | POST | requester identity + scope | request id | SLA timer starts |
| `/compliance/correction-requests` | POST | target record + request note | request id | routed to clinical reviewer |
| `/compliance/disclosures` | GET | filters | disclosure list | privacy officer scope |

---

## 5) BC Privacy Risk Register (Operational)

| ID | Risk | Likelihood | Impact | Inherent risk | Current controls | Residual risk | Owner | Mitigation due |
|---|---|---|---|---|---|---|---|---|
| PR-01 | Unauthorized chart access by staff | Medium | High | High | RBAC + audit events | Medium | Privacy Officer | Week 8 |
| PR-02 | Consent revocation not propagated quickly | Medium | High | High | consent artifacts + manual checks | Medium | Product/Backend | Week 9 |
| PR-03 | Improper record export/disclosure | Low | Very High | High | approval gates + watermark | Medium | Compliance Lead | Week 10 |
| PR-04 | Missing retention/destruction enforcement | Medium | Very High | Critical | policy intent only | High | Data Platform Lead | Week 11 |
| PR-05 | Breach runbook untested | Medium | High | High | draft process | Medium | Security Lead | Week 11 |
| PR-06 | Agent sends unsafe external communication | Medium | High | High | template locks + R3 gating | Medium | AI Safety Lead | Week 10 |
| PR-07 | Cross-border processing ambiguity | Low | High | Medium | architecture note only | Medium | Privacy Officer | Week 12 |
| PR-08 | Break-glass overuse without review | Low | High | Medium | reason + alert workflow | Low-Med | Security Ops | Week 12 |

---

## 6) Human-Approval Matrix for All Agent Actions

| Agent action | Risk class | Default mode | Required approver(s) | SLA | Evidence required | Auto-stop condition |
|---|---|---|---|---|---|---|
| Waitlist ranking | R1 | Auto | None | N/A | scoring trace | >10% ranking failures/day |
| Auto-fill cancellation slot | R2 | Policy toggle | Reception mgr if toggle off | 15 min | slot match rationale | provider mismatch |
| Reminder send (template) | R2 | Auto | Manager optional | N/A | template ID + consent check | opt-out mismatch |
| Custom recall message | R3 | Approval | Coordinator/Manager | 30 min | message draft + cohort | clinical claim detected |
| Insurance benefits fetch | R1 | Auto | None | N/A | portal trace | domain mismatch/captcha loop |
| Claim draft creation | R1 | Auto | None | N/A | scrub score + fields | scrub score below threshold |
| Claim submit | R3 | Approval | Billing lead | 2 hours | scrub report + attachments | duplicate/idempotency failure |
| Denial follow-up template send | R2 | Auto/Approval | Billing manager (policy) | 60 min | template + claim refs | legal-language violation |
| Refund/write-off recommendation | R3 | Approval | Finance admin (+manager >threshold) | 2 hours | amount + reason code | threshold breach without second approver |
| Inbound message triage | R1 | Auto | None | N/A | classification confidence | confidence below floor |
| Clinical response suggestion | R4 | Disabled | Dentist + manager | Same day | clinician-reviewed draft | any direct send attempt |
| OCR intake mapping | R1 | Auto | None | N/A | extraction confidence + diffs | sensitive doc ambiguity |
| Finalize release package | R3/R4 | Approval | Privacy officer (+2nd approver if sensitive) | 1 day | legal basis + scope manifest | missing legal basis |
| Owner KPI digest | R0 | Auto | None | N/A | query provenance | data freshness failure |
| Owner patient drill-down | R3 | Approval | Manager/Privacy policy | 30 min | purpose code | absent purpose code |
| Access anomaly flagging | R1 | Auto | None | N/A | anomaly score + context | detector drift alarm |
| Computer-use portal retrieval | R2 | Auto/Approval | Billing manager (policy) | 30 min | session recording | non-allowlisted domain |
| Irreversible computer-use submission | R4 | Disabled by default | Dual (billing lead + privacy/manager) | Same day | full action plan | any missing approval token |

---

## 7) Microsoft Teams Owner Interface Spec

## 7.1 Scope
- Secure owner/manager command and approval surface integrated with approval workflow and analytics APIs.

## 7.2 Command Set (MVP)

| Command | Purpose | Response card | Actionable? |
|---|---|---|---|
| `/kpi today` | daily KPI snapshot | KPI summary card | Drill-down links |
| `/schedule hygiene next_week` | hygiene utilization | capacity card | optional approve outreach |
| `/claims aging over_30` | unpaid claims | payer aging card | open queue |
| `/approvals pending` | approval queue | risk-class cards | approve/reject |
| `/agents pause [scope] [duration]` | pause automation | confirmation card | yes |
| `/incidents open` | privacy/security incidents | incident card | assign/escalate |
| `/why task {id}` | explain agent action | evidence trace card | no |

## 7.3 Security/Compliance Controls
- Entra ID SSO + MFA.
- Owner role defaults to aggregate-only metrics.
- Patient-level access requires purpose code + enhanced audit.
- Approval actions require card re-auth (step-up) for R3/R4.

## 7.4 Teams Card Schema (minimal)
- `card_id`
- `risk_class`
- `summary`
- `impact`
- `evidence_refs[]`
- `expires_at`
- `actions[]` (approve/reject/escalate/open)

---

## 8) WhatsApp Owner Interface Alternative

## 8.1 Scope
- Alternative lightweight command channel for owners using WhatsApp Business API.

## 8.2 Design Constraints
- No PHI-rich payloads in chat text.
- Send summarized metrics and secure deep links to web console for details.
- Require one-time confirmation code for approvals.

## 8.3 Command Set

| Command | Reply style | Restrictions |
|---|---|---|
| `kpi today` | concise KPI text + link | aggregate only |
| `claims 30+` | count + amount + link | no patient identifiers |
| `approvals` | numbered pending list | approve via signed deep link |
| `pause agents` | confirmation flow | owner/manager only |
| `why <taskid>` | short rationale + evidence link | no raw PHI in chat |

## 8.4 Security Controls
- Verify sender against allowlist of owner numbers.
- Enforce per-message HMAC validation (via webhook secret).
- Expiring deep links (<10 min) for sensitive views.
- Auto-redact identifiers in outbound text templates.

## 8.5 When to Prefer Teams vs WhatsApp
- Prefer **Teams** for enterprises using M365 and richer approval cards.
- Prefer **WhatsApp** for speed/convenience when owners are mobile-first.
- Keep both as thin shells over same approval and analytics APIs.

---

## 9) Highest-Risk Failure Modes and Safeguards

| Failure mode | Trigger example | Impact | Preventive safeguards | Detective safeguards | Recovery action |
|---|---|---|---|---|---|
| Duplicate claim submissions | retry without idempotency | financial and payer errors | idempotency keys, state machine guard | duplicate detector report | auto-void queue + manual review |
| Wrong-patient scheduling edits | fast UI interaction error | care disruption/privacy risk | strong patient context header, confirm dialogs | audit anomaly for rapid patient switches | revert from status history + notify staff |
| Unauthorized patient drill-down by owner | curiosity access | privacy breach | purpose code enforcement + policy gate | weekly access review + alerts | incident review + retraining/discipline |
| Agent sends disallowed outbound text | prompt drift/template bypass | legal/clinical risk | template lock + content filter | outbound QA sampling + policy violation alerts | recall message + incident ticket |
| Improper record export | wrong recipient/scope | severe privacy incident | dual approval + recipient verification + watermark | disclosure log reconciliation | breach protocol + revoke links |
| Break-glass abuse | repeated non-emergency use | trust/compliance risk | strict reason list + step-up MFA + TTL | automatic repeat-pattern detection | access suspension + formal review |
| OCR misclassification of sensitive docs | low-quality scan | wrong chart attachment | confidence thresholds + human validation | mismatch/error queue | detach/reassign + notify privacy officer |
| Event bus lag/loss | infra incident | stale dashboards/missed actions | durable queues + retries + dead-letter | lag monitors + heartbeat alerts | replay from DLQ + reconcile jobs |
| Audit logging outage | downstream service failure | weak forensic trail | local buffer + guaranteed delivery retry | missing-sequence monitors | backfill events + incident RCA |
| Consent revocation race condition | stale cache | non-compliant messaging | cache TTL + revocation priority event | consent violation detector | halt campaign + notify impacted patients |

