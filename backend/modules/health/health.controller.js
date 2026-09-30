const {
  addBPReading, getBPHistory,
  addGlucoseReading, getGlucoseHistory,
  addWeightReading, getWeightHistory,
  addSymptom, getSymptoms,
  addCondition, getConditions, updateCondition,
  addMedication, getMedications, updateMedication,
  getLatestVitalsSummary,
} = require('./health.service');
const { sendSuccess, sendError } = require('../../utils/response');

// Helper: resolve patient_id from authenticated user
const resolvePatientId = async (req) => {
  const pool = require('../../db');
  if (req.user.role === 'patient') {
    const res = await pool.query('SELECT id FROM patients WHERE user_id = $1', [req.user.id]);
    if (res.rows.length === 0) throw Object.assign(new Error('Patient profile not found.'), { statusCode: 404 });
    return res.rows[0].id;
  }
  // Doctor/admin can supply patient_id directly
  if (req.query.patient_id) return req.query.patient_id;
  if (req.body.patient_id) return req.body.patient_id;
  throw Object.assign(new Error('patient_id is required for non-patient roles.'), { statusCode: 400 });
};

// ─── BLOOD PRESSURE ──────────────────────────────────────────────────────────

exports.createBPReading = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const reading = await addBPReading({ patient_id, ...req.body });
    sendSuccess(res, 201, 'Blood pressure reading recorded.', reading);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

exports.listBPReadings = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const { limit, offset, from, to } = req.query;
    const data = await getBPHistory({ patient_id, limit: parseInt(limit) || 30, offset: parseInt(offset) || 0, from, to });
    sendSuccess(res, 200, 'Blood pressure history.', data);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

// ─── GLUCOSE ─────────────────────────────────────────────────────────────────

exports.createGlucoseReading = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const reading = await addGlucoseReading({ patient_id, ...req.body });
    sendSuccess(res, 201, 'Glucose reading recorded.', reading);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

exports.listGlucoseReadings = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const { limit, offset, from, to } = req.query;
    const data = await getGlucoseHistory({ patient_id, limit: parseInt(limit) || 30, offset: parseInt(offset) || 0, from, to });
    sendSuccess(res, 200, 'Glucose history.', data);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

// ─── WEIGHT ──────────────────────────────────────────────────────────────────

exports.createWeightReading = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const reading = await addWeightReading({ patient_id, ...req.body });
    sendSuccess(res, 201, 'Weight reading recorded.', reading);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

exports.listWeightReadings = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const { limit, offset, from, to } = req.query;
    const data = await getWeightHistory({ patient_id, limit: parseInt(limit) || 30, offset: parseInt(offset) || 0, from, to });
    sendSuccess(res, 200, 'Weight history.', data);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

// ─── SYMPTOMS ─────────────────────────────────────────────────────────────────

exports.createSymptom = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const symptom = await addSymptom({ patient_id, ...req.body });
    sendSuccess(res, 201, 'Symptom recorded.', symptom);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

exports.listSymptoms = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const data = await getSymptoms({ patient_id, limit: parseInt(req.query.limit) || 20, offset: parseInt(req.query.offset) || 0 });
    sendSuccess(res, 200, 'Symptom records.', data);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

// ─── CONDITIONS ──────────────────────────────────────────────────────────────

exports.createCondition = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const condition = await addCondition({ patient_id, ...req.body });
    sendSuccess(res, 201, 'Condition added.', condition);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

exports.listConditions = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const data = await getConditions(patient_id);
    sendSuccess(res, 200, 'Patient conditions.', data);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

exports.patchCondition = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const { id } = req.params;
    const updated = await updateCondition(id, patient_id, req.body);
    sendSuccess(res, 200, 'Condition updated.', updated);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

// ─── MEDICATIONS ─────────────────────────────────────────────────────────────

exports.createMedication = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const med = await addMedication({ patient_id, ...req.body });
    sendSuccess(res, 201, 'Medication added.', med);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

exports.listMedications = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const active_only = req.query.active !== 'false';
    const data = await getMedications(patient_id, active_only);
    sendSuccess(res, 200, 'Patient medications.', data);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

exports.patchMedication = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const { id } = req.params;
    const updated = await updateMedication(id, patient_id, req.body);
    sendSuccess(res, 200, 'Medication updated.', updated);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

// ─── VITALS SUMMARY ──────────────────────────────────────────────────────────

exports.getVitalsSummary = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const data = await getLatestVitalsSummary(patient_id);
    sendSuccess(res, 200, 'Latest vitals summary.', data);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};
