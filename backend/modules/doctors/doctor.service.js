const pool = require('../../db');

// ---------------------------------------------------------------------------
// LIST all doctors (publicly browsable — only verified or all based on query)
// ---------------------------------------------------------------------------

/**
 * Fetch a paginated list of doctors with their specializations.
 * @param {{ page?: number, limit?: number, nmc_status?: string }} options
 */
const listDoctors = async ({ page = 1, limit = 20, nmc_status } = {}) => {
  const offset = (page - 1) * limit;

  // Build optional status filter
  const conditions = [];
  const params = [];
  if (nmc_status) {
    conditions.push(`d.nmc_status = $${params.length + 1}::verification_status`);
    params.push(nmc_status);
  }

  const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  // Total count
  const countResult = await pool.query(
    `SELECT COUNT(*) FROM doctors d ${where}`,
    params
  );
  const total = parseInt(countResult.rows[0].count, 10);

  // Fetch rows
  params.push(limit, offset);
  const result = await pool.query(
    `SELECT
       d.id, d.full_name, d.nmc_registration_number, d.nmc_status,
       d.experience_years, d.consultation_fee, d.bio,
       d.is_available, d.average_rating, d.profile_photo_url,
       u.phone, u.email, u.preferred_language,
       -- Aggregate specializations as JSON array
       COALESCE(
         json_agg(
           json_build_object('id', s.id, 'name', s.name)
         ) FILTER (WHERE s.id IS NOT NULL),
         '[]'
       ) AS specializations
     FROM doctors d
     JOIN users u ON u.id = d.user_id
     LEFT JOIN doctor_specializations ds ON ds.doctor_id = d.id
     LEFT JOIN specializations s ON s.id = ds.specialization_id
     ${where}
     GROUP BY d.id, u.phone, u.email, u.preferred_language
     ORDER BY d.average_rating DESC, d.created_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return {
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit),
    doctors: result.rows,
  };
};

// ---------------------------------------------------------------------------
// GET single doctor by doctors.id
// ---------------------------------------------------------------------------
const getDoctorById = async (doctorId) => {
  const result = await pool.query(
    `SELECT
       d.id, d.full_name, d.nmc_registration_number, d.nmc_status,
       d.nmc_verified_at, d.experience_years, d.consultation_fee,
       d.bio, d.is_available, d.average_rating, d.profile_photo_url,
       d.created_at, d.updated_at,
       u.id AS user_id, u.phone, u.email, u.preferred_language, u.status,
       COALESCE(
         json_agg(
           DISTINCT jsonb_build_object('id', s.id, 'name', s.name)
         ) FILTER (WHERE s.id IS NOT NULL),
         '[]'
       ) AS specializations
     FROM doctors d
     JOIN users u ON u.id = d.user_id
     LEFT JOIN doctor_specializations ds ON ds.doctor_id = d.id
     LEFT JOIN specializations s ON s.id = ds.specialization_id
     WHERE d.id = $1
     GROUP BY d.id, u.id`,
    [doctorId]
  );

  if (result.rows.length === 0) {
    const err = new Error('Doctor not found.');
    err.statusCode = 404;
    throw err;
  }

  return result.rows[0];
};

// ---------------------------------------------------------------------------
// GET doctor by user_id (from JWT payload)
// ---------------------------------------------------------------------------
const getDoctorByUserId = async (userId) => {
  const result = await pool.query(
    `SELECT
       d.id, d.full_name, d.nmc_registration_number, d.nmc_status,
       d.nmc_verified_at, d.experience_years, d.consultation_fee,
       d.bio, d.is_available, d.average_rating, d.profile_photo_url,
       d.created_at, d.updated_at,
       u.id AS user_id, u.phone, u.email, u.preferred_language, u.status
     FROM doctors d
     JOIN users u ON u.id = d.user_id
     WHERE d.user_id = $1`,
    [userId]
  );

  if (result.rows.length === 0) {
    const err = new Error('Doctor profile not found.');
    err.statusCode = 404;
    throw err;
  }

  return result.rows[0];
};

// ---------------------------------------------------------------------------
// UPDATE doctor profile
// ---------------------------------------------------------------------------

/**
 * @param {string} doctorId
 * @param {{
 *   full_name?: string,
 *   bio?: string,
 *   consultation_fee?: number,
 *   experience_years?: number,
 *   is_available?: boolean,
 *   profile_photo_url?: string,
 * }} fields
 */
const updateDoctor = async (doctorId, fields) => {
  const {
    full_name,
    bio,
    consultation_fee,
    experience_years,
    is_available,
    profile_photo_url,
  } = fields;

  const result = await pool.query(
    `UPDATE doctors SET
       full_name         = COALESCE($1, full_name),
       bio               = COALESCE($2, bio),
       consultation_fee  = COALESCE($3, consultation_fee),
       experience_years  = COALESCE($4, experience_years),
       is_available      = COALESCE($5, is_available),
       profile_photo_url = COALESCE($6, profile_photo_url),
       updated_at        = now()
     WHERE id = $7
     RETURNING id, full_name, bio, consultation_fee, experience_years,
               is_available, nmc_status, average_rating, profile_photo_url, updated_at`,
    [
      full_name || null,
      bio !== undefined ? bio : null,
      consultation_fee !== undefined ? consultation_fee : null,
      experience_years !== undefined ? experience_years : null,
      is_available !== undefined ? is_available : null,
      profile_photo_url || null,
      doctorId,
    ]
  );

  if (result.rows.length === 0) {
    const err = new Error('Doctor not found.');
    err.statusCode = 404;
    throw err;
  }

  return result.rows[0];
};

// ---------------------------------------------------------------------------
// DEACTIVATE doctor (soft delete)
// ---------------------------------------------------------------------------
const deactivateDoctor = async (doctorId) => {
  const d = await pool.query('SELECT user_id FROM doctors WHERE id = $1', [doctorId]);
  if (d.rows.length === 0) {
    const err = new Error('Doctor not found.');
    err.statusCode = 404;
    throw err;
  }

  await pool.query(
    `UPDATE users SET status = 'deactivated', updated_at = now() WHERE id = $1`,
    [d.rows[0].user_id]
  );

  return { message: 'Doctor account deactivated.' };
};

// ---------------------------------------------------------------------------
// GET doctor's patients — only those with at least one appointment/consultation
// ---------------------------------------------------------------------------
const getDoctorPatients = async (doctorId) => {
  const result = await pool.query(
    `SELECT DISTINCT
       p.id, p.full_name, p.dob, p.gender, p.blood_group, p.profile_photo_url,
       u.phone AS patient_phone, p.emergency_contact_phone,
       u.email, u.preferred_language,
       -- Most recent appointment info
       (
         SELECT a.status FROM appointments a
         WHERE a.patient_id = p.id AND a.doctor_id = $1
         ORDER BY a.scheduled_at DESC LIMIT 1
       ) AS last_appointment_status,
       (
         SELECT a.scheduled_at FROM appointments a
         WHERE a.patient_id = p.id AND a.doctor_id = $1
         ORDER BY a.scheduled_at DESC LIMIT 1
       ) AS last_appointment_at,
       (
         SELECT a.reason_for_visit FROM appointments a
         WHERE a.patient_id = p.id AND a.doctor_id = $1
         ORDER BY a.scheduled_at DESC LIMIT 1
       ) AS last_reason
     FROM patients p
     JOIN users u ON u.id = p.user_id
     JOIN appointments a ON a.patient_id = p.id
     WHERE a.doctor_id = $1
     ORDER BY last_appointment_at DESC`,
    [doctorId]
  );
  return result.rows;
};

// ---------------------------------------------------------------------------
// GET single patient detail (authorized — only if relationship exists)
// ---------------------------------------------------------------------------
const getDoctorPatientById = async (doctorId, patientId) => {
  // Authorization check
  const authCheck = await pool.query(
    `SELECT 1 FROM appointments WHERE doctor_id = $1 AND patient_id = $2 LIMIT 1`,
    [doctorId, patientId]
  );
  if (authCheck.rows.length === 0) {
    const err = new Error('Patient not associated with this doctor.');
    err.statusCode = 403;
    throw err;
  }

  // Patient profile
  const patRes = await pool.query(
    `SELECT
       p.id, p.full_name, p.dob, p.gender, p.blood_group, p.profile_photo_url,
       u.phone AS patient_phone, p.emergency_contact_phone, p.address_line AS address,
       u.email, u.preferred_language
     FROM patients p
     JOIN users u ON u.id = p.user_id
     WHERE p.id = $1`,
    [patientId]
  );

  if (patRes.rows.length === 0) {
    const err = new Error('Patient not found.');
    err.statusCode = 404;
    throw err;
  }

  // Appointment history with this doctor
  const aptRes = await pool.query(
    `SELECT id, scheduled_at, mode, status, fee, reason_for_visit
     FROM appointments
     WHERE doctor_id = $1 AND patient_id = $2
     ORDER BY scheduled_at DESC`,
    [doctorId, patientId]
  );

  // Prescriptions from this doctor
  const rxRes = await pool.query(
    `SELECT
       p2.id, p2.issued_at, p2.notes,
       COALESCE(json_agg(pi.*) FILTER (WHERE pi.id IS NOT NULL), '[]') AS items
     FROM prescriptions p2
     LEFT JOIN prescription_items pi ON pi.prescription_id = p2.id
     WHERE p2.doctor_id = $1 AND p2.patient_id = $2
     GROUP BY p2.id
     ORDER BY p2.issued_at DESC`,
    [doctorId, patientId]
  );

  return {
    ...patRes.rows[0],
    appointments: aptRes.rows,
    prescriptions: rxRes.rows,
  };
};

// ---------------------------------------------------------------------------
// GET doctor's prescriptions — all prescriptions issued by doctor
// ---------------------------------------------------------------------------
const getDoctorPrescriptions = async (doctorId) => {
  const result = await pool.query(
    `SELECT
       p.id, p.issued_at, p.notes,
       pat.id AS patient_id, pat.full_name AS patient_name,
       pat.profile_photo_url AS patient_photo_url,
       COALESCE(json_agg(
         json_build_object(
           'id', pi.id,
           'medicine_name', pi.medicine_name,
           'dosage', pi.dosage,
           'route', pi.route,
           'frequency', pi.frequency,
           'duration_days', pi.duration_days,
           'instructions', pi.instructions
         )
       ) FILTER (WHERE pi.id IS NOT NULL), '[]') AS items
     FROM prescriptions p
     JOIN patients pat ON pat.id = p.patient_id
     LEFT JOIN prescription_items pi ON pi.prescription_id = p.id
     WHERE p.doctor_id = $1
     GROUP BY p.id, pat.id, pat.full_name, pat.profile_photo_url
     ORDER BY p.issued_at DESC`,
    [doctorId]
  );
  return result.rows;
};

// ---------------------------------------------------------------------------
// GET doctor's chat conversations — consultations involving this doctor
// ---------------------------------------------------------------------------
const getDoctorConversations = async (doctorId) => {
  const result = await pool.query(
    `SELECT
       c.id AS consultation_id,
       c.started_at,
       c.ended_at,
       a.mode,
       pat.id AS patient_id,
       pat.full_name AS patient_name,
       pat.profile_photo_url AS patient_photo_url,
       -- latest message
       (
         SELECT m.message FROM chat_messages m
         WHERE m.consultation_id = c.id
         ORDER BY m.sent_at DESC LIMIT 1
       ) AS last_message,
       (
         SELECT m.sent_at FROM chat_messages m
         WHERE m.consultation_id = c.id
         ORDER BY m.sent_at DESC LIMIT 1
       ) AS last_message_at,
       (
         SELECT COUNT(*)::int FROM chat_messages m
         WHERE m.consultation_id = c.id
           AND m.sender_id != (SELECT user_id FROM doctors WHERE id = $1)
       ) AS unread_count
     FROM consultations c
     JOIN appointments a ON a.id = c.appointment_id
     JOIN patients pat ON pat.id = a.patient_id
     WHERE a.doctor_id = $1
     ORDER BY last_message_at DESC NULLS LAST`,
    [doctorId]
  );
  return result.rows;
};

module.exports = {
  listDoctors,
  getDoctorById,
  getDoctorByUserId,
  updateDoctor,
  deactivateDoctor,
  getDoctorPatients,
  getDoctorPatientById,
  getDoctorPrescriptions,
  getDoctorConversations,
};

