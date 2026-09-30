const express = require('express');
const { body, query, param } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate } = require('../../middlewares/auth.middleware');
const ctrl = require('./health.controller');

const router = express.Router();
router.use(authenticate);

const uuidParam = param('id').isUUID().withMessage('ID must be a valid UUID.');

// ─── VITALS SUMMARY ──────────────────────────────────────────────────────────
// GET /api/v1/health/vitals
router.get('/vitals', ctrl.getVitalsSummary);

// ─── BLOOD PRESSURE ──────────────────────────────────────────────────────────
router.post(
  '/blood-pressure',
  [
    body('systolic').isInt({ min: 1 }).withMessage('systolic must be a positive integer.'),
    body('diastolic').isInt({ min: 1 }).withMessage('diastolic must be a positive integer.'),
    body('heart_rate').optional().isInt({ min: 1 }),
    body('measured_at').isISO8601().withMessage('measured_at must be a valid ISO 8601 timestamp.'),
    body('measurement_context').optional().isIn(['morning', 'evening', 'before_meal', 'after_meal', 'random', 'manual']),
    body('source').optional().isIn(['manual', 'device', 'imported', 'clinician']),
    body('notes').optional().isString(),
    validate,
  ],
  ctrl.createBPReading
);

router.get(
  '/blood-pressure',
  [
    query('limit').optional().isInt({ min: 1, max: 200 }),
    query('offset').optional().isInt({ min: 0 }),
    query('from').optional().isISO8601(),
    query('to').optional().isISO8601(),
    validate,
  ],
  ctrl.listBPReadings
);

// ─── GLUCOSE ─────────────────────────────────────────────────────────────────
router.post(
  '/glucose',
  [
    body('glucose_value').isFloat({ min: 0.1 }).withMessage('glucose_value must be a positive number.'),
    body('unit').optional().isIn(['mg/dl', 'mmol/l']),
    body('measurement_type').optional().isIn(['fasting', 'before_meal', 'after_meal', 'random', 'bedtime']),
    body('measured_at').isISO8601().withMessage('measured_at must be a valid ISO 8601 timestamp.'),
    body('source').optional().isIn(['manual', 'device', 'imported', 'clinician']),
    body('notes').optional().isString(),
    validate,
  ],
  ctrl.createGlucoseReading
);

router.get(
  '/glucose',
  [
    query('limit').optional().isInt({ min: 1, max: 200 }),
    query('offset').optional().isInt({ min: 0 }),
    query('from').optional().isISO8601(),
    query('to').optional().isISO8601(),
    validate,
  ],
  ctrl.listGlucoseReadings
);

// ─── WEIGHT ──────────────────────────────────────────────────────────────────
router.post(
  '/weight',
  [
    body('weight_kg').isFloat({ min: 0.1 }).withMessage('weight_kg must be a positive number.'),
    body('measured_at').isISO8601().withMessage('measured_at must be a valid ISO 8601 timestamp.'),
    body('source').optional().isIn(['manual', 'device', 'imported', 'clinician']),
    body('notes').optional().isString(),
    validate,
  ],
  ctrl.createWeightReading
);

router.get(
  '/weight',
  [
    query('limit').optional().isInt({ min: 1, max: 200 }),
    query('offset').optional().isInt({ min: 0 }),
    query('from').optional().isISO8601(),
    query('to').optional().isISO8601(),
    validate,
  ],
  ctrl.listWeightReadings
);

// ─── SYMPTOMS ────────────────────────────────────────────────────────────────
router.post(
  '/symptoms',
  [
    body('symptom_name').isString().notEmpty().withMessage('symptom_name is required.'),
    body('severity').optional().isInt({ min: 1, max: 10 }),
    body('started_at').optional().isISO8601(),
    body('ended_at').optional().isISO8601(),
    body('notes').optional().isString(),
    validate,
  ],
  ctrl.createSymptom
);

router.get(
  '/symptoms',
  [
    query('limit').optional().isInt({ min: 1, max: 100 }),
    query('offset').optional().isInt({ min: 0 }),
    validate,
  ],
  ctrl.listSymptoms
);

// ─── CONDITIONS ──────────────────────────────────────────────────────────────
router.post(
  '/conditions',
  [
    body('condition_name').isString().notEmpty().withMessage('condition_name is required.'),
    body('condition_type').optional().isString(),
    body('diagnosis_date').optional().isISO8601(),
    body('status').optional().isIn(['active', 'resolved', 'managed', 'suspected']),
    body('notes').optional().isString(),
    validate,
  ],
  ctrl.createCondition
);

router.get('/conditions', ctrl.listConditions);

router.patch(
  '/conditions/:id',
  [
    uuidParam,
    body('condition_name').optional().isString(),
    body('condition_type').optional().isString(),
    body('diagnosis_date').optional().isISO8601(),
    body('status').optional().isIn(['active', 'resolved', 'managed', 'suspected']),
    body('notes').optional().isString(),
    validate,
  ],
  ctrl.patchCondition
);

// ─── MEDICATIONS ─────────────────────────────────────────────────────────────
router.post(
  '/medications',
  [
    body('medicine_name').isString().notEmpty().withMessage('medicine_name is required.'),
    body('start_date').isISO8601().withMessage('start_date is required (ISO 8601 date).'),
    body('dosage').optional().isString(),
    body('route').optional().isIn(['oral', 'intravenous', 'intramuscular', 'subcutaneous', 'topical', 'inhaled', 'sublingual', 'rectal', 'other']),
    body('frequency').optional().isString(),
    body('end_date').optional().isISO8601(),
    body('instructions').optional().isString(),
    body('prescription_item_id').optional().isUUID(),
    validate,
  ],
  ctrl.createMedication
);

router.get(
  '/medications',
  [
    query('active').optional().isIn(['true', 'false']),
    validate,
  ],
  ctrl.listMedications
);

router.patch(
  '/medications/:id',
  [
    uuidParam,
    body('is_active').optional().isBoolean(),
    body('dosage').optional().isString(),
    body('frequency').optional().isString(),
    body('end_date').optional().isISO8601(),
    body('instructions').optional().isString(),
    validate,
  ],
  ctrl.patchMedication
);

module.exports = router;
