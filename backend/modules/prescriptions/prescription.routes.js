const express = require('express');
const { body, param } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate, authorize } = require('../../middlewares/auth.middleware');
const {
  issuePrescription,
  getPrescription,
  getPatientPrescriptions,
} = require('./prescription.controller');

const router = express.Router();
router.use(authenticate);

const uuidParam = (name) => param(name).isUUID().withMessage(`${name} must be a valid UUID.`);

router.post(
  '/',
  authorize('doctor', 'admin'),
  [
    body('consultation_id').isUUID().withMessage('Valid consultation_id UUID required.'),
    body('patient_id').isUUID().withMessage('Valid patient_id UUID required.'),
    body('items').isArray({ min: 1 }).withMessage('Prescription must include at least one item.'),
    body('items.*.medicine_name').trim().notEmpty().withMessage('Medicine name is required for each item.'),
    body('items.*.dosage').optional().isString(),
    body('items.*.route').optional().isIn(['oral', 'topical', 'injection', 'other']),
    body('items.*.frequency').optional().isString(),
    body('items.*.duration_days').optional().isInt({ min: 1 }),
    body('items.*.instructions').optional().isString(),
    body('notes').optional().isString(),
    validate,
  ],
  issuePrescription
);

router.get('/:id', [uuidParam('id'), validate], getPrescription);

router.get(
  '/patient/:patientId',
  [uuidParam('patientId'), validate],
  getPatientPrescriptions
);

module.exports = router;
