const express = require('express');
const { body, param } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate, authorize } = require('../../middlewares/auth.middleware');
const {
  getMyProfile, getPatient, updatePatient, deletePatient,
} = require('./patient.controller');

const router = express.Router();

// All patient routes require a valid JWT
router.use(authenticate);

const uuidParam = param('id').isUUID().withMessage('Patient ID must be a valid UUID.');

const updateRules = [
  body('full_name').optional().trim().notEmpty().withMessage('Full name cannot be blank.'),
  body('email').optional({ checkFalsy: true }).isEmail().withMessage('Invalid email format.'),
  body('phone').optional({ checkFalsy: true }).matches(/^[0-9+ ]{7,20}$/).withMessage('Invalid phone number.'),
  body('gender').optional({ checkFalsy: true })
    .isIn(['male', 'female', 'other']).withMessage("Gender must be 'male', 'female', or 'other'."),
  body('dob').optional({ checkFalsy: true })
    .isISO8601().withMessage('Date of birth must be in YYYY-MM-DD format.'),
  body('blood_group').optional({ checkFalsy: true })
    .isIn(['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'])
    .withMessage('Invalid blood group.'),
  body('municipality_id').optional({ checkFalsy: true })
    .isInt({ min: 1 }).withMessage('Municipality ID must be a positive integer.'),
  body('ward_no').optional({ checkFalsy: true }).isString(),
  body('address_line').optional({ checkFalsy: true }).isString(),
  body('emergency_contact_name').optional({ checkFalsy: true }).isString(),
  body('emergency_contact_phone').optional({ checkFalsy: true })
    .matches(/^\+?[0-9]{7,20}$/).withMessage('Invalid emergency contact phone number.'),
  body('preferred_language').optional({ checkFalsy: true })
    .isIn(['ne', 'en']).withMessage("Language must be 'ne' or 'en'."),
];


/**
 * @route   GET /api/v1/patients/me
 * @desc    Get own patient profile (from JWT)
 * @access  Patient only
 */
router.get('/me', authorize('patient'), getMyProfile);

/**
 * @route   GET /api/v1/patients/:id
 * @desc    Get patient profile by UUID
 * @access  Patient (own) | Admin
 */
router.get('/:id', [uuidParam, validate], authorize('patient', 'admin'), getPatient);

/**
 * @route   PUT /api/v1/patients/:id
 * @desc    Update patient profile
 * @access  Patient (own) | Admin
 */
router.put('/:id', [uuidParam, ...updateRules, validate],
  authorize('patient', 'admin'), updatePatient);

/**
 * @route   DELETE /api/v1/patients/:id
 * @desc    Deactivate patient account (soft delete)
 * @access  Patient (own) | Admin
 */
router.delete('/:id', [uuidParam, validate], authorize('patient', 'admin'), deletePatient);

module.exports = router;
