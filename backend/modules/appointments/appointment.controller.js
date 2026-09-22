const appointmentService = require('./appointment.service');
const pool = require('../../db');
const { sendSuccess, sendError } = require('../../utils/response');

const resolveEntityId = async (user) => {
  if (user.role === 'patient') {
    const res = await pool.query('SELECT id FROM patients WHERE user_id = $1', [user.id]);
    return { patientId: res.rows[0]?.id };
  } else if (user.role === 'doctor') {
    const res = await pool.query('SELECT id FROM doctors WHERE user_id = $1', [user.id]);
    return { doctorId: res.rows[0]?.id };
  }
  return {};
};

const bookAppointment = async (req, res) => {
  try {
    let { patient_id, doctor_id, scheduled_at, mode, fee, reason_for_visit } = req.body;

    if (req.user.role === 'patient') {
      const { patientId } = await resolveEntityId(req.user);
      patient_id = patientId;
    }

    if (!patient_id) {
      return sendError(res, 400, 'Patient ID is required.');
    }

    const data = await appointmentService.createAppointment({
      patient_id,
      doctor_id,
      scheduled_at,
      mode,
      fee,
      reason_for_visit,
      user_id: req.user.id,
    });

    return sendSuccess(res, 201, 'Appointment booked successfully.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const listAppointments = async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);
    const offset = parseInt(req.query.offset, 10) || 0;
    const status = req.query.status || undefined;

    let patient_id = req.query.patient_id;
    let doctor_id = req.query.doctor_id;

    if (req.user.role === 'patient') {
      const resolved = await resolveEntityId(req.user);
      patient_id = resolved.patientId;
    } else if (req.user.role === 'doctor') {
      const resolved = await resolveEntityId(req.user);
      doctor_id = resolved.doctorId;
    }

    const data = await appointmentService.listAppointments({
      patient_id,
      doctor_id,
      status,
      limit,
      offset,
    });

    return sendSuccess(res, 200, 'Appointments retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const getAppointment = async (req, res) => {
  try {
    const data = await appointmentService.getAppointmentById(req.params.id);
    return sendSuccess(res, 200, 'Appointment details retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const updateStatus = async (req, res) => {
  try {
    const { status, note } = req.body;
    const data = await appointmentService.updateAppointmentStatus(
      req.params.id,
      status,
      req.user.id,
      note
    );
    return sendSuccess(res, 200, `Appointment status updated to ${status}.`, data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const reschedule = async (req, res) => {
  try {
    const data = await appointmentService.rescheduleAppointment(req.params.id, req.body);
    return sendSuccess(res, 200, 'Appointment rescheduled.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = {
  bookAppointment,
  listAppointments,
  getAppointment,
  updateStatus,
  reschedule,
};
