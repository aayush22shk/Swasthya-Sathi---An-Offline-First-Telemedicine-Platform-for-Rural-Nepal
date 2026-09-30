const { explainAnalysis, startConversation, getConversations, getConversationMessages, sendChatMessage } = require('./ai.service');
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

// POST /api/v1/ai/explain
exports.explain = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const { analysis_id, language } = req.body;
    const result = await explainAnalysis(patient_id, analysis_id || null, language || 'en');
    sendSuccess(res, 200, 'AI health explanation generated.', result);
  } catch (err) {
    console.error('[AIController] explain error:', err.message);
    sendError(res, err.statusCode || 500, err.message);
  }
};

// POST /api/v1/ai/conversations
exports.createConversation = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const conv = await startConversation(patient_id, req.body.title);
    sendSuccess(res, 201, 'Conversation started.', conv);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

// GET /api/v1/ai/conversations
exports.listConversations = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const data = await getConversations(patient_id);
    sendSuccess(res, 200, 'Conversations.', data);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

// GET /api/v1/ai/conversations/:id/messages
exports.getMessages = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const data = await getConversationMessages(req.params.id, patient_id);
    sendSuccess(res, 200, 'Messages.', data);
  } catch (err) {
    sendError(res, err.statusCode || 500, err.message);
  }
};

// POST /api/v1/ai/conversations/:id/messages
exports.sendMessage = async (req, res) => {
  try {
    const patient_id = await resolvePatientId(req);
    const { message, language } = req.body;
    const result = await sendChatMessage(patient_id, req.params.id, message, language || 'en');
    sendSuccess(res, 201, 'Message sent.', result);
  } catch (err) {
    console.error('[AIController] sendMessage error:', err.message);
    sendError(res, err.statusCode || 500, err.message);
  }
};
