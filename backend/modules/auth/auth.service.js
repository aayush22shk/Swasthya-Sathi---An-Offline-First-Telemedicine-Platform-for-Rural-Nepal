const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../../db');

const SALT_ROUNDS = 12;

/**
 * Generate a signed JWT for a user.
 * @param {{ id: string, role: string, phone: string }} payload
 */
const signToken = (payload) => {
  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '24h',
  });
};

// ---------------------------------------------------------------------------
// PATIENT REGISTRATION
// ---------------------------------------------------------------------------

/**
 * Register a new patient.
 * Creates a row in `users` (role=patient) then a row in `patients`.
 *
 * @param {{
 *   phone: string,
 *   email?: string,
 *   password: string,
 *   full_name: string,
 *   gender?: string,
 *   dob?: string,
 *   blood_group?: string,
 *   preferred_language?: string,
 * }} data
 */
const registerPatient = async (data) => {
  const {
    phone,
    email,
    password,
    full_name,
    gender,
    dob,
    blood_group,
    preferred_language = 'en',
  } = data;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Uniqueness check
    const existing = await client.query(
      'SELECT id FROM users WHERE phone = $1 OR (email = $2 AND $2 IS NOT NULL)',
      [phone, email || null]
    );
    if (existing.rows.length > 0) {
      const err = new Error('An account with this phone or email already exists.');
      err.statusCode = 409;
      throw err;
    }

    // 2. Hash password
    const password_hash = await bcrypt.hash(password, SALT_ROUNDS);

    // 3. Insert into users
    const userResult = await client.query(
      `INSERT INTO users (phone, email, password_hash, role, preferred_language)
       VALUES ($1, $2, $3, 'patient', $4)
       RETURNING id, phone, email, role, preferred_language, status, created_at`,
      [phone, email || null, password_hash, preferred_language]
    );
    const user = userResult.rows[0];

    // 4. Insert into patients
    const patientResult = await client.query(
      `INSERT INTO patients (user_id, full_name, gender, dob, blood_group)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, full_name, gender, dob, blood_group, created_at`,
      [user.id, full_name, gender || null, dob || null, blood_group || null]
    );
    const patient = patientResult.rows[0];

    await client.query('COMMIT');

    // 5. Sign JWT
    const token = signToken({ id: user.id, role: user.role, phone: user.phone });

    return {
      token,
      user: {
        id: user.id,
        phone: user.phone,
        email: user.email,
        role: user.role,
        status: user.status,
        preferred_language: user.preferred_language,
      },
      profile: patient,
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

// ---------------------------------------------------------------------------
// DOCTOR REGISTRATION
// ---------------------------------------------------------------------------

/**
 * Register a new doctor.
 * Creates a row in `users` (role=doctor) then a row in `doctors`.
 *
 * @param {{
 *   phone: string,
 *   email?: string,
 *   password: string,
 *   full_name: string,
 *   nmc_registration_number: string,
 *   consultation_fee?: number,
 *   experience_years?: number,
 *   bio?: string,
 *   preferred_language?: string,
 * }} data
 */
const registerDoctor = async (data) => {
  const {
    phone,
    email,
    password,
    full_name,
    nmc_registration_number,
    consultation_fee = 0,
    experience_years = 0,
    bio,
    preferred_language = 'en',
  } = data;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Uniqueness checks
    const existingUser = await client.query(
      'SELECT id FROM users WHERE phone = $1 OR (email = $2 AND $2 IS NOT NULL)',
      [phone, email || null]
    );
    if (existingUser.rows.length > 0) {
      const err = new Error('An account with this phone or email already exists.');
      err.statusCode = 409;
      throw err;
    }

    const existingNmc = await client.query(
      'SELECT id FROM doctors WHERE nmc_registration_number = $1',
      [nmc_registration_number]
    );
    if (existingNmc.rows.length > 0) {
      const err = new Error('A doctor with this NMC registration number already exists.');
      err.statusCode = 409;
      throw err;
    }

    // 2. Hash password
    const password_hash = await bcrypt.hash(password, SALT_ROUNDS);

    // 3. Insert into users
    const userResult = await client.query(
      `INSERT INTO users (phone, email, password_hash, role, preferred_language)
       VALUES ($1, $2, $3, 'doctor', $4)
       RETURNING id, phone, email, role, preferred_language, status, created_at`,
      [phone, email || null, password_hash, preferred_language]
    );
    const user = userResult.rows[0];

    // 4. Insert into doctors
    const doctorResult = await client.query(
      `INSERT INTO doctors
         (user_id, full_name, nmc_registration_number, consultation_fee, experience_years, bio)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, full_name, nmc_registration_number, nmc_status,
                 consultation_fee, experience_years, bio, is_available, created_at`,
      [user.id, full_name, nmc_registration_number,
       consultation_fee, experience_years, bio || null]
    );
    const doctor = doctorResult.rows[0];

    await client.query('COMMIT');

    // 5. Sign JWT
    const token = signToken({ id: user.id, role: user.role, phone: user.phone });

    return {
      token,
      user: {
        id: user.id,
        phone: user.phone,
        email: user.email,
        role: user.role,
        status: user.status,
        preferred_language: user.preferred_language,
      },
      profile: doctor,
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

// ---------------------------------------------------------------------------
// LOGIN  (patient or doctor — same endpoint)
// ---------------------------------------------------------------------------

/**
 * Authenticate a user by phone (or email) + password.
 * Loads the role-specific profile automatically.
 *
 * @param {{ identifier: string, password: string }} data
 */
const login = async ({ identifier, password }) => {
  // 1. Find user by phone or email
  const userResult = await pool.query(
    `SELECT id, phone, email, password_hash, role, status, preferred_language
     FROM users
     WHERE phone = $1 OR email = $1
     LIMIT 1`,
    [identifier]
  );

  if (userResult.rows.length === 0) {
    const err = new Error('Invalid credentials. Please check your phone/email and password.');
    err.statusCode = 401;
    throw err;
  }

  const user = userResult.rows[0];

  // 2. Check account status
  if (user.status !== 'active') {
    const err = new Error(`Your account is ${user.status}. Please contact support.`);
    err.statusCode = 403;
    throw err;
  }

  // 3. Verify password
  const isMatch = await bcrypt.compare(password, user.password_hash);
  if (!isMatch) {
    const err = new Error('Invalid credentials. Please check your phone/email and password.');
    err.statusCode = 401;
    throw err;
  }

  // 4. Load role-specific profile
  let profile = null;
  if (user.role === 'patient') {
    const p = await pool.query(
      `SELECT id, full_name, gender, dob, blood_group, profile_photo_url
       FROM patients WHERE user_id = $1`,
      [user.id]
    );
    profile = p.rows[0] || null;
  } else if (user.role === 'doctor') {
    const d = await pool.query(
      `SELECT id, full_name, nmc_registration_number, nmc_status,
              consultation_fee, experience_years, bio, is_available,
              average_rating, profile_photo_url
       FROM doctors WHERE user_id = $1`,
      [user.id]
    );
    profile = d.rows[0] || null;
  }

  // 5. Sign JWT
  const token = signToken({ id: user.id, role: user.role, phone: user.phone });

  return {
    token,
    user: {
      id: user.id,
      phone: user.phone,
      email: user.email,
      role: user.role,
      status: user.status,
      preferred_language: user.preferred_language,
    },
    profile,
  };
};

module.exports = { registerPatient, registerDoctor, login };
