const pool = require('../../db');

// ---------------------------------------------------------------------------
// GET a single patient by their patients.id (profile UUID)
// ---------------------------------------------------------------------------

/**
 * Fetch a patient profile joined with their user record.
 * @param {string} patientId  - UUID from patients.id
 */
const getPatientById = async (patientId) => {
  const result = await pool.query(
    `SELECT
       p.id, p.full_name, p.dob, p.gender, p.blood_group,
       p.municipality_id, p.ward_no, p.address_line,
       p.emergency_contact_name, p.emergency_contact_phone,
       p.profile_photo_url, p.created_at, p.updated_at,
       u.id        AS user_id,
       u.phone,
       u.email,
       u.preferred_language,
       u.status,
       u.phone_verified_at,
       u.email_verified_at
     FROM patients p
     JOIN users u ON u.id = p.user_id
     WHERE p.id = $1`,
    [patientId]
  );

  if (result.rows.length === 0) {
    const err = new Error('Patient not found.');
    err.statusCode = 404;
    throw err;
  }

  return result.rows[0];
};

// ---------------------------------------------------------------------------
// GET patient profile by user_id  (useful after decoding JWT)
// ---------------------------------------------------------------------------
const getPatientByUserId = async (userId) => {
  const result = await pool.query(
    `SELECT
       p.id, p.full_name, p.dob, p.gender, p.blood_group,
       p.municipality_id, p.ward_no, p.address_line,
       p.emergency_contact_name, p.emergency_contact_phone,
       p.profile_photo_url, p.created_at, p.updated_at,
       u.id        AS user_id,
       u.phone,
       u.email,
       u.preferred_language,
       u.status,
       u.phone_verified_at,
       u.email_verified_at
     FROM patients p
     JOIN users u ON u.id = p.user_id
     WHERE p.user_id = $1`,
    [userId]
  );

  if (result.rows.length === 0) {
    const err = new Error('Patient profile not found.');
    err.statusCode = 404;
    throw err;
  }

  return result.rows[0];
};

// ---------------------------------------------------------------------------
// UPDATE patient profile
// ---------------------------------------------------------------------------

/**
 * Partially update a patient's profile and user record.
 * Only supplied fields are updated (COALESCE pattern).
 *
 * @param {string} patientId
 * @param {{
 *   full_name?: string,
 *   dob?: string,
 *   gender?: string,
 *   blood_group?: string,
 *   municipality_id?: number,
 *   ward_no?: string,
 *   address_line?: string,
 *   emergency_contact_name?: string,
 *   emergency_contact_phone?: string,
 *   profile_photo_url?: string,
 *   phone?: string,
 *   email?: string,
 *   preferred_language?: string,
 * }} fields
 */
const updatePatient = async (patientId, fields) => {
  const {
    full_name,
    dob,
    gender,
    blood_group,
    municipality_id,
    ward_no,
    address_line,
    emergency_contact_name,
    emergency_contact_phone,
    profile_photo_url,
    phone,
    email,
    preferred_language,
  } = fields;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Get patient's user_id
    const pCheck = await client.query('SELECT user_id FROM patients WHERE id = $1', [patientId]);
    if (pCheck.rows.length === 0) {
      const err = new Error('Patient not found.');
      err.statusCode = 404;
      throw err;
    }
    const userId = pCheck.rows[0].user_id;

    // 2. Update users table if phone / email / preferred_language provided
    if (phone !== undefined || email !== undefined || preferred_language !== undefined) {
      if (phone || email) {
        const dupCheck = await client.query(
          `SELECT id FROM users WHERE (phone = $1 OR (email = $2 AND $2 IS NOT NULL)) AND id != $3`,
          [phone || null, email || null, userId]
        );
        if (dupCheck.rows.length > 0) {
          const err = new Error('Another account is already using this phone or email.');
          err.statusCode = 409;
          throw err;
        }
      }

      await client.query(
        `UPDATE users SET
           phone              = COALESCE($1, phone),
           email              = COALESCE($2, email),
           preferred_language = COALESCE($3::language_pref, preferred_language),
           updated_at         = now()
         WHERE id = $4`,
        [phone || null, email || null, preferred_language || null, userId]
      );
    }

    // 3. Update patients table
    await client.query(
      `UPDATE patients SET
         full_name                = COALESCE($1, full_name),
         dob                      = COALESCE($2, dob),
         gender                   = COALESCE($3::gender_type, gender),
         blood_group              = COALESCE($4, blood_group),
         municipality_id          = COALESCE($5, municipality_id),
         ward_no                  = COALESCE($6, ward_no),
         address_line             = COALESCE($7, address_line),
         emergency_contact_name   = COALESCE($8, emergency_contact_name),
         emergency_contact_phone  = COALESCE($9, emergency_contact_phone),
         profile_photo_url        = COALESCE($10, profile_photo_url),
         updated_at               = now()
       WHERE id = $11`,
      [
        full_name || null,
        dob || null,
        gender || null,
        blood_group || null,
        municipality_id || null,
        ward_no || null,
        address_line || null,
        emergency_contact_name || null,
        emergency_contact_phone || null,
        profile_photo_url || null,
        patientId,
      ]
    );

    await client.query('COMMIT');

    // Return the updated full profile joined with user
    return await getPatientById(patientId);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};


// ---------------------------------------------------------------------------
// DELETE / deactivate patient
// Sets users.status = 'deactivated' (soft delete — data is preserved)
// ---------------------------------------------------------------------------
const deactivatePatient = async (patientId) => {
  // First get the user_id from patients
  const p = await pool.query('SELECT user_id FROM patients WHERE id = $1', [patientId]);
  if (p.rows.length === 0) {
    const err = new Error('Patient not found.');
    err.statusCode = 404;
    throw err;
  }

  await pool.query(
    `UPDATE users SET status = 'deactivated', updated_at = now() WHERE id = $1`,
    [p.rows[0].user_id]
  );

  return { message: 'Patient account deactivated.' };
};

module.exports = { getPatientById, getPatientByUserId, updatePatient, deactivatePatient };
