-- Dental Office App v2 - Phase 1 MVP Schema (PostgreSQL)
-- Scope: single-clinic BC launch with clean service ownership boundaries.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------- shared types ----------
CREATE TYPE user_role AS ENUM (
  'owner',
  'practice_manager',
  'receptionist',
  'treatment_coordinator',
  'hygienist',
  'dentist',
  'assistant',
  'finance_admin',
  'it_admin',
  'privacy_officer',
  'external_billing',
  'auditor',
  'patient'
);

CREATE TYPE appointment_status AS ENUM (
  'scheduled', 'confirmed', 'arrived', 'in_chair', 'completed', 'cancelled', 'no_show'
);

CREATE TYPE encounter_status AS ENUM ('draft', 'signed', 'locked', 'amended');
CREATE TYPE claim_status AS ENUM ('draft', 'queued', 'submitted', 'paid', 'denied', 'voided');
CREATE TYPE approval_status AS ENUM ('pending', 'approved', 'rejected', 'expired', 'cancelled');
CREATE TYPE actor_type AS ENUM ('human', 'agent', 'system');
CREATE TYPE access_request_status AS ENUM ('received', 'in_review', 'fulfilled', 'rejected', 'withdrawn');
CREATE TYPE correction_request_status AS ENUM ('received', 'in_review', 'approved', 'denied', 'completed');

-- ---------- utility trigger ----------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------- identity + roles ----------
CREATE TABLE app_user (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  external_auth_subject TEXT UNIQUE,
  email TEXT UNIQUE,
  display_name TEXT NOT NULL,
  role user_role NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_app_user_updated
BEFORE UPDATE ON app_user
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE provider (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES app_user(id),
  provider_code TEXT UNIQUE NOT NULL,
  provider_type TEXT NOT NULL CHECK (provider_type IN ('dentist', 'hygienist', 'assistant', 'other')),
  license_number TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_provider_updated
BEFORE UPDATE ON provider
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------- patient administration ----------
CREATE TABLE patient (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chart_number TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  sex_at_birth TEXT,
  preferred_name TEXT,
  phone TEXT,
  email TEXT,
  address_line1 TEXT,
  address_line2 TEXT,
  city TEXT,
  province TEXT,
  postal_code TEXT,
  preferred_language TEXT,
  communication_opt_in_sms BOOLEAN NOT NULL DEFAULT FALSE,
  communication_opt_in_email BOOLEAN NOT NULL DEFAULT FALSE,
  medical_alerts TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_patient_name_dob ON patient(last_name, first_name, date_of_birth);
CREATE INDEX idx_patient_phone ON patient(phone);
CREATE INDEX idx_patient_email ON patient(email);

CREATE TRIGGER trg_patient_updated
BEFORE UPDATE ON patient
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE guardian_link (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patient(id),
  guardian_first_name TEXT NOT NULL,
  guardian_last_name TEXT NOT NULL,
  relationship TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  legal_authority_note TEXT,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(patient_id, guardian_first_name, guardian_last_name, relationship)
);

CREATE TRIGGER trg_guardian_link_updated
BEFORE UPDATE ON guardian_link
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE insurance_plan (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patient(id),
  insurer_name TEXT NOT NULL,
  policy_number TEXT NOT NULL,
  member_id TEXT NOT NULL,
  group_number TEXT,
  coverage_priority SMALLINT NOT NULL DEFAULT 1 CHECK (coverage_priority IN (1,2,3)),
  effective_date DATE,
  termination_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_insurance_patient_priority ON insurance_plan(patient_id, coverage_priority);

CREATE TRIGGER trg_insurance_plan_updated
BEFORE UPDATE ON insurance_plan
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE consent_artifact (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patient(id),
  consent_type TEXT NOT NULL, -- treatment, communication, release_of_records, marketing
  version_label TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('granted', 'revoked', 'expired')),
  captured_at TIMESTAMPTZ NOT NULL,
  captured_by_user_id UUID REFERENCES app_user(id),
  evidence_document_id UUID,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_consent_patient_type ON consent_artifact(patient_id, consent_type, captured_at DESC);

CREATE TRIGGER trg_consent_artifact_updated
BEFORE UPDATE ON consent_artifact
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------- scheduling ----------
CREATE TABLE operatory_chair (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chair_code TEXT UNIQUE NOT NULL,
  room_name TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_operatory_chair_updated
BEFORE UPDATE ON operatory_chair
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE appointment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patient(id),
  provider_id UUID NOT NULL REFERENCES provider(id),
  operatory_chair_id UUID REFERENCES operatory_chair(id),
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  status appointment_status NOT NULL DEFAULT 'scheduled',
  appointment_type TEXT NOT NULL,
  reason TEXT,
  created_by_user_id UUID REFERENCES app_user(id),
  cancelled_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (end_time > start_time)
);

CREATE INDEX idx_appointment_provider_time ON appointment(provider_id, start_time);
CREATE INDEX idx_appointment_patient_time ON appointment(patient_id, start_time DESC);
CREATE INDEX idx_appointment_status_time ON appointment(status, start_time);

CREATE TRIGGER trg_appointment_updated
BEFORE UPDATE ON appointment
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------- clinical ----------
CREATE TABLE encounter (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patient(id),
  appointment_id UUID REFERENCES appointment(id),
  provider_id UUID NOT NULL REFERENCES provider(id),
  status encounter_status NOT NULL DEFAULT 'draft',
  signed_at TIMESTAMPTZ,
  locked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_encounter_patient_created ON encounter(patient_id, created_at DESC);
CREATE INDEX idx_encounter_provider_created ON encounter(provider_id, created_at DESC);

CREATE TRIGGER trg_encounter_updated
BEFORE UPDATE ON encounter
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE chart_entry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  encounter_id UUID NOT NULL REFERENCES encounter(id),
  patient_id UUID NOT NULL REFERENCES patient(id),
  entry_type TEXT NOT NULL, -- odontogram, progress_note, perio
  body_json JSONB NOT NULL,
  created_by_user_id UUID NOT NULL REFERENCES app_user(id),
  amended_from_entry_id UUID REFERENCES chart_entry(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_chart_entry_patient_type ON chart_entry(patient_id, entry_type, created_at DESC);
CREATE INDEX idx_chart_entry_encounter ON chart_entry(encounter_id, created_at);

CREATE TRIGGER trg_chart_entry_updated
BEFORE UPDATE ON chart_entry
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE treatment_plan (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patient(id),
  encounter_id UUID REFERENCES encounter(id),
  plan_name TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('draft', 'presented', 'accepted', 'declined', 'partial')),
  total_estimated_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_by_provider_id UUID REFERENCES provider(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_treatment_plan_updated
BEFORE UPDATE ON treatment_plan
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------- financials + claims ----------
CREATE TABLE invoice (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patient(id),
  encounter_id UUID REFERENCES encounter(id),
  invoice_number TEXT UNIQUE NOT NULL,
  issue_date DATE NOT NULL,
  due_date DATE,
  status TEXT NOT NULL CHECK (status IN ('open', 'partially_paid', 'paid', 'voided')),
  total_amount NUMERIC(12,2) NOT NULL,
  patient_responsibility_amount NUMERIC(12,2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_invoice_patient_status ON invoice(patient_id, status, issue_date DESC);

CREATE TRIGGER trg_invoice_updated
BEFORE UPDATE ON invoice
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE payment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patient(id),
  invoice_id UUID REFERENCES invoice(id),
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'card', 'e_transfer', 'insurance', 'other')),
  payment_date TIMESTAMPTZ NOT NULL,
  reference_number TEXT,
  posted_by_user_id UUID REFERENCES app_user(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_payment_patient_date ON payment(patient_id, payment_date DESC);

CREATE TRIGGER trg_payment_updated
BEFORE UPDATE ON payment
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE claim (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patient(id),
  invoice_id UUID REFERENCES invoice(id),
  insurance_plan_id UUID REFERENCES insurance_plan(id),
  claim_number TEXT UNIQUE,
  status claim_status NOT NULL DEFAULT 'draft',
  total_claim_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  submitted_at TIMESTAMPTZ,
  adjudicated_at TIMESTAMPTZ,
  denial_reason TEXT,
  created_by_user_id UUID REFERENCES app_user(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_claim_status_created ON claim(status, created_at DESC);
CREATE INDEX idx_claim_patient_created ON claim(patient_id, created_at DESC);

CREATE TRIGGER trg_claim_updated
BEFORE UPDATE ON claim
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------- documents + communication ----------
CREATE TABLE document (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID REFERENCES patient(id),
  encounter_id UUID REFERENCES encounter(id),
  claim_id UUID REFERENCES claim(id),
  storage_uri TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  document_type TEXT NOT NULL,
  checksum_sha256 TEXT NOT NULL,
  uploaded_by_user_id UUID REFERENCES app_user(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_document_patient_created ON document(patient_id, created_at DESC);

ALTER TABLE consent_artifact
  ADD CONSTRAINT fk_consent_evidence_document
  FOREIGN KEY (evidence_document_id) REFERENCES document(id);

CREATE TABLE communication_event (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patient(id),
  channel TEXT NOT NULL CHECK (channel IN ('sms', 'email', 'portal_message', 'voice')),
  direction TEXT NOT NULL CHECK (direction IN ('outbound', 'inbound')),
  template_code TEXT,
  subject TEXT,
  body_redacted TEXT,
  status TEXT NOT NULL,
  sent_at TIMESTAMPTZ,
  created_by_user_id UUID REFERENCES app_user(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_comm_patient_created ON communication_event(patient_id, created_at DESC);

-- ---------- workflow + approvals + agent ----------
CREATE TABLE approval_request (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_type TEXT NOT NULL, -- claim_submit, record_export, refund, writeoff
  request_payload JSONB NOT NULL,
  status approval_status NOT NULL DEFAULT 'pending',
  requested_by_user_id UUID REFERENCES app_user(id),
  requested_by_agent_task_id UUID,
  decided_by_user_id UUID REFERENCES app_user(id),
  decision_note TEXT,
  decided_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_approval_request_updated
BEFORE UPDATE ON approval_request
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE agent_task (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_name TEXT NOT NULL,
  task_type TEXT NOT NULL,
  input_payload JSONB NOT NULL,
  output_payload JSONB,
  status TEXT NOT NULL CHECK (status IN ('queued', 'running', 'completed', 'failed', 'cancelled')),
  confidence_score NUMERIC(5,4),
  requires_approval BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE approval_request
  ADD CONSTRAINT fk_approval_agent_task
  FOREIGN KEY (requested_by_agent_task_id) REFERENCES agent_task(id);

CREATE TRIGGER trg_agent_task_updated
BEFORE UPDATE ON agent_task
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------- access/correction + audit ----------
CREATE TABLE access_request (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patient(id),
  requested_by_name TEXT NOT NULL,
  requested_by_contact TEXT,
  status access_request_status NOT NULL DEFAULT 'received',
  scope_note TEXT,
  verified_by_user_id UUID REFERENCES app_user(id),
  fulfilled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_access_request_updated
BEFORE UPDATE ON access_request
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE correction_request (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patient(id),
  target_entity TEXT NOT NULL,
  target_entity_id UUID NOT NULL,
  request_note TEXT NOT NULL,
  status correction_request_status NOT NULL DEFAULT 'received',
  reviewed_by_user_id UUID REFERENCES app_user(id),
  resolution_note TEXT,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_correction_request_updated
BEFORE UPDATE ON correction_request
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE audit_event (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_type actor_type NOT NULL,
  actor_id UUID,
  actor_label TEXT,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  purpose_of_use TEXT,
  request_id TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_entity ON audit_event(entity_type, entity_id, created_at DESC);
CREATE INDEX idx_audit_actor ON audit_event(actor_type, actor_id, created_at DESC);
CREATE INDEX idx_audit_action_time ON audit_event(action, created_at DESC);

-- Recommended DB role strategy:
-- - one DB role per service schema ownership (write on owned tables, read on approved cross-service views)
-- - no shared write credentials across services
