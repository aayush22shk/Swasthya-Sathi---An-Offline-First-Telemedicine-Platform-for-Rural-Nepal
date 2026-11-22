/**
 * tests/integration/middleware.test.js
 *
 * Integration Tests — Auth Middleware (authenticate + authorize)
 * Tests the JWT middleware chain on a dummy protected route without
 * needing a real database.
 *
 * Run: npm test -- --testPathPattern=middleware
 */

'use strict';

jest.mock('../../db', () => ({ query: jest.fn(), connect: jest.fn() }));

const request   = require('supertest');
const express   = require('express');
const jwt       = require('jsonwebtoken');
const { authenticate, authorize } = require('../../middlewares/auth.middleware');
const { sendSuccess, sendError }  = require('../../utils/response');

// ── Test app with a protected route ──────────────────────────────────────────

const app = express();
app.use(express.json());

// Public route
app.get('/public', (req, res) => sendSuccess(res, 200, 'Public OK'));

// Protected — JWT required
app.get('/protected', authenticate, (req, res) =>
  sendSuccess(res, 200, 'Protected OK', { user: req.user }));

// Doctor-only route
app.get('/doctor-only', authenticate, authorize('doctor'), (req, res) =>
  sendSuccess(res, 200, 'Doctor area', { user: req.user }));

// Multi-role route (patient OR admin)
app.get('/patient-or-admin', authenticate, authorize('patient', 'admin'), (req, res) =>
  sendSuccess(res, 200, 'Patient or Admin', { user: req.user }));

// Error handler
app.use((err, req, res, next) => {
  sendError(res, err.statusCode || 500, err.message);
});

// ── JWT Helpers ───────────────────────────────────────────────────────────────

const SECRET = process.env.JWT_SECRET || 'swasthyasathi_super_secret_key_change_in_production';

const signToken = (payload, options = {}) =>
  jwt.sign(payload, SECRET, { expiresIn: '1h', ...options });

const patientToken  = signToken({ id: 'uuid-p-001', role: 'patient',  phone: '9841234567' });
const doctorToken   = signToken({ id: 'uuid-d-001', role: 'doctor',   phone: '9851234567' });
const adminToken    = signToken({ id: 'uuid-a-001', role: 'admin',    phone: '9860000000' });
const expiredToken  = signToken({ id: 'uuid-x-001', role: 'patient',  phone: '9899999999' }, { expiresIn: '-1s' });

// ══════════════════════════════════════════════════════════════════════════════
// authenticate middleware
// ══════════════════════════════════════════════════════════════════════════════

describe('authenticate middleware —', () => {
  test('200 — valid Bearer token grants access', async () => {
    const res = await request(app)
      .get('/protected')
      .set('Authorization', `Bearer ${patientToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.user.id).toBe('uuid-p-001');
    expect(res.body.data.user.role).toBe('patient');
    expect(res.body.data.user.phone).toBe('9841234567');
  });

  test('401 — request with no Authorization header is rejected', async () => {
    const res = await request(app).get('/protected');

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('No token');
  });

  test('401 — request with empty Authorization header is rejected', async () => {
    const res = await request(app)
      .get('/protected')
      .set('Authorization', '');

    expect(res.status).toBe(401);
  });

  test('401 — request with "Bearer" but no token is rejected', async () => {
    const res = await request(app)
      .get('/protected')
      .set('Authorization', 'Bearer ');

    expect(res.status).toBe(401);
  });

  test('401 — request with a completely invalid token is rejected', async () => {
    const res = await request(app)
      .get('/protected')
      .set('Authorization', 'Bearer this.is.not.a.valid.jwt');

    expect(res.status).toBe(401);
    expect(res.body.message).toContain('Invalid token');
  });

  test('401 — expired token is rejected with session expired message', async () => {
    const res = await request(app)
      .get('/protected')
      .set('Authorization', `Bearer ${expiredToken}`);

    expect(res.status).toBe(401);
    expect(res.body.message).toContain('expired');
  });

  test('401 — token with wrong secret is rejected', async () => {
    const wrongSecretToken = jwt.sign(
      { id: 'fake-uuid', role: 'patient', phone: '9800000000' },
      'wrong_secret_key',
      { expiresIn: '1h' }
    );

    const res = await request(app)
      .get('/protected')
      .set('Authorization', `Bearer ${wrongSecretToken}`);

    expect(res.status).toBe(401);
    expect(res.body.message).toContain('Invalid token');
  });

  test('401 — token missing "Bearer " prefix is rejected', async () => {
    const res = await request(app)
      .get('/protected')
      .set('Authorization', patientToken); // no "Bearer " prefix

    expect(res.status).toBe(401);
  });

  test('200 — public route works without any token', async () => {
    const res = await request(app).get('/public');
    expect(res.status).toBe(200);
  });
});

// ══════════════════════════════════════════════════════════════════════════════
// authorize middleware
// ══════════════════════════════════════════════════════════════════════════════

describe('authorize middleware —', () => {
  test('200 — doctor token allowed on doctor-only route', async () => {
    const res = await request(app)
      .get('/doctor-only')
      .set('Authorization', `Bearer ${doctorToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.user.role).toBe('doctor');
  });

  test('403 — patient token rejected on doctor-only route', async () => {
    const res = await request(app)
      .get('/doctor-only')
      .set('Authorization', `Bearer ${patientToken}`);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('permission');
  });

  test('403 — admin token rejected on doctor-only route', async () => {
    const res = await request(app)
      .get('/doctor-only')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(403);
  });

  test('200 — patient token allowed on patient-or-admin route', async () => {
    const res = await request(app)
      .get('/patient-or-admin')
      .set('Authorization', `Bearer ${patientToken}`);

    expect(res.status).toBe(200);
  });

  test('200 — admin token allowed on patient-or-admin route', async () => {
    const res = await request(app)
      .get('/patient-or-admin')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
  });

  test('403 — doctor token rejected on patient-or-admin route', async () => {
    const res = await request(app)
      .get('/patient-or-admin')
      .set('Authorization', `Bearer ${doctorToken}`);

    expect(res.status).toBe(403);
  });
});
