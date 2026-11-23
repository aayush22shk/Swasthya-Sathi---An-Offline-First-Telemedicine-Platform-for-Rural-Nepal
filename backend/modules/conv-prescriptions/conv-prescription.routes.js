const express = require('express');
const { body, param } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate, authorize } = require('../../middlewares/auth.middleware');
const ctrl = require('./conv-prescription.controller');

const router = express.Router();
router.use(authenticate);

const uuidParam = (name) => param(name).isUUID().withMessage(`${name} must be a valid UUID.`);

router.post(
  '/',
  authorize('doctor'),
  [
    body('conversation_id').isUUID().withMessage('conversation_id must be a valid UUID.'),
    body('medicines').isArray({ min: 1 }).withMessage('At least one medicine is required.'),
    body('medicines.*.medicine_name').trim().notEmpty().withMessage('medicine_name is required.'),
    body('medicines.*.dosage').optional().isString(),
    body('medicines.*.frequency').optional().isString(),
    body('medicines.*.duration').optional().isString(),
    body('medicines.*.instructions').optional().isString(),
    body('title').optional().isString(),
    body('additional_instructions').optional().isString(),
    validate,
  ],
  ctrl.create
);

router.get('/patient/:patientId', [uuidParam('patientId'), validate], ctrl.getByPatient);
router.get('/:id', [uuidParam('id'), validate], ctrl.getById);

module.exports = router;
