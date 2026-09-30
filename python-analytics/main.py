"""
SwasthyaSathi — Python Health Analytics Service
Internal service called by Node.js backend for statistical analysis.
Runs on port 8001 (internal only, not publicly accessible).
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import logging

from services.bp_analyzer import analyze_blood_pressure
from services.glucose_analyzer import analyze_glucose
from services.weight_analyzer import analyze_weight

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="SwasthyaSathi Analytics Service", version="1.0.0")

# ─── REQUEST MODELS ──────────────────────────────────────────────────────────

class BPReading(BaseModel):
    systolic: int
    diastolic: int
    heart_rate: Optional[int] = None
    measured_at: str
    measurement_context: Optional[str] = "manual"

class GlucoseReading(BaseModel):
    glucose_value: float
    unit: str = "mg/dl"
    measurement_type: str = "random"
    measured_at: str

class WeightReading(BaseModel):
    weight_kg: float
    measured_at: str

class CompleteAnalysisRequest(BaseModel):
    blood_pressure: List[BPReading] = []
    glucose: List[GlucoseReading] = []
    weight: List[WeightReading] = []
    period_start: str
    period_end: str

# ─── ENDPOINTS ───────────────────────────────────────────────────────────────

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "swasthyasathi-analytics", "version": "1.0.0"}

@app.post("/internal/analysis/blood-pressure")
def analyze_bp(readings: List[BPReading]):
    try:
        result = analyze_blood_pressure([r.model_dump() for r in readings])
        return result
    except Exception as e:
        logger.error(f"BP analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/internal/analysis/glucose")
def analyze_glucose_endpoint(readings: List[GlucoseReading]):
    try:
        result = analyze_glucose([r.model_dump() for r in readings])
        return result
    except Exception as e:
        logger.error(f"Glucose analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/internal/analysis/weight")
def analyze_weight_endpoint(readings: List[WeightReading]):
    try:
        result = analyze_weight([r.model_dump() for r in readings])
        return result
    except Exception as e:
        logger.error(f"Weight analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/internal/analysis/complete")
def complete_analysis(req: CompleteAnalysisRequest):
    try:
        bp_result = analyze_blood_pressure([r.model_dump() for r in req.blood_pressure])
        glucose_result = analyze_glucose([r.model_dump() for r in req.glucose])
        weight_result = analyze_weight([r.model_dump() for r in req.weight])

        return {
            "blood_pressure": bp_result,
            "glucose": glucose_result,
            "weight": weight_result,
            "flags": [],  # Flags are applied by Node.js clinical rule engine
            "engine": "python_analytics_1.0",
        }
    except Exception as e:
        logger.error(f"Complete analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8001, reload=True)
