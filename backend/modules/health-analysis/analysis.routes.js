const express = require('express');
const { body, param, query } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate } = require('../../middlewares/auth.middleware');
const ctrl = require('./analysis.controller');

const router = express.Router();
router.use(authenticate);

// POST /api/v1/health-analysis/summary → generate a new analysis
router.post(
  '/summary',
  [
    body('period').optional().isIn(['7d', '30d', '90d']).withMessage('period must be 7d, 30d, or 90d.'),
    body('patient_id').optional().isUUID(),
    validate,
  ],
  ctrl.generateSummary
);

// GET /api/v1/health-analysis/history → list past analyses
router.get(
  '/history',
  [
    query('limit').optional().isInt({ min: 1, max: 50 }),
    query('offset').optional().isInt({ min: 0 }),
    validate,
  ],
  ctrl.listAnalyses
);

// GET /api/v1/health-analysis/:id → get specific analysis
router.get(
  '/:id',
  [
    param('id').isUUID().withMessage('Analysis ID must be a valid UUID.'),
    validate,
  ],
  ctrl.getAnalysis
);

module.exports = router;
