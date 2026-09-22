const express = require('express');
const { body, query } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate, authorize } = require('../../middlewares/auth.middleware');
const {
  listProvinces,
  listDistricts,
  listMunicipalities,
  listSpecializations,
  addSpecialization,
  listLanguages,
} = require('./masters.controller');

const router = express.Router();

router.get('/provinces', listProvinces);

router.get(
  '/districts',
  [query('province_id').optional().isInt({ min: 1 }), validate],
  listDistricts
);

router.get(
  '/municipalities',
  [query('district_id').optional().isInt({ min: 1 }), validate],
  listMunicipalities
);

router.get('/specializations', listSpecializations);

router.post(
  '/specializations',
  authenticate,
  authorize('admin'),
  [
    body('name').trim().notEmpty().withMessage('Specialization name is required.'),
    body('description').optional().isString(),
    validate,
  ],
  addSpecialization
);

router.get('/languages', listLanguages);

module.exports = router;
