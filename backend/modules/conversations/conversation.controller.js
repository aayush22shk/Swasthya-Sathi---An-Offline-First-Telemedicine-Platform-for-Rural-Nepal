const conversationService = require('./conversation.service');
const pool = require('../../db');
const { sendSuccess, sendError } = require('../../utils/response');

// GET /api/v1/conversations — list for authenticated user
const listConversations = async (req, res) => {
  try {
    const data = await conversationService.listConversations(req.user.id, req.user.role);
    return sendSuccess(res, 200, 'Conversations retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// POST /api/v1/conversations — get or create conversation
// Doctor sends: { patient_id }  (patients.id UUID)
// Patient sends: { doctor_id } (doctors.id UUID)
const getOrCreate = async (req, res) => {
  try {
    let doctorId, patientId;

    if (req.user.role === 'doctor') {
      doctorId = await conversationService.getDoctorId(req.user.id);
      patientId = req.body.patient_id;
      if (!patientId) return sendError(res, 400, 'patient_id is required.');
    } else if (req.user.role === 'patient') {
      patientId = await conversationService.getPatientId(req.user.id);
      doctorId = req.body.doctor_id;
      if (!doctorId) return sendError(res, 400, 'doctor_id is required.');
    } else {
      return sendError(res, 403, 'Only doctors and patients can create conversations.');
    }

    const data = await conversationService.getOrCreateConversation(doctorId, patientId);
    return sendSuccess(res, 200, 'Conversation retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// GET /api/v1/conversations/:conversationId/messages
const getMessages = async (req, res) => {
  try {
    const { limit, before } = req.query;
    const data = await conversationService.getMessages(
      req.params.conversationId,
      req.user.id,
      req.user.role,
      { limit: parseInt(limit) || 50, before }
    );
    return sendSuccess(res, 200, 'Messages retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// POST /api/v1/conversations/:conversationId/messages
const sendMessage = async (req, res) => {
  try {
    const { content } = req.body;
    if (!content || !content.trim()) return sendError(res, 400, 'Message content cannot be empty.');
    const data = await conversationService.sendMessage(
      req.params.conversationId,
      req.user.id,
      req.user.role,
      content.trim()
    );
    return sendSuccess(res, 201, 'Message sent.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = { listConversations, getOrCreate, getMessages, sendMessage };
