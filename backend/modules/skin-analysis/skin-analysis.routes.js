const express = require('express');
const router = express.Router();
const controller = require('./skin-analysis.controller');
const { authenticateToken, requireRole } = require('../../middleware/auth.middleware');

// Patient creates an analysis record (from offline model or sync)
router.post('/', authenticateToken, requireRole('patient'), controller.createAnalysis);

// Patient lists their analyses
router.get('/my', authenticateToken, requireRole('patient'), controller.getMyAnalyses);

// View analysis details (patient or authorized doctor)
router.get('/:id', authenticateToken, controller.getAnalysisById);

// Patient shares analysis with doctor
router.post('/:id/share', authenticateToken, requireRole('patient'), controller.shareWithDoctor);

// Doctor reviews and provides clinical notes
router.post('/:id/review', authenticateToken, requireRole('doctor'), controller.reviewAnalysis);

module.exports = router;
