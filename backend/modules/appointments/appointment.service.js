const pool = require('../../db');

const createAppointment = async ({ patient_id, doctor_id, scheduled_at, mode, fee, reason_for_visit, user_id }) => {
  console.log('[AppointmentService] createAppointment() called:', {
    patient_id,
    doctor_id,
    scheduled_at,
    mode,
    fee,
    reason_for_visit,
    user_id,
  });

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Verify patient exists
    const patientCheck = await client.query('SELECT id FROM patients WHERE id = $1', [patient_id]);
    if (patientCheck.rows.length === 0) {
      const err = new Error(`Patient with id '${patient_id}' does not exist.`);
      err.statusCode = 400;
      throw err;
    }

    // 2. Verify doctor exists
    const doctorCheck = await client.query('SELECT id FROM doctors WHERE id = $1', [doctor_id]);
    if (doctorCheck.rows.length === 0) {
      const err = new Error(`Doctor with id '${doctor_id}' does not exist.`);
      err.statusCode = 400;
      throw err;
    }

    // 3. Insert appointment
    const res = await client.query(
      `INSERT INTO appointments (patient_id, doctor_id, scheduled_at, mode, status, fee, reason_for_visit)
       VALUES ($1, $2, $3, COALESCE($4, 'video'), 'pending', COALESCE($5, 0), $6)
       RETURNING *`,
      [patient_id, doctor_id, scheduled_at, mode, fee, reason_for_visit || null]
    );
    const appointment = res.rows[0];
    console.log('[AppointmentService] createAppointment() inserted row:', appointment.id, 'status:', appointment.status);

    // 4. Log status history
    await client.query(
      `INSERT INTO appointment_status_history (appointment_id, old_status, new_status, changed_by, note)
       VALUES ($1, NULL, 'pending', $2, 'Appointment booked.')`,
      [appointment.id, user_id || null]
    );

    // 5. Create a notification for the doctor
    const docUser = await client.query('SELECT user_id FROM doctors WHERE id = $1', [doctor_id]);
    if (docUser.rows.length > 0) {
      await client.query(
        `INSERT INTO notifications (user_id, type, title, message)
         VALUES ($1, 'appointment_request', 'New Appointment Request', 'You have a new appointment booking request awaiting review.')`,
        [docUser.rows[0].user_id]
      );
    }

    await client.query('COMMIT');
    console.log('[AppointmentService] createAppointment() committed successfully. id:', appointment.id);
    return appointment;
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[AppointmentService] createAppointment() ROLLBACK due to error:', err.message);
    throw err;
  } finally {
    client.release();
  }
};

const listAppointments = async ({ patient_id, doctor_id, status, limit = 50, offset = 0 }) => {
  const conditions = [];
  const params = [];

  if (patient_id) {
    conditions.push(`a.patient_id = $${params.length + 1}`);
    params.push(patient_id);
  }
  if (doctor_id) {
    conditions.push(`a.doctor_id = $${params.length + 1}`);
    params.push(doctor_id);
  }
  if (status) {
    conditions.push(`a.status = $${params.length + 1}`);
    params.push(status);
  }

  const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
  params.push(limit, offset);

  const limitIdx  = params.length - 1; // 1-based index for LIMIT
  const offsetIdx = params.length;     // 1-based index for OFFSET

  const res = await pool.query(
    `SELECT
       a.id,
       a.patient_id,
       a.doctor_id,
       a.scheduled_at,
       a.mode,
       a.status,
       a.fee,
       a.reason_for_visit,
       a.created_at,
       a.updated_at,

       -- Patient fields
       p.full_name    AS patient_name,
       p.dob          AS patient_dob,
       p.gender       AS patient_gender,
       p.profile_photo_url AS patient_photo_url,
       u_pat.phone    AS patient_phone,

       -- Doctor fields
       d.full_name       AS doctor_name,
       d.profile_photo_url AS doctor_photo_url,
       d.nmc_registration_number,
       d.consultation_fee AS doctor_consultation_fee,

       -- Doctor primary specialization (subquery)
       (
         SELECT s.name
         FROM doctor_specializations ds
         JOIN specializations s ON s.id = ds.specialization_id
         WHERE ds.doctor_id = a.doctor_id
         ORDER BY s.id
         LIMIT 1
       ) AS doctor_specialty

     FROM appointments a
     JOIN patients p  ON p.id = a.patient_id
     JOIN users u_pat ON u_pat.id = p.user_id
     JOIN doctors d   ON d.id = a.doctor_id
     ${where}
     ORDER BY a.scheduled_at DESC
     LIMIT $${limitIdx} OFFSET $${offsetIdx}`,
    params
  );

  return res.rows;
};

const getAppointmentById = async (appointmentId) => {
  const aptRes = await pool.query(
    `SELECT
       a.*,

       -- Patient
       p.full_name    AS patient_name,
       p.dob          AS patient_dob,
       p.gender       AS patient_gender,
       p.blood_group  AS patient_blood_group,
       p.profile_photo_url AS patient_photo_url,
       u_pat.phone    AS patient_phone,

       -- Doctor
       d.full_name         AS doctor_name,
       d.profile_photo_url AS doctor_photo_url,
       d.nmc_registration_number,
       d.consultation_fee  AS doctor_consultation_fee,

       (
         SELECT s.name
         FROM doctor_specializations ds
         JOIN specializations s ON s.id = ds.specialization_id
         WHERE ds.doctor_id = a.doctor_id
         ORDER BY s.id
         LIMIT 1
       ) AS doctor_specialty

     FROM appointments a
     JOIN patients p  ON p.id = a.patient_id
     JOIN users u_pat ON u_pat.id = p.user_id
     JOIN doctors d   ON d.id = a.doctor_id
     WHERE a.id = $1`,
    [appointmentId]
  );

  if (aptRes.rows.length === 0) {
    const err = new Error('Appointment not found.');
    err.statusCode = 404;
    throw err;
  }

  const historyRes = await pool.query(
    `SELECT id, old_status, new_status, changed_by, changed_at, note
     FROM appointment_status_history
     WHERE appointment_id = $1
     ORDER BY changed_at ASC`,
    [appointmentId]
  );

  return {
    ...aptRes.rows[0],
    history: historyRes.rows,
  };
};

const updateAppointmentStatus = async (appointmentId, newStatus, changedByUserId, note) => {
  console.log('[AppointmentService] updateAppointmentStatus():', { appointmentId, newStatus, changedByUserId });

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Get current appointment
    const currentRes = await client.query(
      'SELECT status, patient_id, doctor_id FROM appointments WHERE id = $1',
      [appointmentId]
    );
    if (currentRes.rows.length === 0) {
      const err = new Error('Appointment not found.');
      err.statusCode = 404;
      throw err;
    }
    const current = currentRes.rows[0];

    // 2. Update status
    const updateRes = await client.query(
      `UPDATE appointments
       SET status = $1, updated_at = now()
       WHERE id = $2
       RETURNING *`,
      [newStatus, appointmentId]
    );

    // 3. Log history
    await client.query(
      `INSERT INTO appointment_status_history (appointment_id, old_status, new_status, changed_by, note)
       VALUES ($1, $2, $3, $4, $5)`,
      [appointmentId, current.status, newStatus, changedByUserId || null, note || `Status changed to ${newStatus}.`]
    );

    // 4. Notify patient
    const patUser = await client.query('SELECT user_id FROM patients WHERE id = $1', [current.patient_id]);
    if (patUser.rows.length > 0) {
      const statusLabel = newStatus === 'confirmed' ? 'Accepted' : newStatus.charAt(0).toUpperCase() + newStatus.slice(1);
      await client.query(
        `INSERT INTO notifications (user_id, type, title, message)
         VALUES ($1, 'appointment_status', $2, $3)`,
        [
          patUser.rows[0].user_id,
          `Appointment ${statusLabel}`,
          `Your appointment has been ${statusLabel.toLowerCase()} by the doctor.`,
        ]
      );
    }

    await client.query('COMMIT');
    console.log('[AppointmentService] updateAppointmentStatus() committed. id:', appointmentId, '→', newStatus);
    return updateRes.rows[0];
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[AppointmentService] updateAppointmentStatus() ROLLBACK:', err.message);
    throw err;
  } finally {
    client.release();
  }
};

const rescheduleAppointment = async (appointmentId, { scheduled_at, mode, reason }) => {
  const res = await pool.query(
    `UPDATE appointments
     SET scheduled_at = COALESCE($1, scheduled_at),
         mode = COALESCE($2, mode),
         reason_for_visit = COALESCE($3, reason_for_visit),
         updated_at = now()
     WHERE id = $4
     RETURNING *`,
    [scheduled_at, mode, reason, appointmentId]
  );
  if (res.rows.length === 0) {
    const err = new Error('Appointment not found.');
    err.statusCode = 404;
    throw err;
  }
  return res.rows[0];
};

module.exports = {
  createAppointment,
  listAppointments,
  getAppointmentById,
  updateAppointmentStatus,
  rescheduleAppointment,
};
