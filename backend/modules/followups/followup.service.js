const pool = require('../../db');

const createFollowUp = async ({ doctor_id, patient_id, consultation_id, appointment_id, follow_up_date, notes }) => {
  const result = await pool.query(
    `INSERT INTO follow_ups (doctor_id, patient_id, consultation_id, appointment_id, follow_up_date, notes, status)
     VALUES ($1, $2, $3, $4, $5, $6, 'upcoming')
     RETURNING *`,
    [doctor_id, patient_id, consultation_id || null, appointment_id || null, follow_up_date, notes || null]
  );
  const followUp = result.rows[0];

  // Notify patient
  const patRes = await pool.query('SELECT user_id, full_name FROM patients WHERE id = $1', [patient_id]);
  const docRes = await pool.query('SELECT full_name FROM doctors WHERE id = $1', [doctor_id]);
  if (patRes.rows.length > 0) {
    const docName = docRes.rows.length > 0 ? docRes.rows[0].full_name : 'Your Doctor';
    await pool.query(
      `INSERT INTO notifications (user_id, type, title, message)
       VALUES ($1, 'followup_scheduled', 'Follow-up Scheduled', $2)`,
      [patRes.rows[0].user_id, `${docName} has scheduled a follow-up for you on ${follow_up_date}.`]
    );
  }

  return followUp;
};

const getDoctorFollowUps = async (doctorId, status) => {
  let query = `
    SELECT
      f.*,
      p.full_name AS patient_name,
      p.dob AS patient_dob,
      p.gender AS patient_gender,
      p.blood_group AS patient_blood_group,
      p.profile_photo_url AS patient_photo_url,
      u.phone AS patient_phone,
      d.full_name AS doctor_name,
      (
        SELECT s.name
        FROM doctor_specializations ds
        JOIN specializations s ON s.id = ds.specialization_id
        WHERE ds.doctor_id = d.id
        ORDER BY s.id
        LIMIT 1
      ) AS doctor_specialty
    FROM follow_ups f
    JOIN patients p ON p.id = f.patient_id
    JOIN users u ON u.id = p.user_id
    JOIN doctors d ON d.id = f.doctor_id
    WHERE f.doctor_id = $1
  `;
  const params = [doctorId];

  if (status) {
    params.push(status);
    query += ` AND f.status = $${params.length}`;
  }

  query += ` ORDER BY f.follow_up_date ASC`;

  const result = await pool.query(query, params);
  return result.rows;
};

const getPatientFollowUps = async (patientId, status) => {
  let query = `
    SELECT
      f.*,
      d.full_name AS doctor_name,
      d.profile_photo_url AS doctor_photo_url,
      p.full_name AS patient_name
    FROM follow_ups f
    JOIN doctors d ON d.id = f.doctor_id
    JOIN patients p ON p.id = f.patient_id
    WHERE f.patient_id = $1
  `;
  const params = [patientId];

  if (status) {
    params.push(status);
    query += ` AND f.status = $${params.length}`;
  }

  query += ` ORDER BY f.follow_up_date ASC`;

  const result = await pool.query(query, params);
  return result.rows;
};

const updateFollowUpStatus = async (id, status, notes) => {
  const result = await pool.query(
    `UPDATE follow_ups
     SET status = $1, notes = COALESCE($2, notes), updated_at = now()
     WHERE id = $3
     RETURNING *`,
    [status, notes || null, id]
  );
  if (result.rows.length === 0) {
    const err = new Error('Follow-up not found.');
    err.statusCode = 404;
    throw err;
  }
  return result.rows[0];
};

module.exports = {
  createFollowUp,
  getDoctorFollowUps,
  getPatientFollowUps,
  updateFollowUpStatus,
};
