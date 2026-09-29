const appointmentService = require('./appointment.service');
const pool = require('../../db');
const { sendSuccess, sendError } = require('../../utils/response');

/**
 * Resolves the role-specific entity ID (patients.id or doctors.id)
 * from the authenticated user's users.id.
 */
const resolveEntityId = async (user) => {
  if (user.role === 'patient') {
    const res = await pool.query('SELECT id FROM patients WHERE user_id = $1', [user.id]);
    if (res.rows.length === 0) {
      const err = new Error('Patient profile not found for this account. Please complete your profile.');
      err.statusCode = 404;
      throw err;
    }
    return { patientId: res.rows[0].id };
  } else if (user.role === 'doctor') {
    const res = await pool.query('SELECT id FROM doctors WHERE user_id = $1', [user.id]);
    if (res.rows.length === 0) {
      const err = new Error('Doctor profile not found for this account.');
      err.statusCode = 404;
      throw err;
    }
    return { doctorId: res.rows[0].id };
  }
  return {};
};

const bookAppointment = async (req, res) => {
  try {
    let { patient_id, doctor_id, scheduled_at, mode, fee, reason_for_visit } = req.body;

    console.log('[AppointmentController] bookAppointment() called by user:', req.user.id, 'role:', req.user.role);
    console.log('[AppointmentController] Request body:', { doctor_id, scheduled_at, mode, fee, reason_for_visit });

    // If the requester is a patient, resolve their patient_id from users table
    if (req.user.role === 'patient') {
      const { patientId } = await resolveEntityId(req.user);
      patient_id = patientId;
      console.log('[AppointmentController] Resolved patient_id for user', req.user.id, '→', patient_id);
    }

    if (!patient_id) {
      return sendError(res, 400, 'Patient ID is required. Ensure your patient profile is complete.');
    }

    if (!doctor_id) {
      return sendError(res, 400, 'Doctor ID is required.');
    }

    if (!scheduled_at) {
      return sendError(res, 400, 'scheduled_at is required.');
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
    console.error('[AppointmentController] bookAppointment() error:', err.message);
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const listAppointments = async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);
    const offset = parseInt(req.query.offset, 10) || 0;
    const status = req.query.status || undefined;

    let patient_id = req.query.patient_id;
    let doctor_id  = req.query.doctor_id;

    // Automatically scope to the authenticated user's entity
    if (req.user.role === 'patient') {
      const resolved = await resolveEntityId(req.user);
      patient_id = resolved.patientId;
    } else if (req.user.role === 'doctor') {
      const resolved = await resolveEntityId(req.user);
      doctor_id = resolved.doctorId;
    }

    console.log('[AppointmentController] listAppointments() user:', req.user.id, 'role:', req.user.role, 'patient_id:', patient_id, 'doctor_id:', doctor_id);

    const data = await appointmentService.listAppointments({
      patient_id,
      doctor_id,
      status,
      limit,
      offset,
    });

    return sendSuccess(res, 200, 'Appointments retrieved.', data);
  } catch (err) {
    console.error('[AppointmentController] listAppointments() error:', err.message);
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const getAppointment = async (req, res) => {
  try {
    const data = await appointmentService.getAppointmentById(req.params.id);
    return sendSuccess(res, 200, 'Appointment details retrieved.', data);
  } catch (err) {
    console.error('[AppointmentController] getAppointment() error:', err.message);
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const updateStatus = async (req, res) => {
  try {
    const { status, note } = req.body;
    console.log('[AppointmentController] updateStatus() appointmentId:', req.params.id, 'newStatus:', status, 'by user:', req.user.id);

    const data = await appointmentService.updateAppointmentStatus(
      req.params.id,
      status,
      req.user.id,
      note
    );
    return sendSuccess(res, 200, `Appointment status updated to ${status}.`, data);
  } catch (err) {
    console.error('[AppointmentController] updateStatus() error:', err.message);
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const reschedule = async (req, res) => {
  try {
    const data = await appointmentService.rescheduleAppointment(req.params.id, req.body);
    return sendSuccess(res, 200, 'Appointment rescheduled.', data);
  } catch (err) {
    console.error('[AppointmentController] reschedule() error:', err.message);
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
