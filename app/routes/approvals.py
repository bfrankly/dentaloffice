from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import ApprovalRequest, AuditEvent
from ..schemas import ApprovalCreate, ApprovalOut, ApprovalDecision

router = APIRouter(prefix="/approvals", tags=["approvals"])


@router.post("", response_model=ApprovalOut)
def create_approval(payload: ApprovalCreate, db: Session = Depends(get_db)):
    req = ApprovalRequest(**payload.model_dump())
    db.add(req)
    db.add(
        AuditEvent(
            actor_type="human",
            action="APPROVAL_REQUEST_CREATED",
            entity_type="approval_request",
            entity_id=req.id,
            purpose_of_use="operations",
            metadata="{}",
        )
    )
    db.commit()
    db.refresh(req)
    return req


@router.get("/pending", response_model=list[ApprovalOut])
def pending_approvals(db: Session = Depends(get_db)):
    return db.query(ApprovalRequest).filter(ApprovalRequest.status == "pending").all()


@router.post("/{approval_id}/approve", response_model=ApprovalOut)
def approve(approval_id: str, payload: ApprovalDecision, db: Session = Depends(get_db)):
    req = db.query(ApprovalRequest).filter(ApprovalRequest.id == approval_id).first()
    if not req:
        raise HTTPException(status_code=404, detail="approval not found")
    if req.status != "pending":
        raise HTTPException(status_code=409, detail="approval is not pending")
    req.status = "approved"
    req.decided_by = payload.decided_by
    req.decision_note = payload.decision_note
    req.decided_at = datetime.utcnow().isoformat()
    db.add(
        AuditEvent(
            actor_type="human",
            action="APPROVAL_APPROVED",
            entity_type="approval_request",
            entity_id=req.id,
            purpose_of_use="operations",
            metadata="{}",
        )
    )
    db.commit()
    db.refresh(req)
    return req


@router.post("/{approval_id}/reject", response_model=ApprovalOut)
def reject(approval_id: str, payload: ApprovalDecision, db: Session = Depends(get_db)):
    req = db.query(ApprovalRequest).filter(ApprovalRequest.id == approval_id).first()
    if not req:
        raise HTTPException(status_code=404, detail="approval not found")
    if req.status != "pending":
        raise HTTPException(status_code=409, detail="approval is not pending")
    req.status = "rejected"
    req.decided_by = payload.decided_by
    req.decision_note = payload.decision_note
    req.decided_at = datetime.utcnow().isoformat()
    db.add(
        AuditEvent(
            actor_type="human",
            action="APPROVAL_REJECTED",
            entity_type="approval_request",
            entity_id=req.id,
            purpose_of_use="operations",
            metadata="{}",
        )
    )
    db.commit()
    db.refresh(req)
    return req
