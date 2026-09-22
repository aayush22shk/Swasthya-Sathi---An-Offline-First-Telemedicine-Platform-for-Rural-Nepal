const paymentService = require('./payment.service');
const pool = require('../../db');
const { sendSuccess, sendError } = require('../../utils/response');

const createPayment = async (req, res) => {
  try {
    let { appointment_id, pharmacy_order_id, patient_id, amount, gateway } = req.body;

    if (req.user.role === 'patient' && !patient_id) {
      const patRes = await pool.query('SELECT id FROM patients WHERE user_id = $1', [req.user.id]);
      patient_id = patRes.rows[0]?.id;
    }

    const data = await paymentService.initiatePayment({
      appointment_id,
      pharmacy_order_id,
      patient_id,
      amount,
      gateway,
    });
    return sendSuccess(res, 201, 'Payment record initiated.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const verify = async (req, res) => {
  try {
    const data = await paymentService.verifyPayment(req.params.id, req.body);
    return sendSuccess(res, 200, 'Payment verified.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const getPayment = async (req, res) => {
  try {
    const data = await paymentService.getPaymentById(req.params.id);
    return sendSuccess(res, 200, 'Payment details retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const refund = async (req, res) => {
  try {
    const data = await paymentService.requestRefund(req.params.id, req.body);
    return sendSuccess(res, 201, 'Refund request submitted.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = {
  createPayment,
  verify,
  getPayment,
  refund,
};
