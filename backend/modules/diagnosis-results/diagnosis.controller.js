const svc = require('./diagnosis.service');
const { sendSuccess, sendError } = require('../../utils/response');

const create = async (req, res) => {
  try {
    const { conversation_id, title, description, findings, recommended_treatment, additional_notes } = req.body;
    const data = await svc.createDiagnosis(conversation_id, req.user.id, {
      title, description, findings, recommended_treatment, additional_notes,
    });
    return sendSuccess(res, 201, 'Diagnosis created.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const getById = async (req, res) => {
  try {
    const data = await svc.getDiagnosisById(req.params.id, req.user.id, req.user.role);
    return sendSuccess(res, 200, 'Diagnosis retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const getByPatient = async (req, res) => {
  try {
    const data = await svc.getDiagnosesByPatient(req.params.patientId, req.user.id, req.user.role);
    return sendSuccess(res, 200, 'Patient diagnoses retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = { create, getById, getByPatient };
