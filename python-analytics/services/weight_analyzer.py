"""Weight Analyzer — statistical analysis for weight time-series data."""

import pandas as pd
from typing import List, Dict, Optional, Any


def analyze_weight(readings: List[Dict]) -> Dict[str, Any]:
    if not readings:
        return {"measurement_count": 0, "latest_kg": None, "change_30d_kg": None, "change_90d_kg": None}

    df = pd.DataFrame(readings)
    df['measured_at'] = pd.to_datetime(df['measured_at'], utc=True)
    df['weight_kg'] = df['weight_kg'].astype(float)
    df = df.sort_values('measured_at')

    now = df['measured_at'].max()
    latest_kg = round(float(df.iloc[-1]['weight_kg']), 2)

    def change_over_days(days: int) -> Optional[float]:
        cutoff = now - pd.Timedelta(days=days)
        past = df[df['measured_at'] <= cutoff]
        if len(past) == 0:
            return None
        first_in_period = float(past.iloc[-1]['weight_kg'])  # last reading before period
        return round(latest_kg - first_in_period, 2)

    return {
        "measurement_count": len(df),
        "latest_kg": latest_kg,
        "change_30d_kg": change_over_days(30),
        "change_90d_kg": change_over_days(90),
    }
