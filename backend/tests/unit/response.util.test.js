/**
 * tests/unit/response.util.test.js
 *
 * Unit Tests — Response Utility (backend/utils/response.js)
 *
 * Tests the sendSuccess() and sendError() helpers that standardise
 * every API response shape across the entire SwasthyaSathi backend.
 *
 * Run: npm test -- --testPathPattern=response.util
 */

'use strict';

const { sendSuccess, sendError } = require('../../utils/response');

// ── Mock Express Response Object ──────────────────────────────────────────────

/**
 * Creates a minimal mock of an Express `res` object.
 * Supports the chaining pattern: res.status(200).json({ ... })
 */
const createMockRes = () => {
  const res = {};
  res.statusCode = null;
  res.body = null;

  res.status = jest.fn((code) => {
    res.statusCode = code;
    return res;           // enables chaining
  });

  res.json = jest.fn((body) => {
    res.body = body;
    return res;
  });

  return res;
};

// ── Test Suite: sendSuccess ───────────────────────────────────────────────────

describe('sendSuccess()', () => {
  test('sets HTTP 200 and correct response shape', () => {
    const res = createMockRes();
    sendSuccess(res, 200, 'Operation successful', { id: 'user-001' });

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toBe('Operation successful');
    expect(res.body.data).toEqual({ id: 'user-001' });
  });

  test('sets HTTP 201 for resource creation', () => {
    const res = createMockRes();
    sendSuccess(res, 201, 'Patient registered successfully', { token: 'jwt.token' });

    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBe('jwt.token');
  });

  test('omits "data" key when data is null', () => {
    const res = createMockRes();
    sendSuccess(res, 200, 'Logged out', null);

    expect(res.body).not.toHaveProperty('data');
    expect(res.body.success).toBe(true);
  });

  test('omits "data" key when data is undefined', () => {
    const res = createMockRes();
    sendSuccess(res, 200, 'OK'); // data not passed — defaults to null

    expect(res.body).not.toHaveProperty('data');
  });

  test('includes array data correctly', () => {
    const res = createMockRes();
    const appointments = [{ id: 'appt-001' }, { id: 'appt-002' }];
    sendSuccess(res, 200, 'Appointments fetched', appointments);

    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data).toHaveLength(2);
  });

  test('defaults to status 200 and message "Success" when not provided', () => {
    const res = createMockRes();
    sendSuccess(res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.body.message).toBe('Success');
  });
});

// ── Test Suite: sendError ─────────────────────────────────────────────────────

describe('sendError()', () => {
  test('sets HTTP 400 and correct error shape', () => {
    const res = createMockRes();
    sendError(res, 400, 'Phone number is required.');

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBe('Phone number is required.');
    expect(res.body).not.toHaveProperty('errors');
  });

  test('sets HTTP 401 for unauthorised requests', () => {
    const res = createMockRes();
    sendError(res, 401, 'Access denied. No token provided.');

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.body.success).toBe(false);
  });

  test('sets HTTP 403 for forbidden access', () => {
    const res = createMockRes();
    sendError(res, 403, 'You do not have permission to access this resource.');

    expect(res.status).toHaveBeenCalledWith(403);
    expect(res.body.message).toContain('permission');
  });

  test('sets HTTP 404 for not found', () => {
    const res = createMockRes();
    sendError(res, 404, 'Doctor not found.');

    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBe('Doctor not found.');
  });

  test('sets HTTP 409 for conflict errors', () => {
    const res = createMockRes();
    sendError(res, 409, 'An account with this phone already exists.');

    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.body.success).toBe(false);
  });

  test('sets HTTP 422 with validation errors array', () => {
    const res = createMockRes();
    const validationErrors = [
      { field: 'phone', message: 'Phone number is required.' },
      { field: 'password', message: 'Password must be at least 8 characters.' },
    ];
    sendError(res, 422, 'Validation failed', validationErrors);

    expect(res.status).toHaveBeenCalledWith(422);
    expect(res.body.success).toBe(false);
    expect(res.body.errors).toHaveLength(2);
    expect(res.body.errors[0].field).toBe('phone');
  });

  test('sets HTTP 500 for internal errors', () => {
    const res = createMockRes();
    sendError(res, 500, 'Internal Server Error');

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.body.success).toBe(false);
  });

  test('omits "errors" key when errors param is null', () => {
    const res = createMockRes();
    sendError(res, 400, 'Bad request', null);

    expect(res.body).not.toHaveProperty('errors');
  });

  test('defaults to 500 and "Internal Server Error" when args missing', () => {
    const res = createMockRes();
    sendError(res);

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.body.message).toBe('Internal Server Error');
  });
});
