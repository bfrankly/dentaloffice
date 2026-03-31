from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Patient, AuditEvent
from ..schemas import PatientCreate, PatientOut

router = APIRouter(prefix="/patients", tags=["patients"])


@router.post("", response_model=PatientOut)
def create_patient(payload: PatientCreate, db: Session = Depends(get_db)):
    exists = db.query(Patient).filter(Patient.chart_number == payload.chart_number).first()
    if exists:
        raise HTTPException(status_code=409, detail="chart_number already exists")

    patient = Patient(**payload.model_dump())
    db.add(patient)
    db.add(
        AuditEvent(
            actor_type="human",
            action="PATIENT_CREATED",
            entity_type="patient",
            entity_id=patient.id,
            purpose_of_use="operations",
            metadata="{}",
        )
    )
    db.commit()
    db.refresh(patient)
    return patient


@router.get("/{patient_id}", response_model=PatientOut)
def get_patient(patient_id: str, db: Session = Depends(get_db)):
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="patient not found")
    return patient


@router.get("")
def search_patients(
    q: str = Query(min_length=1),
    db: Session = Depends(get_db),
):
    pattern = f"%{q}%"
    rows = (
        db.query(Patient)
        .filter((Patient.first_name.like(pattern)) | (Patient.last_name.like(pattern)) | (Patient.phone.like(pattern)))
        .limit(50)
        .all()
    )
    return [{"id": r.id, "chart_number": r.chart_number, "name": f"{r.first_name} {r.last_name}"} for r in rows]
