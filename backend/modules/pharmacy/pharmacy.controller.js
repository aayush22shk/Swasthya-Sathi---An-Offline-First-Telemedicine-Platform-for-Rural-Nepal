const pharmacyService = require('./pharmacy.service');
const pool = require('../../db');
const { sendSuccess, sendError } = require('../../utils/response');

const getPharmacies = async (req, res) => {
  try {
    const data = await pharmacyService.listPharmacies(req.query);
    return sendSuccess(res, 200, 'Pharmacies retrieved.', data);
  } catch (err) {
    return sendError(res, 500, err.message);
  }
};

const addPharmacy = async (req, res) => {
  try {
    const data = await pharmacyService.createPharmacy(req.body);
    return sendSuccess(res, 201, 'Pharmacy registered.', data);
  } catch (err) {
    return sendError(res, err.code === '23505' ? 409 : 500, err.message);
  }
};

const createOrder = async (req, res) => {
  try {
    let { prescription_id, pharmacy_id, patient_id, delivery_address, total_amount } = req.body;

    if (req.user.role === 'patient' && !patient_id) {
      const patRes = await pool.query('SELECT id FROM patients WHERE user_id = $1', [req.user.id]);
      patient_id = patRes.rows[0]?.id;
    }

    const data = await pharmacyService.placeOrder({
      prescription_id,
      pharmacy_id,
      patient_id,
      delivery_address,
      total_amount,
    });
    return sendSuccess(res, 201, 'Order placed successfully.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const getOrder = async (req, res) => {
  try {
    const data = await pharmacyService.getOrderById(req.params.id);
    return sendSuccess(res, 200, 'Order retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const updateStatus = async (req, res) => {
  try {
    const data = await pharmacyService.updateOrderStatus(req.params.id, req.body.status);
    return sendSuccess(res, 200, 'Order status updated.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = {
  getPharmacies,
  addPharmacy,
  createOrder,
  getOrder,
  updateStatus,
};
