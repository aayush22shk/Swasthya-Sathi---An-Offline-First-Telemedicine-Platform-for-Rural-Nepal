const express = require('express');
const { body, param } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate } = require('../../middlewares/auth.middleware');
const {
  listMedicalRecords,
  createMedicalRecord,
  removeMedicalRecord,
  listVitals,
  addVitals,
  listLabReports,
  createLabReport,
  removeLabReport,
} = require('./records.controller');

const router = express.Router();
router.use(authenticate);

const patientIdParam = param('patientId').isUUID().withMessage('patientId must be a valid UUID.');
const idParam = param('id').isUUID().withMessage('ID must be a valid UUID.');

// Medical Records
router.get('/patients/:patientId/medical-records', [patientIdParam, validate], listMedicalRecords);
router.post(
  '/patients/:patientId/medical-records',
  [
    patientIdParam,
    body('record_type').trim().notEmpty().withMessage('record_type is required.'),
    body('description').trim().notEmpty().withMessage('description is required.'),
    validate,
  ],
  createMedicalRecord
);
router.delete('/patients/:patientId/medical-records/:id', [patientIdParam, idParam, validate], removeMedicalRecord);

// Vitals
router.get('/patients/:patientId/vitals', [patientIdParam, validate], listVitals);
router.post(
  '/patients/:patientId/vitals',
  [
    patientIdParam,
    body('systolic_bp').optional().isInt({ min: 40, max: 300 }),
    body('diastolic_bp').optional().isInt({ min: 20, max: 200 }),
    body('blood_sugar').optional().isFloat({ min: 10, max: 1000 }),
    body('weight_kg').optional().isFloat({ min: 1, max: 500 }),
    validate,
  ],
  addVitals
);

// Lab Reports
router.get('/patients/:patientId/lab-reports', [patientIdParam, validate], listLabReports);
router.post(
  '/patients/:patientId/lab-reports',
  [
    patientIdParam,
    body('file_url').isURL().withMessage('Valid file_url URL required.'),
    body('report_type').optional().isString(),
    validate,
  ],
  createLabReport
);
router.delete('/patients/:patientId/lab-reports/:id', [patientIdParam, idParam, validate], removeLabReport);

module.exports = router;
