from fastapi import FastAPI

from .db import Base, engine
from .routes import patients, appointments, encounters, approvals

app = FastAPI(title="Dental Office Phase 1 API", version="0.1.0")


@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)


@app.get("/health")
def health():
    return {"status": "ok", "phase": "1"}


app.include_router(patients.router)
app.include_router(appointments.router)
app.include_router(encounters.router)
app.include_router(approvals.router)
