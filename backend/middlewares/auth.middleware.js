const jwt = require('jsonwebtoken');
const { sendError } = require('../utils/response');

/**
 * Verifies the JWT Bearer token attached to a request.
 * On success, attaches `req.user = { id, role, phone }` for downstream use.
 */
const authenticate = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return sendError(res, 401, 'Access denied. No token provided.');
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { id, role, phone, iat, exp }
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return sendError(res, 401, 'Session expired. Please log in again.');
    }
    return sendError(res, 401, 'Invalid token.');
  }
};

/**
 * Role guard – use AFTER authenticate.
 * @param {...string} roles - allowed role strings, e.g. 'patient', 'doctor', 'admin'
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return sendError(res, 403, 'You do not have permission to access this resource.');
    }
    next();
  };
};

module.exports = { authenticate, authorize };
