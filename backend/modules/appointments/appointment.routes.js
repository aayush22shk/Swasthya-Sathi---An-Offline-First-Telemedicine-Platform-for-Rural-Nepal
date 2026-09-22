const express = require('express');
const { body, param, query } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate } = require('../../middlewares/auth.middleware');
const {
  bookAppointment,
  listAppointments,
  getAppointment,
  updateStatus,
  reschedule,
} = require('./appointment.controller');

const router = express.Router();
router.use(authenticate);

const uuidParam = param('id').isUUID().withMessage('Appointment ID must be a valid UUID.');

router.post(
  '/',
  [
    body('doctor_id').isUUID().withMessage('Valid doctor_id UUID is required.'),
    body('scheduled_at').isISO8601().withMessage('Valid scheduled_at ISO timestamp required.'),
    body('mode').optional().isIn(['video', 'audio', 'chat', 'in_person']),
    body('fee').optional().isFloat({ min: 0 }),
    body('reason_for_visit').optional().isString(),
    validate,
  ],
  bookAppointment
);

router.get(
  '/',
  [
    query('status').optional().isIn(['pending', 'confirmed', 'completed', 'cancelled', 'no_show']),
    query('limit').optional().isInt({ min: 1, max: 100 }),
    query('offset').optional().isInt({ min: 0 }),
    validate,
  ],
  listAppointments
);

router.get('/:id', [uuidParam, validate], getAppointment);

router.patch(
  '/:id/status',
  [
    uuidParam,
    body('status')
      .isIn(['pending', 'confirmed', 'completed', 'cancelled', 'no_show'])
      .withMessage('Invalid appointment status.'),
    body('note').optional().isString(),
    validate,
  ],
  updateStatus
);

router.put(
  '/:id/reschedule',
  [
    uuidParam,
    body('scheduled_at').optional().isISO8601(),
    body('mode').optional().isIn(['video', 'audio', 'chat', 'in_person']),
    body('reason').optional().isString(),
    validate,
  ],
  reschedule
);

module.exports = router;
