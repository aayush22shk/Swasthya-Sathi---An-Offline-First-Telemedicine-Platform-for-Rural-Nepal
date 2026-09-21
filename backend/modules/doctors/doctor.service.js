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

module.exports = {
  listDoctors,
  getDoctorById,
  getDoctorByUserId,
  updateDoctor,
  deactivateDoctor,
};
