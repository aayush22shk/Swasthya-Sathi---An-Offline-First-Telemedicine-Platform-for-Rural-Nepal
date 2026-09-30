const pool = require('../../db');
const axios = require('axios');

const PYTHON_SERVICE_URL = process.env.PYTHON_ANALYTICS_URL || 'http://localhost:8001';

// ─── HELPERS ─────────────────────────────────────────────────────────────────

const getPeriodDates = (period = '30d') => {
  const now = new Date();
  const end = now.toISOString();
  let start;
  if (period === '7d')  start = new Date(now - 7  * 24 * 3600 * 1000).toISOString();
  if (period === '30d') start = new Date(now - 30 * 24 * 3600 * 1000).toISOString();
  if (period === '90d') start = new Date(now - 90 * 24 * 3600 * 1000).toISOString();
  if (!start) start = new Date(now - 30 * 24 * 3600 * 1000).toISOString();
  return { start, end };
};

const loadHealthData = async (patient_id, start, end) => {
  const [bpRes, glucoseRes, weightRes, condRes, medRes] = await Promise.all([
    pool.query(
      `SELECT systolic, diastolic, heart_rate, measured_at, measurement_context
       FROM blood_pressure_readings
       WHERE patient_id = $1 AND measured_at BETWEEN $2 AND $3
       ORDER BY measured_at ASC`,
      [patient_id, start, end]
    ),
    pool.query(
      `SELECT glucose_value, unit, measurement_type, measured_at
       FROM glucose_readings
       WHERE patient_id = $1 AND measured_at BETWEEN $2 AND $3
       ORDER BY measured_at ASC`,
      [patient_id, start, end]
    ),
    pool.query(
      `SELECT weight_kg, measured_at
       FROM weight_readings
       WHERE patient_id = $1 AND measured_at BETWEEN $2 AND $3
       ORDER BY measured_at ASC`,
      [patient_id, start, end]
    ),
    pool.query(
      `SELECT condition_name, condition_type, status FROM patient_conditions WHERE patient_id = $1 AND status = 'active'`,
      [patient_id]
    ),
    pool.query(
      `SELECT medicine_name, dosage, route, frequency, instructions FROM patient_medications WHERE patient_id = $1 AND is_active = true`,
      [patient_id]
    ),
  ]);
  return {
    blood_pressure: bpRes.rows,
    glucose: glucoseRes.rows,
    weight: weightRes.rows,
    conditions: condRes.rows,
    medications: medRes.rows,
  };
};

// ─── CALL PYTHON SERVICE ─────────────────────────────────────────────────────

const callPythonAnalytics = async (healthData, start, end) => {
  try {
    const resp = await axios.post(`${PYTHON_SERVICE_URL}/internal/analysis/complete`, {
      blood_pressure: healthData.blood_pressure,
      glucose: healthData.glucose,
      weight: healthData.weight,
      period_start: start,
      period_end: end,
    }, { timeout: 15000 });
    return resp.data;
  } catch (err) {
    // Fall back to basic JS analytics if Python service is unavailable
    console.warn('[AnalysisService] Python service unavailable, using fallback analytics:', err.message);
    return computeFallbackAnalytics(healthData, start, end);
  }
};

// Fallback analytics (runs in Node.js if Python service is down)
const computeFallbackAnalytics = (healthData, start, end) => {
  const { blood_pressure: bpData, glucose: glucoseData, weight: weightData } = healthData;
  const avg = (arr) => arr.length ? arr.reduce((a, b) => a + b, 0) / arr.length : null;
  const latest = (arr) => arr.length ? arr[arr.length - 1] : null;
  const trend = (values) => {
    if (values.length < 3) return 'insufficient_data';
    const mid = Math.floor(values.length / 2);
    const firstHalfAvg = avg(values.slice(0, mid));
    const secondHalfAvg = avg(values.slice(mid));
    const diff = secondHalfAvg - firstHalfAvg;
    if (Math.abs(diff) < 2) return 'stable';
    return diff > 0 ? 'increasing' : 'decreasing';
  };

  const bpResult = {
    measurement_count: bpData.length,
    latest: latest(bpData) ? { systolic: latest(bpData).systolic, diastolic: latest(bpData).diastolic } : null,
    average_30d: bpData.length ? {
      systolic: Math.round(avg(bpData.map(r => r.systolic))),
      diastolic: Math.round(avg(bpData.map(r => r.diastolic))),
    } : null,
    trend: bpData.length >= 3 ? trend(bpData.map(r => r.systolic)) : 'insufficient_data',
  };

  const glucoseResult = {
    measurement_count: glucoseData.length,
    latest: latest(glucoseData) ? { value: latest(glucoseData).glucose_value, unit: latest(glucoseData).unit } : null,
    average_30d: glucoseData.length ? parseFloat(avg(glucoseData.map(r => parseFloat(r.glucose_value))).toFixed(1)) : null,
    trend: glucoseData.length >= 3 ? trend(glucoseData.map(r => parseFloat(r.glucose_value))) : 'insufficient_data',
  };

  const weightResult = {
    measurement_count: weightData.length,
    latest: latest(weightData) ? parseFloat(latest(weightData).weight_kg) : null,
    change_30d_kg: weightData.length >= 2
      ? parseFloat((parseFloat(latest(weightData).weight_kg) - parseFloat(weightData[0].weight_kg)).toFixed(1))
      : null,
  };

  return { blood_pressure: bpResult, glucose: glucoseResult, weight: weightResult, flags: [], engine: 'fallback_js' };
};

// ─── CLINICAL RULE ENGINE ────────────────────────────────────────────────────

const RULE_VERSION = '1.0.0';

const applyClinicalRules = (analysisResult) => {
  const flags = [];
  const { blood_pressure, glucose } = analysisResult;

  // BP Rules (JNC 8 / ACC/AHA 2017 aligned)
  if (blood_pressure?.latest) {
    const { systolic: s, diastolic: d } = blood_pressure.latest;
    if (s >= 180 || d >= 120) {
      flags.push({ category: 'blood_pressure', severity: 'critical', code: 'BP_CRISIS', message: 'Blood pressure is in hypertensive crisis range. Seek immediate medical attention.' });
    } else if (s >= 140 || d >= 90) {
      flags.push({ category: 'blood_pressure', severity: 'alert', code: 'BP_STAGE2', message: 'Blood pressure readings suggest Stage 2 hypertension range. Discuss with your doctor.' });
    } else if (s >= 130 || d >= 80) {
      flags.push({ category: 'blood_pressure', severity: 'warning', code: 'BP_STAGE1', message: 'Blood pressure is in Stage 1 hypertension range.' });
    } else if (s >= 120 && s < 130 && d < 80) {
      flags.push({ category: 'blood_pressure', severity: 'info', code: 'BP_ELEVATED', message: 'Blood pressure is elevated (pre-hypertension range).' });
    }
  }
  if (blood_pressure?.trend === 'increasing') {
    flags.push({ category: 'blood_pressure', severity: 'warning', code: 'BP_TREND_UP', message: 'Blood pressure trend is increasing over the analysis period.' });
  }

  // Glucose Rules (ADA 2024 aligned)
  if (glucose?.latest) {
    const val = parseFloat(glucose.latest.value);
    if (val < 54) {
      flags.push({ category: 'glucose', severity: 'critical', code: 'GLUCOSE_SEVERE_LOW', message: 'Blood glucose is critically low. This requires immediate action.' });
    } else if (val < 70) {
      flags.push({ category: 'glucose', severity: 'alert', code: 'GLUCOSE_LOW', message: 'Blood glucose is below normal range. Check again and consider intervention.' });
    } else if (val > 250) {
      flags.push({ category: 'glucose', severity: 'alert', code: 'GLUCOSE_HIGH', message: 'Blood glucose is significantly elevated. Contact your doctor.' });
    } else if (val > 180) {
      flags.push({ category: 'glucose', severity: 'warning', code: 'GLUCOSE_ELEVATED', message: 'Blood glucose is above normal range.' });
    }
  }

  return { ...analysisResult, flags, rule_version: RULE_VERSION };
};

// ─── PERSIST ANALYSIS ────────────────────────────────────────────────────────

const persistAnalysis = async (patient_id, type, start, end, healthData, result, engineVersion) => {
  const res = await pool.query(
    `INSERT INTO health_analyses (patient_id, analysis_type, period_start, period_end, engine_version, rule_version, input_snapshot, result)
     VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8::jsonb)
     RETURNING id, patient_id, analysis_type, period_start, period_end, engine_version, rule_version, result, generated_at`,
    [patient_id, type, start, end, engineVersion || 'node_fallback_1.0', result.rule_version || RULE_VERSION,
     JSON.stringify({ bp_count: healthData.blood_pressure.length, glucose_count: healthData.glucose.length, weight_count: healthData.weight.length }),
     JSON.stringify(result)]
  );
  return res.rows[0];
};

// ─── PUBLIC SERVICE FUNCTIONS ─────────────────────────────────────────────────

const generateComprehensiveAnalysis = async (patient_id, period = '30d') => {
  const { start, end } = getPeriodDates(period);
  const healthData = await loadHealthData(patient_id, start, end);
  const rawResult = await callPythonAnalytics(healthData, start, end);
  const resultWithFlags = applyClinicalRules(rawResult);
  const persisted = await persistAnalysis(patient_id, 'comprehensive', start, end, healthData, resultWithFlags, rawResult.engine);
  return { ...persisted, conditions: healthData.conditions, medications: healthData.medications };
};

const getAnalysisById = async (id, patient_id) => {
  const res = await pool.query(
    `SELECT * FROM health_analyses WHERE id = $1 AND patient_id = $2`,
    [id, patient_id]
  );
  if (res.rows.length === 0) {
    const err = new Error('Analysis not found.'); err.statusCode = 404; throw err;
  }
  return res.rows[0];
};

const getAnalysisHistory = async (patient_id, limit = 10, offset = 0) => {
  const res = await pool.query(
    `SELECT id, analysis_type, period_start, period_end, engine_version, rule_version, generated_at
     FROM health_analyses WHERE patient_id = $1
     ORDER BY generated_at DESC
     LIMIT $2 OFFSET $3`,
    [patient_id, limit, offset]
  );
  return res.rows;
};

module.exports = { generateComprehensiveAnalysis, getAnalysisById, getAnalysisHistory };
