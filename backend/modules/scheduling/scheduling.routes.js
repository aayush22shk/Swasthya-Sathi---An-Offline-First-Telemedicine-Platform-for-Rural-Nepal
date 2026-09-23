const express = require('express');
const { body, param, query } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate, authorize } = require('../../middlewares/auth.middleware');
const {
  getAvailability,
  createSlot,
  updateSlot,
  deleteSlot,
  addTimeOff,
  deleteTimeOff,
  getAvailableSlots,
} = require('./scheduling.controller');

const router = express.Router();

const uuidParam = (name) => param(name).isUUID().withMessage(`${name} must be a valid UUID.`);

// Public: view a doctor's availability
router.get(
  '/doctors/:doctorId/availability',
  [uuidParam('doctorId'), validate],
  getAvailability
);

// Public: get available time slots for a doctor on a specific date
router.get(
  '/doctors/:doctorId/slots',
  [
    uuidParam('doctorId'),
    query('date').notEmpty().matches(/^\d{4}-\d{2}-\d{2}$/).withMessage('Date must be YYYY-MM-DD.'),
    validate,
  ],
  getAvailableSlots
);

// Doctor only: manage own availability slots
router.post(
  '/availability',
  authenticate,
  authorize('doctor'),
  [
    body('day_of_week')
      .isIn(['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'])
      .withMessage('Invalid day_of_week.'),
    body('start_time').matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$/).withMessage('Invalid start_time format (HH:MM).'),
    body('end_time').matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$/).withMessage('Invalid end_time format (HH:MM).'),
    body('slot_duration_minutes').optional().isInt({ min: 5, max: 120 }),
    body('is_active').optional().isBoolean(),
    validate,
  ],
  createSlot
);

router.put(
  '/availability/:id',
  authenticate,
  authorize('doctor'),
  [uuidParam('id'), validate],
  updateSlot
);

router.delete(
  '/availability/:id',
  authenticate,
  authorize('doctor'),
  [uuidParam('id'), validate],
  deleteSlot
);

// Doctor only: manage time-off
router.post(
  '/time-off',
  authenticate,
  authorize('doctor'),
  [
    body('start_at').isISO8601().withMessage('Valid start_at ISO timestamp required.'),
    body('end_at').isISO8601().withMessage('Valid end_at ISO timestamp required.'),
    body('reason').optional().isString(),
    validate,
  ],
  addTimeOff
);

router.delete(
  '/time-off/:id',
  authenticate,
  authorize('doctor'),
  [uuidParam('id'), validate],
  deleteTimeOff
);

module.exports = router;
