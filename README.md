# dentaloffice

Phase 1 now includes a runnable backend foundation (FastAPI + SQLAlchemy) plus architecture/spec artifacts.

## Run Phase 1 API

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Run tests:

```bash
pytest -q
```

## Current artifacts
- `app/` — Phase 1 API implementation (patients, appointments, encounters, approvals, audit writes).
- `tests/` — API workflow tests.
- `db/schema_phase1.sql` — PostgreSQL schema for full Phase 1 data model.
- `BLUEPRINT_V2.md` — Phase 1 MVP architecture blueprint.
- `docs/SERVICE_BOUNDARIES_PHASE1.md` — service ownership and API/event boundaries.
- `docs/AGENT_APPROVAL_MATRIX_AND_HIGH_RISK_WORKFLOWS.md` — approval matrix and high-risk workflow controls.
- `docs/BC_PRIVACY_GOVERNANCE_GAP_ANALYSIS_PHASE1.md` — BC privacy/governance gap analysis and remediation plan.
- `docs/PORTAL_SPECS_PHASE1.md` — implementation specs for front desk, hygienist, dentist, owner, and patient portals.
- `docs/IMPLEMENTATION_PACK_PHASE1_12W.md` — build-vs-buy, 12-week roadmap, normalized model, APIs, risk register, approvals, owner interfaces, and failure safeguards.
- `docs/PHASE1_EXACT_MVP_SCOPE.md` — exact Phase 1 launch scope, exclusions, safety boundaries, and go-live gates.
