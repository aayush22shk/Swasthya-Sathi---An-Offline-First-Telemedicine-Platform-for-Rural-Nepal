const consultationService = require('./consultation.service');
const { sendSuccess, sendError } = require('../../utils/response');

const startSession = async (req, res) => {
  try {
    const data = await consultationService.startConsultation(req.body);
    return sendSuccess(res, 201, 'Consultation session started.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const getConsultation = async (req, res) => {
  try {
    const data = await consultationService.getConsultationById(req.params.id);
    return sendSuccess(res, 200, 'Consultation retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const endSession = async (req, res) => {
  try {
    const data = await consultationService.endConsultation(req.params.id, req.body);
    return sendSuccess(res, 200, 'Consultation concluded.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const listMessages = async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 100, 200);
    const offset = parseInt(req.query.offset, 10) || 0;
    const data = await consultationService.getChatMessages(req.params.id, { limit, offset });
    return sendSuccess(res, 200, 'Chat messages retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const sendMessage = async (req, res) => {
  try {
    const data = await consultationService.sendChatMessage(
      req.params.id,
      req.user.id,
      req.body
    );
    return sendSuccess(res, 201, 'Message sent.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = {
  startSession,
  getConsultation,
  endSession,
  listMessages,
  sendMessage,
};
