# tests/test_bp_analyzer.py
#
# Unit Tests — Blood Pressure Analyzer
# Tests the statistical analysis logic in services/bp_analyzer.py.
# No external services needed — pure Python unit tests.
#
# Run: pytest tests/test_bp_analyzer.py -v

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import pytest
from datetime import datetime, timedelta
from services.bp_analyzer import analyze_blood_pressure, detect_trend


# ─── Fixtures ─────────────────────────────────────────────────────────────────

def make_bp_reading(systolic: int, diastolic: int, days_ago: int = 0,
                    heart_rate: int = None, context: str = "manual") -> dict:
    """Helper: create a single BP reading dict."""
    measured_at = (datetime.utcnow() - timedelta(days=days_ago)).isoformat() + "Z"
    r = {
        "systolic": systolic,
        "diastolic": diastolic,
        "measured_at": measured_at,
        "measurement_context": context,
    }
    if heart_rate is not None:
        r["heart_rate"] = heart_rate
    return r


def make_readings_series(values: list, spacing_days: float = 1.0) -> list:
    """
    Helper: create a list of BP readings from (systolic, diastolic) tuples.
    Readings are spaced `spacing_days` apart, going back in time.
    """
    return [
        make_bp_reading(s, d, days_ago=i * spacing_days)
        for i, (s, d) in enumerate(values)
    ]


# ─── Test Suite: Empty Readings ───────────────────────────────────────────────

class TestEmptyReadings:
    def test_returns_zero_count(self):
        result = analyze_blood_pressure([])
        assert result["measurement_count"] == 0

    def test_latest_is_none(self):
        result = analyze_blood_pressure([])
        assert result["latest"] is None

    def test_averages_are_none(self):
        result = analyze_blood_pressure([])
        assert result["average_7d"] is None
        assert result["average_30d"] is None
        assert result["average_90d"] is None

    def test_trend_is_insufficient_data(self):
        result = analyze_blood_pressure([])
        assert result["trend"] == "insufficient_data"

    def test_variability_is_none(self):
        result = analyze_blood_pressure([])
        assert result["variability"] is None

    def test_heart_rate_avg_is_none(self):
        result = analyze_blood_pressure([])
        assert result["heart_rate_avg"] is None


# ─── Test Suite: Single Reading ───────────────────────────────────────────────

class TestSingleReading:
    def setup_method(self):
        self.readings = [make_bp_reading(120, 80, days_ago=0, heart_rate=72)]

    def test_measurement_count_is_one(self):
        result = analyze_blood_pressure(self.readings)
        assert result["measurement_count"] == 1

    def test_latest_is_correct(self):
        result = analyze_blood_pressure(self.readings)
        assert result["latest"]["systolic"] == 120
        assert result["latest"]["diastolic"] == 80

    def test_trend_is_insufficient_data_for_single_reading(self):
        result = analyze_blood_pressure(self.readings)
        # Requires min 5 readings for trend detection
        assert result["trend"] == "insufficient_data"

    def test_heart_rate_avg_is_computed(self):
        result = analyze_blood_pressure(self.readings)
        assert result["heart_rate_avg"] == 72.0


# ─── Test Suite: Statistical Summaries ───────────────────────────────────────

class TestStatisticalSummaries:
    def test_7d_average_from_recent_readings(self):
        # 5 readings in last 7 days
        readings = make_readings_series(
            [(120, 80), (122, 82), (118, 78), (125, 85), (115, 75)],
            spacing_days=1
        )
        result = analyze_blood_pressure(readings)

        assert result["average_7d"] is not None
        # Average systolic: (120+122+118+125+115)/5 = 120.0
        assert result["average_7d"]["systolic"] == pytest.approx(120.0, abs=0.2)

    def test_30d_average_includes_older_readings(self):
        # Mix of readings: some recent, some older
        readings = [
            make_bp_reading(130, 85, days_ago=2),
            make_bp_reading(128, 83, days_ago=10),
            make_bp_reading(126, 82, days_ago=20),
        ]
        result = analyze_blood_pressure(readings)

        assert result["average_30d"] is not None
        assert result["average_30d"]["count"] == 3

    def test_90d_average_includes_all_readings(self):
        readings = [
            make_bp_reading(120, 80, days_ago=5),
            make_bp_reading(125, 82, days_ago=45),
            make_bp_reading(130, 85, days_ago=80),
        ]
        result = analyze_blood_pressure(readings)
        assert result["average_90d"]["count"] == 3

    def test_7d_average_is_none_when_all_readings_older(self):
        # All readings are older than 7 days
        readings = [
            make_bp_reading(120, 80, days_ago=10),
            make_bp_reading(122, 82, days_ago=15),
        ]
        result = analyze_blood_pressure(readings)
        assert result["average_7d"] is None
        assert result["average_30d"] is not None  # but within 30 days

    def test_variability_computed_for_3_or_more_readings(self):
        readings = make_readings_series(
            [(120, 80), (130, 85), (115, 75)],
            spacing_days=1
        )
        result = analyze_blood_pressure(readings)
        assert result["variability"] is not None
        assert "systolic_std" in result["variability"]
        assert "diastolic_std" in result["variability"]

    def test_variability_is_none_for_fewer_than_3_readings(self):
        readings = [make_bp_reading(120, 80, days_ago=0)]
        result = analyze_blood_pressure(readings)
        assert result["variability"] is None

    def test_heart_rate_avg_ignores_none_values(self):
        readings = [
            make_bp_reading(120, 80, heart_rate=72),
            make_bp_reading(122, 82),  # no heart rate
            make_bp_reading(118, 78, heart_rate=68),
        ]
        result = analyze_blood_pressure(readings)
        # Average of 72 and 68 = 70.0 (the None value is dropped)
        assert result["heart_rate_avg"] == pytest.approx(70.0, abs=0.1)

    def test_heart_rate_avg_is_none_when_no_readings_have_heart_rate(self):
        readings = [
            make_bp_reading(120, 80),
            make_bp_reading(122, 82),
        ]
        result = analyze_blood_pressure(readings)
        assert result["heart_rate_avg"] is None


# ─── Test Suite: detect_trend ─────────────────────────────────────────────────

class TestDetectTrend:
    def test_insufficient_data_for_fewer_than_5_points(self):
        assert detect_trend([120, 122, 118, 125]) == "insufficient_data"

    def test_stable_trend_for_no_significant_slope(self):
        # Readings that are essentially flat with minor noise
        values = [120, 121, 119, 120, 121, 120, 119, 121]
        assert detect_trend(values) == "stable"

    def test_increasing_trend_detected(self):
        # Clear upward trend: 110 → 120 → 130 → 140 → 150 → 160
        values = [110, 120, 130, 140, 150, 160]
        assert detect_trend(values) == "increasing"

    def test_decreasing_trend_detected(self):
        # Clear downward trend: 160 → 150 → 140 → 130 → 120 → 110
        values = [160, 150, 140, 130, 120, 110]
        assert detect_trend(values) == "decreasing"

    def test_custom_min_points_parameter(self):
        # With min_points=3, 4 data points should be enough
        values = [120, 125, 130, 135]
        assert detect_trend(values, min_points=3) == "increasing"

    def test_returns_string(self):
        values = [120, 118, 122, 119, 121, 120]
        result = detect_trend(values)
        assert isinstance(result, str)
        assert result in ("stable", "increasing", "decreasing", "insufficient_data")


# ─── Test Suite: Full Analysis Result Structure ────────────────────────────────

class TestResultStructure:
    def test_all_expected_keys_present(self):
        readings = make_readings_series(
            [(120, 80)] * 10,
            spacing_days=3
        )
        result = analyze_blood_pressure(readings)

        expected_keys = [
            "measurement_count", "latest", "average_7d",
            "average_30d", "average_90d", "trend",
            "variability", "heart_rate_avg",
        ]
        for key in expected_keys:
            assert key in result, f"Missing key: {key}"

    def test_latest_reading_contains_required_fields(self):
        readings = [make_bp_reading(130, 85, days_ago=0)]
        result = analyze_blood_pressure(readings)

        assert "systolic" in result["latest"]
        assert "diastolic" in result["latest"]
        assert "measured_at" in result["latest"]

    def test_latest_is_the_most_recent_reading(self):
        readings = [
            make_bp_reading(100, 65, days_ago=10),  # older
            make_bp_reading(140, 90, days_ago=0),   # most recent
        ]
        result = analyze_blood_pressure(readings)
        assert result["latest"]["systolic"] == 140
        assert result["latest"]["diastolic"] == 90

    def test_measurement_count_matches_input_length(self):
        readings = [make_bp_reading(120, 80, days_ago=i) for i in range(7)]
        result = analyze_blood_pressure(readings)
        assert result["measurement_count"] == 7


# ─── Test Suite: Clinical Accuracy ────────────────────────────────────────────

class TestClinicalAccuracy:
    """
    Ensures statistical calculations are numerically correct
    to a defined tolerance (±0.5 mmHg).
    """

    def test_average_systolic_calculation(self):
        readings = [
            make_bp_reading(120, 80, days_ago=0),
            make_bp_reading(130, 85, days_ago=1),
            make_bp_reading(110, 75, days_ago=2),
        ]
        result = analyze_blood_pressure(readings)
        # Expected average: (120+130+110)/3 = 120.0
        assert result["average_7d"]["systolic"] == pytest.approx(120.0, abs=0.5)

    def test_average_diastolic_calculation(self):
        readings = [
            make_bp_reading(120, 80, days_ago=0),
            make_bp_reading(130, 90, days_ago=1),
            make_bp_reading(110, 70, days_ago=2),
        ]
        result = analyze_blood_pressure(readings)
        # Expected average: (80+90+70)/3 = 80.0
        assert result["average_7d"]["diastolic"] == pytest.approx(80.0, abs=0.5)
