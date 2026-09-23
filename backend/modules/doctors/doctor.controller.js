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

// ---------------------------------------------------------------------------
// Helper: resolve doctor entity id from JWT user id
// ---------------------------------------------------------------------------
const resolveDoctorId = async (userId) => {
  const pool = require('../../db');
  const res = await pool.query('SELECT id FROM doctors WHERE user_id = $1', [userId]);
  if (res.rows.length === 0) {
    const err = new Error('Doctor profile not found.');
    err.statusCode = 404;
    throw err;
  }
  return res.rows[0].id;
};

// ---------------------------------------------------------------------------
// GET /api/v1/doctors/me/patients
// – Return only patients with an appointment with this doctor
// ---------------------------------------------------------------------------
const getMyPatients = async (req, res) => {
  try {
    const doctorId = await resolveDoctorId(req.user.id);
    const patients = await doctorService.getDoctorPatients(doctorId);
    return sendSuccess(res, 200, 'Patients retrieved.', patients);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// ---------------------------------------------------------------------------
// GET /api/v1/doctors/me/patients/:patientId
// – Get single patient full profile (auth-checked)
// ---------------------------------------------------------------------------
const getMyPatientById = async (req, res) => {
  try {
    const doctorId = await resolveDoctorId(req.user.id);
    const patient = await doctorService.getDoctorPatientById(doctorId, req.params.patientId);
    return sendSuccess(res, 200, 'Patient details retrieved.', patient);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// ---------------------------------------------------------------------------
// GET /api/v1/doctors/me/prescriptions
// – Return all prescriptions issued by this doctor
// ---------------------------------------------------------------------------
const getMyPrescriptions = async (req, res) => {
  try {
    const doctorId = await resolveDoctorId(req.user.id);
    const prescriptions = await doctorService.getDoctorPrescriptions(doctorId);
    return sendSuccess(res, 200, 'Prescriptions retrieved.', prescriptions);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// ---------------------------------------------------------------------------
// GET /api/v1/doctors/me/conversations
// – Return consultation chat threads for this doctor
// ---------------------------------------------------------------------------
const getMyConversations = async (req, res) => {
  try {
    const doctorId = await resolveDoctorId(req.user.id);
    const conversations = await doctorService.getDoctorConversations(doctorId);
    return sendSuccess(res, 200, 'Conversations retrieved.', conversations);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = {
  listDoctors, getMyProfile, getDoctor, updateDoctor, deleteDoctor,
  getMyPatients, getMyPatientById, getMyPrescriptions, getMyConversations,
};
