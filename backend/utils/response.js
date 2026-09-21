/**
 * Standardised JSON response helpers.
 * Always use these instead of raw res.json() so the API shape is consistent.
 */

/**
 * 2xx success responses
 * @param {import('express').Response} res
 * @param {number} statusCode
 * @param {string} message
 * @param {*} data
 */
const sendSuccess = (res, statusCode = 200, message = 'Success', data = null) => {
  const body = { success: true, message };
  if (data !== null && data !== undefined) body.data = data;
  return res.status(statusCode).json(body);
};

/**
 * 4xx / 5xx error responses
 * @param {import('express').Response} res
 * @param {number} statusCode
 * @param {string} message
 * @param {*} errors - optional validation error array
 */
const sendError = (res, statusCode = 500, message = 'Internal Server Error', errors = null) => {
  const body = { success: false, message };
  if (errors !== null && errors !== undefined) body.errors = errors;
  return res.status(statusCode).json(body);
};

module.exports = { sendSuccess, sendError };
