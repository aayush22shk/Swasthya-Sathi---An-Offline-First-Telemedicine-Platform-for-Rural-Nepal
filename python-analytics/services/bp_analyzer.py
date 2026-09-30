"""
Blood Pressure Analyzer
Computes statistical summaries and trend detection for BP time-series data.
"""

import pandas as pd
import numpy as np
from typing import List, Dict, Optional, Any


def analyze_blood_pressure(readings: List[Dict]) -> Dict[str, Any]:
    """
    Analyze a list of BP readings and return statistical summaries.
    
    Args:
        readings: List of dicts with keys: systolic, diastolic, heart_rate, measured_at
    
    Returns:
        Dict with measurement_count, latest, average_7d, average_30d, trend, etc.
    """
    if not readings:
        return {
            "measurement_count": 0,
            "latest": None,
            "average_7d": None,
            "average_30d": None,
            "average_90d": None,
            "trend": "insufficient_data",
            "variability": None,
            "heart_rate_avg": None,
        }

    df = pd.DataFrame(readings)
    df['measured_at'] = pd.to_datetime(df['measured_at'], utc=True)
    df = df.sort_values('measured_at')

    now = df['measured_at'].max()

    # Latest reading
    latest_row = df.iloc[-1]
    latest = {
        "systolic": int(latest_row['systolic']),
        "diastolic": int(latest_row['diastolic']),
        "measured_at": latest_row['measured_at'].isoformat(),
    }

    def avg_over_days(days: int) -> Optional[Dict]:
        cutoff = now - pd.Timedelta(days=days)
        subset = df[df['measured_at'] >= cutoff]
        if len(subset) == 0:
            return None
        return {
            "systolic": round(float(subset['systolic'].mean()), 1),
            "diastolic": round(float(subset['diastolic'].mean()), 1),
            "count": len(subset),
        }

    avg_7d  = avg_over_days(7)
    avg_30d = avg_over_days(30)
    avg_90d = avg_over_days(90)

    # Trend detection using linear regression on systolic
    trend = detect_trend(df['systolic'].values, min_points=5)

    # Variability (std dev of systolic)
    variability = None
    if len(df) >= 3:
        variability = {
            "systolic_std": round(float(df['systolic'].std()), 1),
            "diastolic_std": round(float(df['diastolic'].std()), 1),
        }

    # Heart rate average
    hr_values = df['heart_rate'].dropna()
    heart_rate_avg = round(float(hr_values.mean()), 1) if len(hr_values) > 0 else None

    return {
        "measurement_count": len(df),
        "latest": latest,
        "average_7d": avg_7d,
        "average_30d": avg_30d,
        "average_90d": avg_90d,
        "trend": trend,
        "variability": variability,
        "heart_rate_avg": heart_rate_avg,
    }


def detect_trend(values: np.ndarray, min_points: int = 5) -> str:
    """
    Detect trend direction using linear regression slope.
    Requires minimum number of observations to avoid single-reading inferences.
    """
    if len(values) < min_points:
        return "insufficient_data"

    x = np.arange(len(values))
    slope, _ = np.polyfit(x, values, 1)

    # Require meaningful slope (not just noise)
    std = np.std(values)
    noise_threshold = max(std * 0.1, 1.5)  # at least 1.5 mmHg/reading slope

    if abs(slope) < noise_threshold:
        return "stable"
    return "increasing" if slope > 0 else "decreasing"
