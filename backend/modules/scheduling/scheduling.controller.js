const schedulingService = require('./scheduling.service');
const pool = require('../../db');
const { sendSuccess, sendError } = require('../../utils/response');

const getDoctorId = async (userId) => {
  const res = await pool.query('SELECT id FROM doctors WHERE user_id = $1', [userId]);
  if (res.rows.length === 0) {
    const err = new Error('Doctor profile not found for user.');
    err.statusCode = 404;
    throw err;
  }
  return res.rows[0].id;
};

const getAvailability = async (req, res) => {
  try {
    const data = await schedulingService.getDoctorAvailability(req.params.doctorId);
    return sendSuccess(res, 200, 'Doctor availability retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const createSlot = async (req, res) => {
  try {
    const doctorId = await getDoctorId(req.user.id);
    const data = await schedulingService.createAvailabilitySlot(doctorId, req.body);
    return sendSuccess(res, 201, 'Availability slot created.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const updateSlot = async (req, res) => {
  try {
    const doctorId = await getDoctorId(req.user.id);
    const data = await schedulingService.updateAvailabilitySlot(req.params.id, doctorId, req.body);
    return sendSuccess(res, 200, 'Availability slot updated.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const deleteSlot = async (req, res) => {
  try {
    const doctorId = await getDoctorId(req.user.id);
    const result = await schedulingService.deleteAvailabilitySlot(req.params.id, doctorId);
    return sendSuccess(res, 200, result.message);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const addTimeOff = async (req, res) => {
  try {
    const doctorId = await getDoctorId(req.user.id);
    const data = await schedulingService.addTimeOff(doctorId, req.body);
    return sendSuccess(res, 201, 'Time off scheduled.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const deleteTimeOff = async (req, res) => {
  try {
    const doctorId = await getDoctorId(req.user.id);
    const result = await schedulingService.deleteTimeOff(req.params.id, doctorId);
    return sendSuccess(res, 200, result.message);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = {
  getAvailability,
  createSlot,
  updateSlot,
  deleteSlot,
  addTimeOff,
  deleteTimeOff,
};
