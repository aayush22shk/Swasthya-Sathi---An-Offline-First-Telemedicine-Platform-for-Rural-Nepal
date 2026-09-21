const doctorService = require('./doctor.service');
const { sendSuccess, sendError } = require('../../utils/response');

// ---------------------------------------------------------------------------
// GET /api/v1/doctors  – list (public)
// ---------------------------------------------------------------------------
const listDoctors = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = Math.min(parseInt(req.query.limit, 10) || 20, 100);
    const nmc_status = req.query.nmc_status || undefined;

    const result = await doctorService.listDoctors({ page, limit, nmc_status });
    return sendSuccess(res, 200, 'Doctors retrieved.', result);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// ---------------------------------------------------------------------------
// GET /api/v1/doctors/me  – own profile (from JWT)
// ---------------------------------------------------------------------------
const getMyProfile = async (req, res) => {
  try {
    const profile = await doctorService.getDoctorByUserId(req.user.id);
    return sendSuccess(res, 200, 'Doctor profile retrieved.', profile);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// ---------------------------------------------------------------------------
// GET /api/v1/doctors/:id  – by doctor UUID
// ---------------------------------------------------------------------------
const getDoctor = async (req, res) => {
  try {
    const profile = await doctorService.getDoctorById(req.params.id);
    return sendSuccess(res, 200, 'Doctor profile retrieved.', profile);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// ---------------------------------------------------------------------------
// PUT /api/v1/doctors/:id  – update profile
// ---------------------------------------------------------------------------
const updateDoctor = async (req, res) => {
  try {
    const updated = await doctorService.updateDoctor(req.params.id, req.body);
    return sendSuccess(res, 200, 'Doctor profile updated.', updated);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// ---------------------------------------------------------------------------
// DELETE /api/v1/doctors/:id  – soft deactivate
// ---------------------------------------------------------------------------
const deleteDoctor = async (req, res) => {
  try {
    const result = await doctorService.deactivateDoctor(req.params.id);
    return sendSuccess(res, 200, result.message);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = { listDoctors, getMyProfile, getDoctor, updateDoctor, deleteDoctor };
