const express = require('express');
const { body, param, query } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate } = require('../../middlewares/auth.middleware');
const {
  startSession,
  getConsultation,
  endSession,
  listMessages,
  sendMessage,
} = require('./consultation.controller');

const router = express.Router();
router.use(authenticate);

const uuidParam = param('id').isUUID().withMessage('Consultation ID must be a valid UUID.');

router.post(
  '/',
  [
    body('appointment_id').isUUID().withMessage('Valid appointment_id UUID required.'),
    body('video_room_id').optional().isString(),
    validate,
  ],
  startSession
);

router.get('/:id', [uuidParam, validate], getConsultation);

router.put(
  '/:id',
  [
    uuidParam,
    body('doctor_notes').optional().isString(),
    body('diagnosis').optional().isString(),
    validate,
  ],
  endSession
);

router.get(
  '/:id/messages',
  [
    uuidParam,
    query('limit').optional().isInt({ min: 1, max: 200 }),
    query('offset').optional().isInt({ min: 0 }),
    validate,
  ],
  listMessages
);

router.post(
  '/:id/messages',
  [
    uuidParam,
    body('message').optional().isString(),
    body('attachment_url').optional().isString(),
    validate,
  ],
  sendMessage
);

module.exports = router;
