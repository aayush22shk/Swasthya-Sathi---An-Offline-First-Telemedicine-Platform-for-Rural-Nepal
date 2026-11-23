const express = require('express');
const { param, body } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate } = require('../../middlewares/auth.middleware');
const ctrl = require('./conversation.controller');

const router = express.Router();
router.use(authenticate);

const uuidParam = (name) => param(name).isUUID().withMessage(`${name} must be a valid UUID.`);

// List conversations for authenticated user
router.get('/', ctrl.listConversations);

// Get or create conversation
router.post(
  '/',
  [
    body('patient_id').optional().isUUID().withMessage('patient_id must be a valid UUID.'),
    body('doctor_id').optional().isUUID().withMessage('doctor_id must be a valid UUID.'),
    validate,
  ],
  ctrl.getOrCreate
);

// Get messages for a conversation
router.get(
  '/:conversationId/messages',
  [uuidParam('conversationId'), validate],
  ctrl.getMessages
);

// Send a text message
router.post(
  '/:conversationId/messages',
  [
    uuidParam('conversationId'),
    body('content').trim().notEmpty().withMessage('Message content is required.'),
    validate,
  ],
  ctrl.sendMessage
);

module.exports = router;
