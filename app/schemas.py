from pydantic import BaseModel, Field
from typing import Optional


class PatientCreate(BaseModel):
    chart_number: str
    first_name: str
    last_name: str
    date_of_birth: str
    email: Optional[str] = None
    phone: Optional[str] = None
    communication_opt_in_sms: bool = False
    communication_opt_in_email: bool = False


class PatientOut(PatientCreate):
    id: str

    class Config:
        from_attributes = True


class AppointmentCreate(BaseModel):
    patient_id: str
    provider_id: str
    operatory_chair_id: Optional[str] = None
    start_time: str
    end_time: str
    appointment_type: str
    reason: Optional[str] = None


class AppointmentOut(AppointmentCreate):
    id: str
    status: str

    class Config:
        from_attributes = True


class AppointmentCancel(BaseModel):
    reason: str = Field(min_length=2)


class EncounterCreate(BaseModel):
    patient_id: str
    appointment_id: Optional[str] = None
    provider_id: str


class EncounterOut(EncounterCreate):
    id: str
    status: str

    class Config:
        from_attributes = True


class ChartEntryCreate(BaseModel):
    patient_id: str
    entry_type: str
    body_json: str
    amended_from_entry_id: Optional[str] = None


class ApprovalCreate(BaseModel):
    request_type: str
    request_payload: str
    requested_by: Optional[str] = None


class ApprovalDecision(BaseModel):
    decided_by: str
    decision_note: Optional[str] = None


class ApprovalOut(BaseModel):
    id: str
    request_type: str
    status: str
    request_payload: str

    class Config:
        from_attributes = True
