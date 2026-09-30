const express = require('express');
const { body, param } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate } = require('../../middlewares/auth.middleware');
const ctrl = require('./ai.controller');

const router = express.Router();
router.use(authenticate);

const uuidParam = param('id').isUUID().withMessage('ID must be a valid UUID.');

// POST /api/v1/ai/explain → Generate AI explanation for latest or specific analysis
router.post(
  '/explain',
  [
    body('analysis_id').optional().isUUID(),
    body('language').optional().isIn(['en', 'ne']),
    body('patient_id').optional().isUUID(),
    validate,
  ],
  ctrl.explain
);

// POST /api/v1/ai/conversations → Start a new conversation
router.post(
  '/conversations',
  [
    body('title').optional().isString().isLength({ max: 200 }),
    body('patient_id').optional().isUUID(),
    validate,
  ],
  ctrl.createConversation
);

// GET /api/v1/ai/conversations → List patient's conversations
router.get('/conversations', ctrl.listConversations);

// GET /api/v1/ai/conversations/:id/messages → Get messages in a conversation
router.get(
  '/conversations/:id/messages',
  [uuidParam, validate],
  ctrl.getMessages
);

// POST /api/v1/ai/conversations/:id/messages → Send a message
router.post(
  '/conversations/:id/messages',
  [
    uuidParam,
    body('message').isString().notEmpty().isLength({ max: 2000 }).withMessage('Message is required (max 2000 chars).'),
    body('language').optional().isIn(['en', 'ne']),
    validate,
  ],
  ctrl.sendMessage
);

module.exports = router;
