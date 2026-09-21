const authService = require('./auth.service');
const { sendSuccess, sendError } = require('../../utils/response');

// ---------------------------------------------------------------------------
// POST /api/v1/auth/register/patient
// ---------------------------------------------------------------------------
const registerPatient = async (req, res) => {
  try {
    const result = await authService.registerPatient(req.body);
    return sendSuccess(res, 201, 'Patient registered successfully.', result);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// ---------------------------------------------------------------------------
// POST /api/v1/auth/register/doctor
// ---------------------------------------------------------------------------
const registerDoctor = async (req, res) => {
  try {
    const result = await authService.registerDoctor(req.body);
    return sendSuccess(res, 201,
      'Doctor registered successfully. Your NMC credentials are pending verification.',
      result);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

// ---------------------------------------------------------------------------
// POST /api/v1/auth/login
// ---------------------------------------------------------------------------
const login = async (req, res) => {
  try {
    const { identifier, password } = req.body;
    const result = await authService.login({ identifier, password });
    return sendSuccess(res, 200, 'Login successful.', result);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = { registerPatient, registerDoctor, login };
