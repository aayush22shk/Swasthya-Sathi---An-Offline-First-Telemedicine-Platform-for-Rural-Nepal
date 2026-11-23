const express = require('express');
const { body, param } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate, authorize } = require('../../middlewares/auth.middleware');
const ctrl = require('./diagnosis.controller');

const router = express.Router();
router.use(authenticate);

const uuidParam = (name) => param(name).isUUID().withMessage(`${name} must be a valid UUID.`);

router.post(
  '/',
  authorize('doctor'),
  [
    body('conversation_id').isUUID().withMessage('conversation_id must be a valid UUID.'),
    body('title').trim().notEmpty().withMessage('Title is required.'),
    body('description').optional().isString(),
    body('findings').optional().isString(),
    body('recommended_treatment').optional().isString(),
    body('additional_notes').optional().isString(),
    validate,
  ],
  ctrl.create
);

router.get('/patient/:patientId', [uuidParam('patientId'), validate], ctrl.getByPatient);
router.get('/:id', [uuidParam('id'), validate], ctrl.getById);

module.exports = router;
