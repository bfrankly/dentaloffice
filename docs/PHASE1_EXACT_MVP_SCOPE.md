# Phase 1 Only — Exact MVP Scope Recommendation

Goal: define the smallest commercially useful, operationally safe, privacy-manageable MVP for a BC dental clinic.

---

## 1) MVP Scope Decision (Exact)

### 1.1 Include in Phase 1 Launch

| Domain | Include exactly | Why commercially useful | Safety/privacy posture |
|---|---|---|---|
| Patient admin | patient profile, guardians, insurance profile, communication preferences, consent capture | Enables front desk replacement and billing accuracy | Low risk if RBAC + audit enforced |
| Scheduling | provider/chair calendar, recurring appointments, cancellation + waitlist fill (human-confirmed) | Immediate value: schedule efficiency and no-show reduction | Safe with conflict checks + no fully autonomous rebooking |
| Clinical minimum | encounter shell, progress notes, odontogram basics, sign + lock + addendum | Clinician adoption requires chairside documentation continuity | Safe if immutable sign/lock and role restrictions |
| Billing core | invoice, payment posting, AR aging, daily closeout report | Strong ROI driver for clinic owners | Moderate risk manageable with approval thresholds |
| Claims baseline | claim draft creation, scrub checks, queue for human submission | Revenue cycle improvement without risky auto-submits | Safe if submission always human-approved |
| Patient communications | appointment reminders, recall templates (approved only), secure portal messaging | Reduces no-shows and improves retention | Template-locked messaging lowers risk |
| Patient portal v1 | appointment view/request, forms, statements/payments, access/correction request intake | Competitive baseline and call-volume reduction | Safe with scoped views and strict auth |
| Owner visibility | aggregate KPI dashboard (production, collections, AR, no-show), approval queue view | Owner can manage business performance early | Aggregate-only default minimizes PHI overreach |
| Governance core | immutable audit log, role management, approval workflow, disclosure log, incident intake | Required for trust and BC privacy posture | Foundational safety control |

### 1.2 Exclude from Phase 1 (Too Risky for First Release)

| Exclude item | Why too risky now | Safer alternative in Phase 1 |
|---|---|---|
| Autonomous claim submission | financial and payer error blast radius | Human-submit queue with pre-scrub |
| Autonomous refunds/write-offs | fraud/compliance risk | Approval-gated manual finance workflow |
| AI-generated clinical advice to patients | clinical liability and patient safety risk | Draft-only internal suggestions |
| AI diagnosis/imaging interpretation | medical/legal risk and model uncertainty | No diagnostic AI in MVP |
| Bulk record exports/self-service bulk download | privacy breach risk | Scoped export via privacy workflow |
| Cross-border data processing by default | regulatory and trust ambiguity | Canada-region default + exception-only review |
| Computer-use irreversible actions | brittle automation + irreversibility | Read-only/status retrieval only |
| Multi-location/DSO controls | complexity beyond single-clinic MVP | Single-clinic tenancy only |
| Marketing automation campaigns with dynamic AI copy | consent/compliance and reputational risk | Static approved templates only |

---

## 2) Commercially Useful Package (What Clinics Will Pay For Immediately)

| Feature package | Buyer pain solved | KPI impact (first 90 days target) |
|---|---|---|
| Front desk acceleration | scheduling chaos + intake rework | no-show rate -10% to -20% |
| Billing and AR control | delayed collections and poor visibility | AR>30 down 10%+ |
| Claims prep queue | staff time and denial rework | first-pass claim acceptance +5% |
| Patient self-service lite | inbound call overload | portal adoption >30%, calls down |
| Owner control center | blind spots in operations | daily decision cycle shortened |

This package is “sellable” without introducing unacceptable safety/legal risk.

---

## 3) Operational Safety Boundaries (Hard Launch Rules)

1. **No irreversible external action without human approval** (claims submit, refunds, exports).
2. **Clinical record immutability after signature** (addendum-only edits).
3. **Template-locked outbound communications** for all automated sends.
4. **Purpose-of-use required** for patient-level privileged views.
5. **Break-glass access requires step-up auth + next-day review**.
6. **Owner defaults to aggregate data**; patient drill-down is exception-based and logged.

---

## 4) Privacy-Manageable Launch Controls (Minimum Set)

| Control | Minimum launch implementation |
|---|---|
| Authentication | MFA for staff; strong patient portal auth |
| Authorization | RBAC + treatment-relationship constraints |
| Auditability | append-only audit events for view/create/update/export/approve |
| Consent | versioned capture + revocation handling |
| Disclosure accounting | mandatory disclosure log for external sharing |
| Rights handling | access/correction request workflows with SLAs |
| Incident response | breach runbook + incident ticketing |
| Data residency | Canada-region default deployment |
| Export safety | watermark + scoped package + approval gate |

---

## 5) Exact MVP Backlog (Build List)

## P0 (Must ship for MVP)
- Identity + RBAC + MFA
- Patient admin core + consents
- Scheduling core + conflict checks + waitlist suggestions
- Encounter + chart entry + sign/lock/addendum
- Invoice + payment posting + AR aging
- Claim draft/scrub/queue (no auto-submit)
- Reminder service + template management
- Patient portal: appointments/forms/statements/messages
- Approval workflow service (R3/R4)
- Immutable audit log + basic compliance reporting

## P1 (Ship in first 4–8 weeks after MVP)
- Enhanced denial management queue
- Privacy portal “who accessed my file” view
- Role recertification workflow and reports
- Break-glass SLA monitor

## Deferred (Phase 2+)
- Computer-use write actions
- AI autonomy beyond draft/triage
- Multi-site tenancy and cross-site scheduling
- Advanced imaging integrations and diagnostics AI

---

## 6) Agent Scope Allowed in Phase 1 (Strict)

| Agent | Allowed | Not allowed |
|---|---|---|
| Scheduling Agent | rank waitlist, suggest fill-ins | direct rebooking without confirmation |
| Recall Agent | send approved templates to consented cohorts | custom AI copy without approval |
| Claims Agent | draft and scrub claims | submit claims autonomously |
| Billing Agent | prioritize AR queues | post write-offs/refunds |
| Inbox Agent | classify/route messages | clinical interpretations to patient |
| Owner Intelligence Agent | KPI summaries + exception cards | unrestricted chart retrieval |
| Computer Use Agent | payer status lookup/read tasks | irreversible submissions or data exports |

---

## 7) Go-Live Readiness Gates (Must Pass)

| Gate | Pass criteria |
|---|---|
| Clinical safety gate | sign/lock/addendum rules validated in UAT |
| Financial safety gate | approval thresholds active for all R3 actions |
| Privacy gate | access/correction/disclosure workflows tested end-to-end |
| Security gate | MFA enforced, audit ingestion complete, incident runbook tested |
| Operational gate | front-desk and billing teams trained with SOP sign-off |

If any gate fails, launch is delayed.

---

## 8) Recommended Commercial Launch Offer (Single Clinic)

**“MVP Core Operations Pack”**
- Front desk + scheduling
- Clinical documentation minimum
- Billing/claims queue
- Patient self-service lite
- Owner dashboard + approval center
- Privacy/governance core controls

This is the minimum set that is:
- commercially useful (clear ROI),
- operationally safe (human-in-the-loop for risk),
- privacy-manageable (BC-ready controls).

