const express = require('express');
const router = express.Router();
const controller = require('./skin-analysis.controller');
const { authenticate, authorize } = require('../../middlewares/auth.middleware');

// Patient creates an analysis record (from offline model or sync)
router.post('/', authenticate, authorize('patient'), controller.createAnalysis);

// Patient lists their analyses
router.get('/my', authenticate, authorize('patient'), controller.getMyAnalyses);

// View analysis details (patient or authorized doctor)
router.get('/:id', authenticate, controller.getAnalysisById);

// Patient shares analysis with doctor
router.post('/:id/share', authenticate, authorize('patient'), controller.shareWithDoctor);

// Doctor reviews and provides clinical notes
router.post('/:id/review', authenticate, authorize('doctor'), controller.reviewAnalysis);

module.exports = router;
