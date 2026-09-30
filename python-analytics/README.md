# SwasthyaSathi — Python Analytics Service
# ==========================================

## Setup

```bash
cd python-analytics
pip install -r requirements.txt
python main.py
```

The service runs on **port 8001** (internal only).

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| POST | `/internal/analysis/blood-pressure` | Analyze BP time-series |
| POST | `/internal/analysis/glucose` | Analyze glucose time-series |
| POST | `/internal/analysis/weight` | Analyze weight time-series |
| POST | `/internal/analysis/complete` | Complete analysis (all vitals) |

## Architecture

```
Flutter App → Node.js API (port 5000) → Python Service (port 8001)
                                       → Gemini Flash 2.0 (AI Explain)
                                       → PostgreSQL
```

The Python service is **optional** — if it's down, the Node.js layer 
falls back to a built-in JavaScript analytics engine automatically.
