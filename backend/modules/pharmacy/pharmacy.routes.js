const express = require('express');
const { body, param, query } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate, authorize } = require('../../middlewares/auth.middleware');
const {
  getPharmacies,
  addPharmacy,
  createOrder,
  getOrder,
  updateStatus,
} = require('./pharmacy.controller');

const router = express.Router();

const uuidParam = param('id').isUUID().withMessage('ID must be a valid UUID.');

// Public: view pharmacies
router.get(
  '/',
  [query('municipality_id').optional().isInt({ min: 1 }), validate],
  getPharmacies
);

// Admin: register new pharmacy
router.post(
  '/',
  authenticate,
  authorize('admin'),
  [
    body('name').trim().notEmpty().withMessage('Pharmacy name is required.'),
    body('license_no').trim().notEmpty().withMessage('License number is required.'),
    body('municipality_id').optional().isInt({ min: 1 }),
    body('address_line').optional().isString(),
    body('contact_phone').optional().isString(),
    validate,
  ],
  addPharmacy
);

// Authenticated users: pharmacy orders
router.post(
  '/orders',
  authenticate,
  [
    body('prescription_id').isUUID().withMessage('Valid prescription_id UUID required.'),
    body('pharmacy_id').isUUID().withMessage('Valid pharmacy_id UUID required.'),
    body('total_amount').optional().isFloat({ min: 0 }),
    body('delivery_address').optional().isString(),
    validate,
  ],
  createOrder
);

router.get('/orders/:id', authenticate, [uuidParam, validate], getOrder);

router.patch(
  '/orders/:id/status',
  authenticate,
  [
    uuidParam,
    body('status')
      .isIn(['placed', 'processing', 'out_for_delivery', 'delivered', 'cancelled'])
      .withMessage('Invalid pharmacy order status.'),
    validate,
  ],
  updateStatus
);

module.exports = router;
