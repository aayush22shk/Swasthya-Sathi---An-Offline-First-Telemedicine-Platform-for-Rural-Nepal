const { generateComprehensiveAnalysis, getAnalysisById, getAnalysisHistory } = require('./analysis.service');
const { sendSuccess, sendError } = require('../../utils/response');

const resolvePatientId = async (req) => {
  const pool = require('../../db');
  if (req.user.role === 'patient') {
    const res = await pool.query('SELECT id FROM patients WHERE user_id = $1', [req.user.id]);
    if (res.rows.length === 0) throw Object.assign(new Error('Patient profile not found.'), { statusCode: 404 });
    return res.rows[0].id;
  }
  if (req.query.patient_id) return req.query.patient_id;
  if (req.body.patient_id) return req.body.patient_id;
  throw Object.assign(new Error('patient_id is required for non-patient roles.'), { statusCode: 400 });
};

exports.generateSummary = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const period = req.body.period || '30d';
    const analysis = await generateComprehensiveAnalysis(patient_id, period);
    sendSuccess(res, 200, 'Health analysis generated.', analysis);
  } catch (err) {
    console.error('[AnalysisController] generateSummary error:', err.message);
    sendError(res, err.statusCode || 500, err.message);
  }
};

exports.getAnalysis = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const analysis = await getAnalysisById(req.params.id, patient_id);
    sendSuccess(res, 200, 'Health analysis.', analysis);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

exports.listAnalyses = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const data = await getAnalysisHistory(patient_id, parseInt(req.query.limit) || 10, parseInt(req.query.offset) || 0);
    sendSuccess(res, 200, 'Analysis history.', data);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};
