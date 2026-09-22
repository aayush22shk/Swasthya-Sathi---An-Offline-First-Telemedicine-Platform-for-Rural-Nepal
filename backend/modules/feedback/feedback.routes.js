const express = require('express');
const { body, param, query } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate } = require('../../middlewares/auth.middleware');
const {
  createReview,
  getReviews,
  getNotifications,
  markRead,
  markAllRead,
} = require('./feedback.controller');

const router = express.Router();

const uuidParam = (name) => param(name).isUUID().withMessage(`${name} must be a valid UUID.`);

// Public: view doctor's reviews
router.get(
  '/doctors/:doctorId/reviews',
  [uuidParam('doctorId'), validate],
  getReviews
);

// Authenticated: submit review
router.post(
  '/reviews',
  authenticate,
  [
    body('appointment_id').isUUID().withMessage('Valid appointment_id UUID required.'),
    body('doctor_id').isUUID().withMessage('Valid doctor_id UUID required.'),
    body('rating').isInt({ min: 1, max: 5 }).withMessage('Rating must be between 1 and 5.'),
    body('comment').optional().isString(),
    validate,
  ],
  createReview
);

// Authenticated: notifications
router.get(
  '/notifications',
  authenticate,
  [
    query('unread_only').optional().isBoolean(),
    query('limit').optional().isInt({ min: 1, max: 100 }),
    validate,
  ],
  getNotifications
);

router.patch(
  '/notifications/read-all',
  authenticate,
  markAllRead
);

router.patch(
  '/notifications/:id/read',
  authenticate,
  [uuidParam('id'), validate],
  markRead
);

module.exports = router;
