/**
 * tests/unit/auth.service.test.js
 *
 * Unit Tests — Auth Service (backend/modules/auth/auth.service.js)
 *
 * Tests pure business logic functions in isolation.
 * The PostgreSQL pool (db.js) is MOCKED — no real database needed.
 *
 * Run: npm test -- --testPathPattern=auth.service
 */

'use strict';

// ── Mock the database pool BEFORE requiring the service ──────────────────────
// This prevents real DB connections during unit tests.
jest.mock('../../db', () => ({
  query: jest.fn(),
  connect: jest.fn(),
}));

const pool = require('../../db');
const { registerPatient, registerDoctor, login } = require('../../modules/auth/auth.service');

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Creates a mock pg client (returned by pool.connect()) */
const createMockClient = ({ existingRows = [], userRow = null, profileRow = null } = {}) => {
  const client = {
    query: jest.fn(),
    release: jest.fn(),
  };

  // Default query resolution sequence:
  //   1st call: uniqueness check (SELECT)
  //   2nd call: INSERT INTO users
  //   3rd call: INSERT INTO patients/doctors
  let callCount = 0;
  client.query.mockImplementation(async (sql) => {
    if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
      return { rows: [] };
    }
    callCount++;
    if (callCount === 1) return { rows: existingRows };       // uniqueness check
    if (callCount === 2) return { rows: [userRow] };          // INSERT users
    if (callCount === 3) return { rows: [profileRow] };       // INSERT patients/doctors
    return { rows: [] };
  });

  return client;
};

/** Minimal valid patient registration data */
const patientData = {
  phone: '9841234567',
  email: 'ram@example.com',
  password: 'SecurePass123',
  full_name: 'Ram Prasad Sharma',
  gender: 'male',
  dob: '1990-05-15',
  blood_group: 'B+',
  preferred_language: 'ne',
};

/** Minimal valid doctor registration data */
const doctorData = {
  phone: '9851234567',
  email: 'dr.sita@hospital.np',
  password: 'DoctorPass456',
  full_name: 'Dr. Sita Devi Thapa',
  nmc_registration_number: 'NMC-2015-12345',
  consultation_fee: 1500,
  experience_years: 8,
  bio: 'Cardiologist with 8 years of experience.',
  preferred_language: 'en',
};

// ── Test Suite: registerPatient ───────────────────────────────────────────────

describe('Auth Service — registerPatient()', () => {
  beforeEach(() => jest.clearAllMocks());

  test('successfully registers a new patient and returns token + profile', async () => {
    const mockClient = createMockClient({
      existingRows: [],
      userRow: {
        id: 'user-uuid-001',
        phone: '9841234567',
        email: 'ram@example.com',
        role: 'patient',
        status: 'active',
        preferred_language: 'ne',
        created_at: new Date(),
      },
      profileRow: {
        id: 'patient-uuid-001',
        full_name: 'Ram Prasad Sharma',
        gender: 'male',
        dob: '1990-05-15',
        blood_group: 'B+',
        created_at: new Date(),
      },
    });

    pool.connect.mockResolvedValue(mockClient);

    const result = await registerPatient(patientData);

    // Must return a JWT token
    expect(result.token).toBeDefined();
    expect(typeof result.token).toBe('string');
    expect(result.token.length).toBeGreaterThan(20);

    // User envelope
    expect(result.user.id).toBe('user-uuid-001');
    expect(result.user.role).toBe('patient');
    expect(result.user.phone).toBe('9841234567');

    // Profile
    expect(result.profile.full_name).toBe('Ram Prasad Sharma');

    // DB transaction must have been used
    expect(mockClient.query).toHaveBeenCalledWith('BEGIN');
    expect(mockClient.query).toHaveBeenCalledWith('COMMIT');
    expect(mockClient.release).toHaveBeenCalledTimes(1);
  });

  test('throws 409 error when phone number already exists', async () => {
    const mockClient = createMockClient({
      existingRows: [{ id: 'existing-uuid' }], // uniqueness check returns a row
    });
    pool.connect.mockResolvedValue(mockClient);

    await expect(registerPatient(patientData)).rejects.toMatchObject({
      message: expect.stringContaining('already exists'),
      statusCode: 409,
    });

    // Must ROLLBACK on error
    expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK');
    expect(mockClient.release).toHaveBeenCalledTimes(1);
  });

  test('calls ROLLBACK and releases client on unexpected DB error', async () => {
    const mockClient = {
      query: jest.fn().mockImplementation(async (sql) => {
        if (sql === 'BEGIN') return { rows: [] };
        throw new Error('PostgreSQL connection lost');
      }),
      release: jest.fn(),
    };
    pool.connect.mockResolvedValue(mockClient);

    await expect(registerPatient(patientData)).rejects.toThrow('PostgreSQL connection lost');

    expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK');
    expect(mockClient.release).toHaveBeenCalledTimes(1);
  });
});

// ── Test Suite: registerDoctor ────────────────────────────────────────────────

describe('Auth Service — registerDoctor()', () => {
  beforeEach(() => jest.clearAllMocks());

  test('successfully registers a new doctor', async () => {
    const mockClient = createMockClient({
      existingRows: [],
      userRow: {
        id: 'user-uuid-doc-001',
        phone: '9851234567',
        email: 'dr.sita@hospital.np',
        role: 'doctor',
        status: 'active',
        preferred_language: 'en',
        created_at: new Date(),
      },
      profileRow: {
        id: 'doctor-uuid-001',
        full_name: 'Dr. Sita Devi Thapa',
        nmc_registration_number: 'NMC-2015-12345',
        nmc_status: 'pending',
        consultation_fee: 1500,
        experience_years: 8,
        bio: 'Cardiologist with 8 years of experience.',
        is_available: true,
        created_at: new Date(),
      },
    });

    // Doctor registration: 2 uniqueness checks (user + NMC)
    let callCount = 0;
    mockClient.query.mockImplementation(async (sql) => {
      if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') return { rows: [] };
      callCount++;
      if (callCount <= 2) return { rows: [] }; // Both uniqueness checks pass
      if (callCount === 3) return { rows: [mockClient._userRow] }; // INSERT users
      if (callCount === 4) return { rows: [mockClient._doctorRow] }; // INSERT doctors
      return { rows: [] };
    });
    mockClient._userRow = {
      id: 'user-uuid-doc-001', phone: '9851234567',
      email: 'dr.sita@hospital.np', role: 'doctor',
      status: 'active', preferred_language: 'en', created_at: new Date(),
    };
    mockClient._doctorRow = {
      id: 'doctor-uuid-001', full_name: 'Dr. Sita Devi Thapa',
      nmc_registration_number: 'NMC-2015-12345', nmc_status: 'pending',
      consultation_fee: 1500, experience_years: 8, is_available: true, created_at: new Date(),
    };

    pool.connect.mockResolvedValue(mockClient);

    const result = await registerDoctor(doctorData);

    expect(result.token).toBeDefined();
    expect(result.user.role).toBe('doctor');
    expect(mockClient.release).toHaveBeenCalledTimes(1);
  });

  test('throws 409 if NMC number already registered', async () => {
    const mockClient = {
      query: jest.fn().mockImplementation(async (sql) => {
        if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') return { rows: [] };
        // First uniqueness check (user): passes
        // Second uniqueness check (NMC): returns existing row
        if (mockClient._queryCount === undefined) mockClient._queryCount = 0;
        mockClient._queryCount++;
        if (mockClient._queryCount === 1) return { rows: [] };
        return { rows: [{ id: 'existing-doctor' }] }; // NMC already exists
      }),
      release: jest.fn(),
    };
    pool.connect.mockResolvedValue(mockClient);

    await expect(registerDoctor(doctorData)).rejects.toMatchObject({
      statusCode: 409,
    });

    expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK');
    expect(mockClient.release).toHaveBeenCalledTimes(1);
  });
});

// ── Test Suite: login ─────────────────────────────────────────────────────────

describe('Auth Service — login()', () => {
  beforeEach(() => jest.clearAllMocks());

  test('login fails with 401 for non-existent user', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] }); // no user found

    await expect(login({ identifier: '0000000000', password: 'any' }))
      .rejects.toMatchObject({
        statusCode: 401,
        message: expect.stringContaining('Invalid credentials'),
      });
  });

  test('login fails with 403 for suspended account', async () => {
    pool.query.mockResolvedValueOnce({
      rows: [{
        id: 'uuid-suspended',
        phone: '9841234567',
        email: null,
        password_hash: 'hashed_password',
        role: 'patient',
        status: 'suspended', // ← suspended account
        preferred_language: 'en',
      }],
    });

    await expect(login({ identifier: '9841234567', password: 'any' }))
      .rejects.toMatchObject({
        statusCode: 403,
        message: expect.stringContaining('suspended'),
      });
  });

  test('login fails with 401 for wrong password', async () => {
    // bcrypt hash of "RealPassword123"
    const bcrypt = require('bcryptjs');
    const hash = await bcrypt.hash('RealPassword123', 1); // 1 round for speed in tests

    pool.query.mockResolvedValueOnce({
      rows: [{
        id: 'uuid-patient-001',
        phone: '9841234567',
        email: 'ram@example.com',
        password_hash: hash,
        role: 'patient',
        status: 'active',
        preferred_language: 'ne',
      }],
    });

    await expect(login({ identifier: '9841234567', password: 'WrongPassword' }))
      .rejects.toMatchObject({ statusCode: 401 });
  });

  test('login succeeds and returns token for correct credentials', async () => {
    const bcrypt = require('bcryptjs');
    const hash = await bcrypt.hash('SecurePass123', 1);

    // First query: find user
    pool.query
      .mockResolvedValueOnce({
        rows: [{
          id: 'uuid-patient-001',
          phone: '9841234567',
          email: 'ram@example.com',
          password_hash: hash,
          role: 'patient',
          status: 'active',
          preferred_language: 'ne',
        }],
      })
      // Second query: load patient profile
      .mockResolvedValueOnce({
        rows: [{
          id: 'patient-profile-001',
          full_name: 'Ram Prasad Sharma',
          gender: 'male',
          dob: '1990-05-15',
          blood_group: 'B+',
          profile_photo_url: null,
        }],
      });

    const result = await login({ identifier: '9841234567', password: 'SecurePass123' });

    expect(result.token).toBeDefined();
    expect(result.token.split('.')).toHaveLength(3); // Valid JWT format: header.payload.signature
    expect(result.user.id).toBe('uuid-patient-001');
    expect(result.user.role).toBe('patient');
    expect(result.user.status).toBe('active');
    expect(result.profile.full_name).toBe('Ram Prasad Sharma');
  });

  test('login succeeds for doctor and loads doctor profile', async () => {
    const bcrypt = require('bcryptjs');
    const hash = await bcrypt.hash('DoctorPass456', 1);

    pool.query
      .mockResolvedValueOnce({
        rows: [{
          id: 'uuid-doctor-001',
          phone: '9851234567',
          email: 'dr.sita@hospital.np',
          password_hash: hash,
          role: 'doctor',
          status: 'active',
          preferred_language: 'en',
        }],
      })
      .mockResolvedValueOnce({
        rows: [{
          id: 'doctor-profile-001',
          full_name: 'Dr. Sita Devi Thapa',
          nmc_registration_number: 'NMC-2015-12345',
          nmc_status: 'verified',
          consultation_fee: 1500,
          experience_years: 8,
          is_available: true,
          average_rating: '4.80',
          profile_photo_url: null,
        }],
      });

    const result = await login({ identifier: 'dr.sita@hospital.np', password: 'DoctorPass456' });

    expect(result.user.role).toBe('doctor');
    expect(result.profile.nmc_status).toBe('verified');
    expect(result.profile.is_available).toBe(true);
  });
});
