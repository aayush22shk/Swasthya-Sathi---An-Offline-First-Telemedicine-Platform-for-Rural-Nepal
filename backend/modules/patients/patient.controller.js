const patientService = require('./patient.service');
const { sendSuccess, sendError } = require('../../utils/response');

// ---------------------------------------------------------------------------
// GET /api/v1/patients/me  – own profile via JWT
// ---------------------------------------------------------------------------
const getMyProfile = async (req, res) => {
  try {
    const profile = await patientService.getPatientByUserId(req.user.id);
    return sendSuccess(res, 200, 'Patient profile retrieved.', profile);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// ---------------------------------------------------------------------------
// GET /api/v1/patients/:id  – profile by patient UUID
// ---------------------------------------------------------------------------
const getPatient = async (req, res) => {
  try {
    const profile = await patientService.getPatientById(req.params.id);
    return sendSuccess(res, 200, 'Patient profile retrieved.', profile);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// ---------------------------------------------------------------------------
// PUT /api/v1/patients/:id  – update profile
// ---------------------------------------------------------------------------
const updatePatient = async (req, res) => {
  try {
    const updated = await patientService.updatePatient(req.params.id, req.body);
    return sendSuccess(res, 200, 'Patient profile updated.', updated);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// ---------------------------------------------------------------------------
// DELETE /api/v1/patients/:id  – soft deactivate
// ---------------------------------------------------------------------------
const deletePatient = async (req, res) => {
  try {
    const result = await patientService.deactivatePatient(req.params.id);
    return sendSuccess(res, 200, result.message);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = { getMyProfile, getPatient, updatePatient, deletePatient };
