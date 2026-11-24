const skinService = require('./skin-analysis.service');
const { sendSuccess, sendError } = require('../../utils/response');

const createAnalysis = async (req, res) => {
  try {
    const {
      image_url,
      predicted_condition,
      confidence_score,
      top_predictions,
      is_uncertain,
      uncertainty_reason,
      model_version,
    } = req.body;

    if (!image_url || !predicted_condition || confidence_score === undefined) {
      return sendError(res, 400, 'image_url, predicted_condition, and confidence_score are required.');
    }

    const record = await skinService.createSkinAnalysis(req.user.id, {
      image_url,
      predicted_condition,
      confidence_score: Number(confidence_score),
      top_predictions: top_predictions || [],
      is_uncertain: Boolean(is_uncertain),
      uncertainty_reason,
      model_version: model_version || 'mobilenetv3_nepal_v1',
    });

    return sendSuccess(res, 201, 'Skin analysis record saved successfully.', record);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const getMyAnalyses = async (req, res) => {
  try {
    const list = await skinService.getPatientAnalyses(req.user.id);
    return sendSuccess(res, 200, 'Patient skin analyses retrieved.', list);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const getAnalysisById = async (req, res) => {
  try {
    const record = await skinService.getSkinAnalysisById(req.params.id, req.user.id, req.user.role);
    return sendSuccess(res, 200, 'Analysis details retrieved.', record);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const shareWithDoctor = async (req, res) => {
  try {
    const { doctor_id, conversation_id } = req.body;
    if (!doctor_id) return sendError(res, 400, 'doctor_id is required.');

    const record = await skinService.shareAnalysisWithDoctor(req.params.id, req.user.id, {
      doctor_id,
      conversation_id,
    });
    return sendSuccess(res, 200, 'Analysis successfully shared with doctor.', record);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const reviewAnalysis = async (req, res) => {
  try {
    const { doctor_notes } = req.body;
    if (!doctor_notes) return sendError(res, 400, 'doctor_notes is required.');

    const record = await skinService.reviewSkinAnalysis(req.params.id, req.user.id, {
      doctor_notes,
    });
    return sendSuccess(res, 200, 'Doctor review recorded successfully.', record);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = {
  createAnalysis,
  getMyAnalyses,
  getAnalysisById,
  shareWithDoctor,
  reviewAnalysis,
};
