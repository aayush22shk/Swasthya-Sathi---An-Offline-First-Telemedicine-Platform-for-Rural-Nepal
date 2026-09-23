const followupService = require('./followup.service');
const pool = require('../../db');
const { sendSuccess, sendError } = require('../../utils/response');

const createFollowUp = async (req, res, next) => {
  try {
    // Get doctor_id from req.user.id
    const docRes = await pool.query('SELECT id FROM doctors WHERE user_id = $1', [req.user.id]);
    if (docRes.rows.length === 0) {
      return sendError(res, 403, 'Doctor profile not found for user.');
    }
    const doctorId = docRes.rows[0].id;

    const followUp = await followupService.createFollowUp({
      doctor_id: doctorId,
      patient_id: req.body.patient_id,
      consultation_id: req.body.consultation_id,
      appointment_id: req.body.appointment_id,
      follow_up_date: req.body.follow_up_date,
      notes: req.body.notes,
    });

    sendSuccess(res, 201, 'Follow-up scheduled successfully.', followUp);
  } catch (err) {
    next(err);
  }
};

const getDoctorFollowUps = async (req, res, next) => {
  try {
    const docRes = await pool.query('SELECT id FROM doctors WHERE user_id = $1', [req.user.id]);
    if (docRes.rows.length === 0) {
      return sendError(res, 403, 'Doctor profile not found.');
    }
    const doctorId = docRes.rows[0].id;

    const followUps = await followupService.getDoctorFollowUps(doctorId, req.query.status);
    sendSuccess(res, 200, 'Doctor follow-ups retrieved.', followUps);
  } catch (err) {
    next(err);
  }
};

const getPatientFollowUps = async (req, res, next) => {
  try {
    const patRes = await pool.query('SELECT id FROM patients WHERE user_id = $1', [req.user.id]);
    if (patRes.rows.length === 0) {
      return sendError(res, 403, 'Patient profile not found.');
    }
    const patientId = patRes.rows[0].id;

    const followUps = await followupService.getPatientFollowUps(patientId, req.query.status);
    sendSuccess(res, 200, 'Patient follow-ups retrieved.', followUps);
  } catch (err) {
    next(err);
  }
};

const updateStatus = async (req, res, next) => {
  try {
    const updated = await followupService.updateFollowUpStatus(
      req.params.id,
      req.body.status,
      req.body.notes
    );
    sendSuccess(res, 200, 'Follow-up status updated.', updated);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createFollowUp,
  getDoctorFollowUps,
  getPatientFollowUps,
  updateStatus,
};
