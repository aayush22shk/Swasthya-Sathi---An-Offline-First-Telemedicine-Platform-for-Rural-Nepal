const express = require('express');
const { body, param } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate } = require('../../middlewares/auth.middleware');
const {
  createPayment,
  verify,
  getPayment,
  refund,
} = require('./payment.controller');

const router = express.Router();
router.use(authenticate);

const uuidParam = param('id').isUUID().withMessage('Payment ID must be a valid UUID.');

router.post(
  '/initiate',
  [
    body('amount').isFloat({ min: 1 }).withMessage('Valid payment amount required.'),
    body('gateway')
      .isIn(['esewa', 'khalti', 'ime_pay', 'connectips', 'card', 'cash'])
      .withMessage('Valid payment gateway required.'),
    body('appointment_id').optional().isUUID(),
    body('pharmacy_order_id').optional().isUUID(),
    validate,
  ],
  createPayment
);

router.post(
  '/:id/verify',
  [
    uuidParam,
    body('gateway_txn_id').optional().isString(),
    body('status').optional().isIn(['success', 'failed']),
    validate,
  ],
  verify
);

router.get('/:id', [uuidParam, validate], getPayment);

router.post(
  '/:id/refund',
  [
    uuidParam,
    body('amount').optional().isFloat({ min: 1 }),
    body('reason').optional().isString(),
    validate,
  ],
  refund
);

module.exports = router;
