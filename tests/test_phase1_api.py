from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["phase"] == "1"


def test_patient_appointment_encounter_flow():
    patient = client.post(
        "/patients",
        json={
            "chart_number": "CH-1001",
            "first_name": "Ava",
            "last_name": "Lee",
            "date_of_birth": "1990-06-01",
            "email": "ava@example.com",
            "phone": "5551001000",
        },
    )
    assert patient.status_code == 200
    patient_id = patient.json()["id"]

    appt = client.post(
        "/appointments",
        json={
            "patient_id": patient_id,
            "provider_id": "prov-1",
            "start_time": "2026-04-01T09:00:00Z",
            "end_time": "2026-04-01T09:30:00Z",
            "appointment_type": "hygiene",
        },
    )
    assert appt.status_code == 200
    appt_id = appt.json()["id"]

    enc = client.post(
        "/encounters",
        json={
            "patient_id": patient_id,
            "appointment_id": appt_id,
            "provider_id": "prov-1",
        },
    )
    assert enc.status_code == 200
    encounter_id = enc.json()["id"]

    entry = client.post(
        f"/encounters/{encounter_id}/entries",
        json={
            "patient_id": patient_id,
            "entry_type": "progress_note",
            "body_json": "{\"note\":\"routine cleaning\"}",
        },
    )
    assert entry.status_code == 200

    signed = client.post(f"/encounters/{encounter_id}/sign")
    assert signed.status_code == 200
    assert signed.json()["status"] == "signed"

    locked = client.post(f"/encounters/{encounter_id}/lock")
    assert locked.status_code == 200
    assert locked.json()["status"] == "locked"


def test_approval_flow():
    created = client.post(
        "/approvals",
        json={"request_type": "claim_submit", "request_payload": "{\"claim_id\":\"c1\"}", "requested_by": "billing-1"},
    )
    assert created.status_code == 200
    approval_id = created.json()["id"]

    approved = client.post(f"/approvals/{approval_id}/approve", json={"decided_by": "manager-1"})
    assert approved.status_code == 200
    assert approved.json()["status"] == "approved"
