# Phase 1 MVP — Agent Approval Matrix and High-Risk Workflow Design

This document defines how agent actions are risk-classified, approved, executed, and audited in Phase 1.

## 1) Risk Classification Model

| Risk Class | Definition | Example actions | Default execution mode |
|---|---|---|---|
| R0 Informational | Read-only, no external side effect | summarize queue, compute KPI | Auto |
| R1 Internal Draft | Internal draft/output; no irreversible state change | draft reminder text, triage labels | Auto with logging |
| R2 External Low-Impact | External communication or state change within approved templates/rules | send approved appointment reminder template | Auto if policy allows; otherwise manager approval |
| R3 Financial/Record Impact | Affects money movement, legal records, or payer submission state | queue claim submission, refund above threshold, record export package prep | Mandatory human approval |
| R4 Legal/Compliance Critical | Irreversible high-impact legal/compliance/security action | regulator response, retention policy changes, bulk PHI export | Dual approval + privacy/compliance sign-off |

## 2) Agent Approval Matrix (Phase 1)

Legend:
- **Auto** = no human approval required.
- **Mgr** = practice manager or designated supervisor.
- **Role** = role-specific approver (e.g., billing lead, privacy officer).
- **Dual** = two approvers required.

| Agent | Action | Risk | Approval | Hard constraints | Fallback on failure |
|---|---|---|---|---|---|
| Scheduling Agent | Rank waitlist for open slot | R1 | Auto | No direct booking if provider mismatch rule hits | Route to receptionist queue |
| Scheduling Agent | Auto-fill cancellation slot | R2 | Auto/Mgr policy toggle | Use approved patient cohorts and template only | Hold slot + alert receptionist |
| Recall Agent | Send recall using approved template | R2 | Auto/Mgr policy toggle | Respect communication consent and quiet hours | Defer and create exception task |
| Recall Agent | Send customized free-text outreach | R3 | Mgr | No clinical claims language | Convert to draft for coordinator |
| Insurance Verification Agent | Pull benefits snapshot | R1 | Auto | Allowed portals only | Open manual verification task |
| Claims Preparation Agent | Build claim draft + attachments list | R1 | Auto | Must pass scrub checks; no submit | Send to billing queue |
| Claims Agent | Submit claim to clearinghouse | R3 | Role (billing lead) | Approval token required; idempotency key required | Keep in queued state |
| Billing Follow-up Agent | Send payer follow-up template | R2 | Auto/Mgr | Template locked; no legal assertions | Escalate to billing specialist |
| Billing Follow-up Agent | Apply write-off or refund > threshold | R3 | Role (finance admin) | Threshold + reason code mandatory | Create pending approval request |
| Inbox/Triage Agent | Categorize inbound messages | R1 | Auto | No clinical advice generation | Escalate uncertain messages |
| Inbox/Triage Agent | Reply with clinical interpretation | R4 | Dual (dentist + manager) | Disabled in Phase 1 by policy | Block and route to clinician |
| Document Intake Agent | OCR parse + draft data map | R1 | Auto | Do not finalize sensitive filing | Queue for receptionist validation |
| Document Intake Agent | Finalize record release package | R3 | Role (privacy officer) | Scope + legal basis required | Keep package locked |
| Owner Intelligence Agent | Daily KPI summary | R0 | Auto | Aggregate-only by default | Re-run with cached data |
| Owner Intelligence Agent | Patient-level drill-down action | R3 | Mgr + purpose code | Justification + enhanced logging | Return aggregate only |
| Compliance Guard Agent | Flag suspicious access pattern | R1 | Auto | Never auto-discipline users | Create incident ticket |
| Computer Use Agent | Fetch claim status from payer portal | R2 | Auto/Mgr | Domain allowlist + session recording | Abort session and alert billing |
| Computer Use Agent | Irreversible portal submission | R4 | Dual (billing lead + privacy/manager) | Disabled by default in Phase 1 | Block and request manual execution |

## 3) Approval Policy Object (Implementation Contract)

Each policy row should compile to a machine-enforceable object:

```json
{
  "action_key": "claims.submit",
  "risk_class": "R3",
  "allowed_actor": ["claims_agent"],
  "required_approvers": ["billing_lead"],
  "approval_ttl_minutes": 120,
  "requires_reason_code": true,
  "requires_evidence": ["scrub_score", "attachment_checklist"],
  "execution_guards": ["idempotency_key", "payer_endpoint_allowlist"],
  "rollback_strategy": "reversal_queue",
  "audit_event_names": ["approval.requested", "approval.approved", "claim.submitted"]
}
```

## 4) High-Risk Workflow Design

## Workflow A — Claim Submission (R3)

### Trigger
- Claim draft reaches “ready-to-submit” and scrub score >= threshold.

### Steps
1. Claims Agent creates `approval_request` with payload hash, scrub report, and attachment checklist.
2. Billing lead receives approval card (amount, payer, patient ID masked, exceptions).
3. Billing lead approves/rejects with reason code.
4. On approval, system issues one-time execution token (short TTL) to Claims Agent.
5. Claims Agent submits claim via clearinghouse adapter.
6. Result event written to audit and claim status updated.

### Mandatory controls
- Idempotency key to prevent duplicate submission.
- Approval expires automatically; requires re-approval after TTL.
- Fail-closed: if adapter or response uncertain, claim remains queued.

### Audit events
- `approval.requested`, `approval.approved|rejected`, `claim.submitted|submission_failed`.

---

## Workflow B — Record Export / Release-of-Records (R3/R4 depending scope)

### Trigger
- Patient access request or third-party legal request requiring release package.

### Steps
1. Compliance Service validates request identity + authority.
2. Document Intake Agent compiles scoped package draft (never auto-send).
3. Privacy officer reviews scope, legal basis, and sensitive attachment flags.
4. If high-sensitivity data included, second approver required (manager/legal delegate).
5. System applies watermarking and generates expiring secure delivery link.
6. Disclosure log entry created with recipient, purpose, and dataset scope.

### Mandatory controls
- View-only default; download requires explicit approval toggle.
- Bulk export is blocked without R4 dual approval.
- Every export artifact has unique watermark ID.

### Audit events
- `access_request.received`, `export.package_created`, `approval.approved`, `record.exported`, `disclosure.logged`.

---

## Workflow C — High-Value Refund/Write-off (R3)

### Trigger
- Finance workflow requests refund/write-off above configured threshold.

### Steps
1. Billing Follow-up Agent prepares transaction recommendation and evidence.
2. Finance admin approval required with mandatory reason code taxonomy.
3. System enforces dual-control if amount exceeds secondary threshold.
4. Approved transaction posted with immutable ledger reference.
5. Notification sent to manager daily exception digest.

### Mandatory controls
- Threshold policy by clinic, role, and action type.
- No agent direct ledger mutation without approval token.
- Reversal path must be available and logged.

### Audit events
- `refund.requested|writeoff.requested`, `approval.*`, `payment.adjustment.posted`.

---

## Workflow D — Break-Glass Patient Record Access (R4)

### Trigger
- Emergency patient safety event requiring immediate expanded chart access.

### Steps
1. User selects break-glass reason from controlled list.
2. Step-up MFA challenge required.
3. Temporary scoped access granted (time-boxed).
4. Real-time alert to privacy officer + manager.
5. Mandatory post-event review within 1 business day.

### Mandatory controls
- No silent break-glass allowed.
- Access auto-expires.
- Repeat break-glass patterns trigger investigation.

### Audit events
- `break_glass.requested`, `break_glass.granted`, `record.accessed`, `break_glass.review_completed`.

## 5) Human Approval UX Requirements

Approval cards must include:
- action and risk class,
- impacted records (minimized identifiers),
- financial/clinical/compliance impact summary,
- policy checks passed/failed,
- rollback plan,
- TTL expiry timer,
- "Explain why agent proposed this" evidence trace.

Approval actions:
- Approve,
- Reject (reason required),
- Request changes,
- Escalate to second approver.

## 6) Safety Guardrails and Runtime Controls

- Fail-closed by default for R3/R4.
- Max autonomous retries (default 1) before human escalation.
- Prompt-injection defenses for computer-use tasks (domain + DOM controls).
- Strict output filters to block legal/clinical diagnosis claims in outbound AI messages.
- Emergency kill switch to pause all agent execution globally or by domain.

## 7) KPI and Monitoring Set for Approval System

### Safety KPIs
- Policy violation rate per 1,000 agent actions.
- Unauthorized action attempts blocked.
- Reversal/correction rate after approved actions.

### Operational KPIs
- Median approval turnaround time by risk class.
- Approval backlog size and SLA breach rate.
- False-positive rate of high-risk flags.

### Trust/Compliance KPIs
- Audit completeness (expected vs emitted events).
- Break-glass review completion within SLA.
- Patient complaint count linked to agent-mediated actions.

## 8) Phase 1 Default Policy Recommendations

- Enable Auto only for R0/R1.
- Enable R2 Auto only for reminders/recalls using approved templates and consent checks.
- Require single approver for all R3 actions.
- Require dual approver + privacy/compliance role for all R4 actions.
- Keep irreversible computer-use submissions disabled by default until Phase 2 evidence supports expansion.

