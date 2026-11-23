const svc = require('./conv-prescription.service');
const { sendSuccess, sendError } = require('../../utils/response');

// POST /api/v1/conv-prescriptions
const create = async (req, res) => {
  try {
    const { conversation_id, title, additional_instructions, medicines } = req.body;
    const data = await svc.createConvPrescription(conversation_id, req.user.id, {
      title, additional_instructions, medicines,
    });
    return sendSuccess(res, 201, 'Prescription created.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// GET /api/v1/conv-prescriptions/:id
const getById = async (req, res) => {
  try {
    const data = await svc.getConvPrescriptionById(req.params.id, req.user.id, req.user.role);
    return sendSuccess(res, 200, 'Prescription retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// GET /api/v1/conv-prescriptions/patient/:patientId
const getByPatient = async (req, res) => {
  try {
    const data = await svc.getConvPrescriptionsByPatient(req.params.patientId, req.user.id, req.user.role);
    return sendSuccess(res, 200, 'Patient prescriptions retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = { create, getById, getByPatient };
