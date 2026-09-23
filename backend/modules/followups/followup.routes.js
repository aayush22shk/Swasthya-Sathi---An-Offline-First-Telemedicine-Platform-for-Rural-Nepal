const express = require('express');
const { body, param, query } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate, authorize } = require('../../middlewares/auth.middleware');
const {
  createFollowUp,
  getDoctorFollowUps,
  getPatientFollowUps,
  updateStatus,
} = require('./followup.controller');

const router = express.Router();
router.use(authenticate);

const uuidParam = (name) => param(name).isUUID().withMessage(`${name} must be a valid UUID.`);

// Doctor: create follow-up
router.post(
  '/',
  authorize('doctor', 'admin'),
  [
    body('patient_id').isUUID().withMessage('Valid patient_id UUID required.'),
    body('follow_up_date').matches(/^\d{4}-\d{2}-\d{2}$/).withMessage('Valid follow_up_date (YYYY-MM-DD) required.'),
    body('consultation_id').optional().isUUID(),
    body('appointment_id').optional().isUUID(),
    body('notes').optional().isString(),
    validate,
  ],
  createFollowUp
);

// Doctor: list own follow-ups
router.get(
  '/doctor/me',
  authorize('doctor', 'admin'),
  [
    query('status').optional().isIn(['upcoming', 'completed', 'missed', 'cancelled']),
    validate,
  ],
  getDoctorFollowUps
);

// Patient: list own follow-ups
router.get(
  '/patient/me',
  authorize('patient'),
  [
    query('status').optional().isIn(['upcoming', 'completed', 'missed', 'cancelled']),
    validate,
  ],
  getPatientFollowUps
);

// Update status
router.patch(
  '/:id/status',
  [
    uuidParam('id'),
    body('status').isIn(['upcoming', 'completed', 'missed', 'cancelled']).withMessage('Invalid status.'),
    body('notes').optional().isString(),
    validate,
  ],
  updateStatus
);

module.exports = router;
