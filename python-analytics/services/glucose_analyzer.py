"""Glucose Analyzer — statistical analysis for glucose time-series data."""

import pandas as pd
import numpy as np
from typing import List, Dict, Optional, Any
from .bp_analyzer import detect_trend


def analyze_glucose(readings: List[Dict]) -> Dict[str, Any]:
    if not readings:
        return {"measurement_count": 0, "latest": None, "fasting_average_30d": None,
                "overall_average_30d": None, "trend": "insufficient_data"}

    df = pd.DataFrame(readings)
    df['measured_at'] = pd.to_datetime(df['measured_at'], utc=True)
    df['glucose_value'] = df['glucose_value'].astype(float)
    df = df.sort_values('measured_at')

    now = df['measured_at'].max()

    latest_row = df.iloc[-1]
    latest = {
        "value": float(latest_row['glucose_value']),
        "unit": str(latest_row['unit']),
        "measurement_type": str(latest_row['measurement_type']),
        "measured_at": latest_row['measured_at'].isoformat(),
    }

    # 30-day window
    cutoff_30 = now - pd.Timedelta(days=30)
    df_30 = df[df['measured_at'] >= cutoff_30]

    # Fasting average (most clinically meaningful)
    fasting = df_30[df_30['measurement_type'] == 'fasting']
    fasting_avg_30d = round(float(fasting['glucose_value'].mean()), 1) if len(fasting) > 0 else None

    overall_avg_30d = round(float(df_30['glucose_value'].mean()), 1) if len(df_30) > 0 else None

    # Trend on all readings
    trend = detect_trend(df['glucose_value'].values, min_points=5)

    return {
        "measurement_count": len(df),
        "fasting_measurement_count": len(fasting),
        "latest": latest,
        "fasting_average_30d": fasting_avg_30d,
        "overall_average_30d": overall_avg_30d,
        "trend": trend,
    }
