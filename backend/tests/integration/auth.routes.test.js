/**
 * tests/integration/auth.routes.test.js
 *
 * Integration Tests — Auth API Endpoints
 * Tests the full HTTP request → Express → Service → DB round-trip
 * using Supertest. The database is MOCKED so no PostgreSQL server is needed.
 *
 * Endpoints covered:
 *   POST /api/v1/auth/register/patient
 *   POST /api/v1/auth/register/doctor
 *   POST /api/v1/auth/login
 *
 * Run: npm test -- --testPathPattern=auth.routes
 */

'use strict';

// ── Mock the DB pool BEFORE requiring server ──────────────────────────────────
jest.mock('../../db', () => ({
  query: jest.fn(),
  connect: jest.fn(),
}));

const request = require('supertest');
const bcrypt  = require('bcryptjs');
const pool    = require('../../db');

// Import the Express app without starting the server
// We re-create a minimal app to avoid port conflicts:
const express = require('express');
const authRoutes = require('../../modules/auth/auth.routes');
const { sendError } = require('../../utils/response');

const app = express();
app.use(express.json());
app.use('/api/v1/auth', authRoutes);
// Global error handler
app.use((err, req, res, next) => {
  sendError(res, err.statusCode || 500, err.message || 'Internal Server Error');
});

// ── Fixtures ──────────────────────────────────────────────────────────────────

const validPatient = {
  phone: '9841234567',
  email: 'ram@example.np',
  password: 'SecurePass123',
  full_name: 'Ram Prasad Sharma',
  gender: 'male',
  dob: '1990-05-15',
  blood_group: 'B+',
};

const validDoctor = {
  phone: '9851234567',
  email: 'dr.sita@hospital.np',
  password: 'DoctorPass456',
  full_name: 'Dr. Sita Devi Thapa',
  nmc_registration_number: 'NMC-2015-12345',
  consultation_fee: 1500,
  experience_years: 8,
};

// ── Helper: mock a successful patient registration DB sequence ────────────────

const mockSuccessfulPatientRegistration = () => {
  const client = {
    query: jest.fn(),
    release: jest.fn(),
  };
  let q = 0;
  client.query.mockImplementation(async (sql) => {
    if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') return { rows: [] };
    q++;
    if (q === 1) return { rows: [] }; // uniqueness: no existing user
    if (q === 2) return {             // INSERT INTO users
      rows: [{
        id: 'uuid-patient-001', phone: '9841234567',
        email: 'ram@example.np', role: 'patient',
        status: 'active', preferred_language: 'en', created_at: new Date(),
      }]
    };
    return {                           // INSERT INTO patients
      rows: [{
        id: 'uuid-profile-001', full_name: 'Ram Prasad Sharma',
        gender: 'male', dob: '1990-05-15', blood_group: 'B+', created_at: new Date(),
      }]
    };
  });
  pool.connect.mockResolvedValue(client);
};

// ══════════════════════════════════════════════════════════════════════════════
// POST /api/v1/auth/register/patient
// ══════════════════════════════════════════════════════════════════════════════

describe('POST /api/v1/auth/register/patient', () => {
  beforeEach(() => jest.clearAllMocks());

  // ── Happy Path ───────────────────────────────────────────────────────────────

  test('201 — successfully registers a new patient', async () => {
    mockSuccessfulPatientRegistration();

    const res = await request(app)
      .post('/api/v1/auth/register/patient')
      .send(validPatient);

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
    expect(res.body.data.token.split('.')).toHaveLength(3); // JWT format
    expect(res.body.data.user.role).toBe('patient');
    expect(res.body.data.user.phone).toBe('9841234567');
    expect(res.body.data.profile.full_name).toBe('Ram Prasad Sharma');
  });

  // ── Validation Errors ────────────────────────────────────────────────────────

  test('422 — rejects when phone is missing', async () => {
    const { phone, ...noPhone } = validPatient;

    const res = await request(app)
      .post('/api/v1/auth/register/patient')
      .send(noPhone);

    expect(res.status).toBe(422);
    expect(res.body.success).toBe(false);
    expect(res.body.errors).toBeDefined();
    expect(res.body.errors.some(e => e.path === 'phone')).toBe(true);
  });

  test('422 — rejects when phone format is invalid', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register/patient')
      .send({ ...validPatient, phone: 'not-a-phone' });

    expect(res.status).toBe(422);
    expect(res.body.errors.some(e => e.path === 'phone')).toBe(true);
  });

  test('422 — rejects when password is too short (< 8 chars)', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register/patient')
      .send({ ...validPatient, password: 'short' });

    expect(res.status).toBe(422);
    expect(res.body.errors.some(e => e.path === 'password')).toBe(true);
  });

  test('422 — rejects when full_name is missing', async () => {
    const { full_name, ...noName } = validPatient;

    const res = await request(app)
      .post('/api/v1/auth/register/patient')
      .send(noName);

    expect(res.status).toBe(422);
    expect(res.body.errors.some(e => e.path === 'full_name')).toBe(true);
  });

  test('422 — rejects invalid email format', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register/patient')
      .send({ ...validPatient, email: 'not-an-email' });

    expect(res.status).toBe(422);
    expect(res.body.errors.some(e => e.path === 'email')).toBe(true);
  });

  test('422 — rejects invalid blood_group', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register/patient')
      .send({ ...validPatient, blood_group: 'X+' });

    expect(res.status).toBe(422);
    expect(res.body.errors.some(e => e.path === 'blood_group')).toBe(true);
  });

  test('422 — rejects invalid gender value', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register/patient')
      .send({ ...validPatient, gender: 'alien' });

    expect(res.status).toBe(422);
    expect(res.body.errors.some(e => e.path === 'gender')).toBe(true);
  });

  test('422 — rejects invalid dob format', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register/patient')
      .send({ ...validPatient, dob: '15-05-1990' }); // wrong format

    expect(res.status).toBe(422);
    expect(res.body.errors.some(e => e.path === 'dob')).toBe(true);
  });

  // ── Conflict ─────────────────────────────────────────────────────────────────

  test('409 — rejects when phone number already registered', async () => {
    const client = {
      query: jest.fn().mockImplementation(async (sql) => {
        if (sql === 'BEGIN' || sql === 'ROLLBACK') return { rows: [] };
        return { rows: [{ id: 'existing-user' }] }; // existing user found
      }),
      release: jest.fn(),
    };
    pool.connect.mockResolvedValue(client);

    const res = await request(app)
      .post('/api/v1/auth/register/patient')
      .send(validPatient);

    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('already exists');
  });

  // ── Optional field — email omitted ───────────────────────────────────────────

  test('201 — registers successfully without optional email', async () => {
    mockSuccessfulPatientRegistration();
    const { email, ...noEmail } = validPatient;

    const res = await request(app)
      .post('/api/v1/auth/register/patient')
      .send(noEmail);

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
  });
});

// ══════════════════════════════════════════════════════════════════════════════
// POST /api/v1/auth/register/doctor
// ══════════════════════════════════════════════════════════════════════════════

describe('POST /api/v1/auth/register/doctor', () => {
  beforeEach(() => jest.clearAllMocks());

  test('201 — successfully registers a new doctor', async () => {
    const client = { query: jest.fn(), release: jest.fn() };
    let q = 0;
    client.query.mockImplementation(async (sql) => {
      if (['BEGIN','COMMIT','ROLLBACK'].includes(sql)) return { rows: [] };
      q++;
      if (q <= 2) return { rows: [] }; // Both uniqueness checks pass
      if (q === 3) return { rows: [{
        id: 'uuid-user-doc', phone: '9851234567', email: 'dr.sita@hospital.np',
        role: 'doctor', status: 'active', preferred_language: 'en', created_at: new Date(),
      }]};
      return { rows: [{
        id: 'uuid-doc-profile', full_name: 'Dr. Sita Devi Thapa',
        nmc_registration_number: 'NMC-2015-12345', nmc_status: 'pending',
        consultation_fee: 1500, experience_years: 8, is_available: true, created_at: new Date(),
      }]};
    });
    pool.connect.mockResolvedValue(client);

    const res = await request(app)
      .post('/api/v1/auth/register/doctor')
      .send(validDoctor);

    expect(res.status).toBe(201);
    expect(res.body.data.user.role).toBe('doctor');
    expect(res.body.data.profile.nmc_status).toBe('pending'); // always pending on registration
  });

  test('422 — rejects when nmc_registration_number is missing', async () => {
    const { nmc_registration_number, ...noNmc } = validDoctor;

    const res = await request(app)
      .post('/api/v1/auth/register/doctor')
      .send(noNmc);

    expect(res.status).toBe(422);
    expect(res.body.errors.some(e => e.path === 'nmc_registration_number')).toBe(true);
  });

  test('422 — rejects negative consultation_fee', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register/doctor')
      .send({ ...validDoctor, consultation_fee: -500 });

    expect(res.status).toBe(422);
  });
});

// ══════════════════════════════════════════════════════════════════════════════
// POST /api/v1/auth/login
// ══════════════════════════════════════════════════════════════════════════════

describe('POST /api/v1/auth/login', () => {
  beforeEach(() => jest.clearAllMocks());

  test('200 — successful login returns token and user object', async () => {
    const hash = await bcrypt.hash('SecurePass123', 1);

    pool.query
      .mockResolvedValueOnce({
        rows: [{ id: 'uuid-p-001', phone: '9841234567', email: 'ram@example.np',
          password_hash: hash, role: 'patient', status: 'active', preferred_language: 'ne' }]
      })
      .mockResolvedValueOnce({
        rows: [{ id: 'prof-001', full_name: 'Ram Prasad Sharma', gender: 'male',
          dob: '1990-05-15', blood_group: 'B+', profile_photo_url: null }]
      });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: '9841234567', password: 'SecurePass123' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
    expect(res.body.data.user.id).toBe('uuid-p-001');
    expect(res.body.data.user.role).toBe('patient');
    expect(res.body.data.profile.full_name).toBe('Ram Prasad Sharma');
  });

  test('401 — wrong password returns 401 with generic error message', async () => {
    const hash = await bcrypt.hash('CorrectPassword', 1);

    pool.query.mockResolvedValueOnce({
      rows: [{ id: 'uuid-p-001', phone: '9841234567', email: null,
        password_hash: hash, role: 'patient', status: 'active', preferred_language: 'en' }]
    });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: '9841234567', password: 'WrongPassword' });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    // Must NOT reveal whether the account exists (prevents user enumeration)
    expect(res.body.message).toContain('Invalid credentials');
  });

  test('401 — non-existent user returns same generic 401 (no user enumeration)', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'nobody@example.com', password: 'anything' });

    expect(res.status).toBe(401);
    expect(res.body.message).toContain('Invalid credentials');
  });

  test('403 — suspended account cannot log in', async () => {
    const hash = await bcrypt.hash('Pass123456', 1);

    pool.query.mockResolvedValueOnce({
      rows: [{ id: 'uuid-p-999', phone: '9800000000', email: null,
        password_hash: hash, role: 'patient', status: 'suspended', preferred_language: 'en' }]
    });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: '9800000000', password: 'Pass123456' });

    expect(res.status).toBe(403);
    expect(res.body.message).toContain('suspended');
  });

  test('422 — missing identifier field triggers validation error', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ password: 'SomePassword' }); // no identifier

    expect(res.status).toBe(422);
    expect(res.body.errors.some(e => e.path === 'identifier')).toBe(true);
  });

  test('422 — missing password field triggers validation error', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: '9841234567' }); // no password

    expect(res.status).toBe(422);
    expect(res.body.errors.some(e => e.path === 'password')).toBe(true);
  });

  test('422 — completely empty body triggers validation errors', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({});

    expect(res.status).toBe(422);
    expect(res.body.errors.length).toBeGreaterThanOrEqual(2);
  });

  test('login works with email as identifier', async () => {
    const hash = await bcrypt.hash('SecurePass123', 1);

    pool.query
      .mockResolvedValueOnce({
        rows: [{ id: 'uuid-p-001', phone: '9841234567', email: 'ram@example.np',
          password_hash: hash, role: 'patient', status: 'active', preferred_language: 'ne' }]
      })
      .mockResolvedValueOnce({ rows: [{ id: 'prof-001', full_name: 'Ram Prasad Sharma' }] });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'ram@example.np', password: 'SecurePass123' });

    expect(res.status).toBe(200);
    expect(res.body.data.user.id).toBe('uuid-p-001');
  });
});
