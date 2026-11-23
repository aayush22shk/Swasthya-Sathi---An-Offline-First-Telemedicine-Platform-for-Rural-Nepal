const express = require('express');
const router = express.Router();
const fhirController = require('./fhir.controller');
const { authenticateToken } = require('../../middleware/auth.middleware');

// HL7 FHIR v4 routes
// GET /api/v1/fhir/Patient/:id/$everything -> Full FHIR v4 Bundle
router.get('/Patient/:id/\\$everything', authenticateToken, fhirController.getPatientEverything);

// GET /api/v1/fhir/Patient/:id -> Single FHIR v4 Patient
router.get('/Patient/:id', authenticateToken, fhirController.getPatientResource);

module.exports = router;
