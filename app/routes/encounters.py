from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Encounter, Patient, Appointment, ChartEntry, AuditEvent
from ..schemas import EncounterCreate, EncounterOut, ChartEntryCreate

router = APIRouter(prefix="/encounters", tags=["encounters"])


@router.post("", response_model=EncounterOut)
def create_encounter(payload: EncounterCreate, db: Session = Depends(get_db)):
    patient = db.query(Patient).filter(Patient.id == payload.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="patient not found")

    if payload.appointment_id:
        appt = db.query(Appointment).filter(Appointment.id == payload.appointment_id).first()
        if not appt:
            raise HTTPException(status_code=404, detail="appointment not found")

    encounter = Encounter(**payload.model_dump())
    db.add(encounter)
    db.add(
        AuditEvent(
            actor_type="human",
            action="ENCOUNTER_CREATED",
            entity_type="encounter",
            entity_id=encounter.id,
            purpose_of_use="treatment",
            metadata="{}",
        )
    )
    db.commit()
    db.refresh(encounter)
    return encounter


@router.post("/{encounter_id}/entries")
def add_entry(encounter_id: str, payload: ChartEntryCreate, db: Session = Depends(get_db)):
    enc = db.query(Encounter).filter(Encounter.id == encounter_id).first()
    if not enc:
        raise HTTPException(status_code=404, detail="encounter not found")
    if enc.status == "locked":
        raise HTTPException(status_code=409, detail="encounter locked; use addendum flow")

    entry = ChartEntry(encounter_id=encounter_id, **payload.model_dump())
    db.add(entry)
    db.add(
        AuditEvent(
            actor_type="human",
            action="CHART_ENTRY_CREATED",
            entity_type="chart_entry",
            entity_id=entry.id,
            purpose_of_use="treatment",
            metadata="{}",
        )
    )
    db.commit()
    db.refresh(entry)
    return {"id": entry.id, "encounter_id": entry.encounter_id}


@router.post("/{encounter_id}/sign", response_model=EncounterOut)
def sign_encounter(encounter_id: str, db: Session = Depends(get_db)):
    enc = db.query(Encounter).filter(Encounter.id == encounter_id).first()
    if not enc:
        raise HTTPException(status_code=404, detail="encounter not found")
    enc.status = "signed"
    enc.signed_at = datetime.utcnow().isoformat()
    db.add(
        AuditEvent(
            actor_type="human",
            action="ENCOUNTER_SIGNED",
            entity_type="encounter",
            entity_id=enc.id,
            purpose_of_use="treatment",
            metadata="{}",
        )
    )
    db.commit()
    db.refresh(enc)
    return enc


@router.post("/{encounter_id}/lock", response_model=EncounterOut)
def lock_encounter(encounter_id: str, db: Session = Depends(get_db)):
    enc = db.query(Encounter).filter(Encounter.id == encounter_id).first()
    if not enc:
        raise HTTPException(status_code=404, detail="encounter not found")
    if enc.status != "signed":
        raise HTTPException(status_code=409, detail="encounter must be signed before lock")
    enc.status = "locked"
    enc.locked_at = datetime.utcnow().isoformat()
    db.add(
        AuditEvent(
            actor_type="human",
            action="ENCOUNTER_LOCKED",
            entity_type="encounter",
            entity_id=enc.id,
            purpose_of_use="treatment",
            metadata="{}",
        )
    )
    db.commit()
    db.refresh(enc)
    return enc
