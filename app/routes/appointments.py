from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Appointment, Patient, AuditEvent
from ..schemas import AppointmentCreate, AppointmentOut, AppointmentCancel

router = APIRouter(prefix="/appointments", tags=["appointments"])


@router.post("", response_model=AppointmentOut)
def create_appointment(payload: AppointmentCreate, db: Session = Depends(get_db)):
    patient = db.query(Patient).filter(Patient.id == payload.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="patient not found")

    appt = Appointment(**payload.model_dump())
    db.add(appt)
    db.add(
        AuditEvent(
            actor_type="human",
            action="APPOINTMENT_CREATED",
            entity_type="appointment",
            entity_id=appt.id,
            purpose_of_use="operations",
            metadata="{}",
        )
    )
    db.commit()
    db.refresh(appt)
    return appt


@router.post("/{appointment_id}/cancel", response_model=AppointmentOut)
def cancel_appointment(appointment_id: str, payload: AppointmentCancel, db: Session = Depends(get_db)):
    appt = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not appt:
        raise HTTPException(status_code=404, detail="appointment not found")
    appt.status = "cancelled"
    appt.cancelled_reason = payload.reason
    db.add(
        AuditEvent(
            actor_type="human",
            action="APPOINTMENT_CANCELLED",
            entity_type="appointment",
            entity_id=appt.id,
            purpose_of_use="operations",
            metadata="{}",
        )
    )
    db.commit()
    db.refresh(appt)
    return appt
