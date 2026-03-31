import uuid
from datetime import datetime
from sqlalchemy import Column, DateTime, ForeignKey, String, Text, Boolean
from sqlalchemy.orm import relationship

from .db import Base


def _id():
    return str(uuid.uuid4())


class Patient(Base):
    __tablename__ = "patient"

    id = Column(String, primary_key=True, default=_id)
    chart_number = Column(String, unique=True, nullable=False)
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    date_of_birth = Column(String, nullable=False)
    email = Column(String)
    phone = Column(String)
    communication_opt_in_sms = Column(Boolean, default=False, nullable=False)
    communication_opt_in_email = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    appointments = relationship("Appointment", back_populates="patient")


class Appointment(Base):
    __tablename__ = "appointment"

    id = Column(String, primary_key=True, default=_id)
    patient_id = Column(String, ForeignKey("patient.id"), nullable=False)
    provider_id = Column(String, nullable=False)
    operatory_chair_id = Column(String)
    start_time = Column(String, nullable=False)
    end_time = Column(String, nullable=False)
    status = Column(String, default="scheduled", nullable=False)
    appointment_type = Column(String, nullable=False)
    reason = Column(Text)
    cancelled_reason = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    patient = relationship("Patient", back_populates="appointments")


class Encounter(Base):
    __tablename__ = "encounter"

    id = Column(String, primary_key=True, default=_id)
    patient_id = Column(String, ForeignKey("patient.id"), nullable=False)
    appointment_id = Column(String, ForeignKey("appointment.id"))
    provider_id = Column(String, nullable=False)
    status = Column(String, default="draft", nullable=False)
    signed_at = Column(String)
    locked_at = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)


class ChartEntry(Base):
    __tablename__ = "chart_entry"

    id = Column(String, primary_key=True, default=_id)
    encounter_id = Column(String, ForeignKey("encounter.id"), nullable=False)
    patient_id = Column(String, ForeignKey("patient.id"), nullable=False)
    entry_type = Column(String, nullable=False)
    body_json = Column(Text, nullable=False)
    amended_from_entry_id = Column(String, ForeignKey("chart_entry.id"))
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)


class ApprovalRequest(Base):
    __tablename__ = "approval_request"

    id = Column(String, primary_key=True, default=_id)
    request_type = Column(String, nullable=False)
    request_payload = Column(Text, nullable=False)
    status = Column(String, default="pending", nullable=False)
    requested_by = Column(String)
    decision_note = Column(Text)
    decided_by = Column(String)
    decided_at = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)


class AuditEvent(Base):
    __tablename__ = "audit_event"

    id = Column(String, primary_key=True, default=_id)
    actor_type = Column(String, nullable=False)
    actor_id = Column(String)
    action = Column(String, nullable=False)
    entity_type = Column(String, nullable=False)
    entity_id = Column(String)
    purpose_of_use = Column(String)
    metadata = Column(Text, nullable=False, default="{}")
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
