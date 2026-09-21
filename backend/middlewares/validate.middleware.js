const { validationResult } = require('express-validator');
const { sendError } = require('../utils/response');

/**
 * Middleware that reads express-validator results and short-circuits the
 * request with a 422 response if any validation errors exist.
 * Place AFTER your validation chains in a route definition.
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return sendError(res, 422, 'Validation failed', errors.array());
  }
  next();
};

module.exports = { validate };
