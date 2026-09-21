const express = require('express');
const { body } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { registerPatient, registerDoctor, login } = require('./auth.controller');

const router = express.Router();

// ---------------------------------------------------------------------------
// Validation chains
// ---------------------------------------------------------------------------

const patientRegisterRules = [
  body('phone')
    .trim()
    .notEmpty().withMessage('Phone number is required.')
    .matches(/^\+?[0-9]{7,20}$/).withMessage('Enter a valid phone number.'),
  body('email')
    .optional({ checkFalsy: true })
    .isEmail().withMessage('Enter a valid email address.')
    .normalizeEmail(),
  body('password')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters.'),
  body('full_name')
    .trim()
    .notEmpty().withMessage('Full name is required.'),
  body('gender')
    .optional({ checkFalsy: true })
    .isIn(['male', 'female', 'other']).withMessage("Gender must be 'male', 'female', or 'other'."),
  body('dob')
    .optional({ checkFalsy: true })
    .isISO8601().withMessage('Date of birth must be a valid date (YYYY-MM-DD).'),
  body('blood_group')
    .optional({ checkFalsy: true })
    .isIn(['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'])
    .withMessage('Invalid blood group.'),
  body('preferred_language')
    .optional()
    .isIn(['ne', 'en']).withMessage("Language must be 'ne' or 'en'."),
];

const doctorRegisterRules = [
  body('phone')
    .trim()
    .notEmpty().withMessage('Phone number is required.')
    .matches(/^\+?[0-9]{7,20}$/).withMessage('Enter a valid phone number.'),
  body('email')
    .optional({ checkFalsy: true })
    .isEmail().withMessage('Enter a valid email address.')
    .normalizeEmail(),
  body('password')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters.'),
  body('full_name')
    .trim()
    .notEmpty().withMessage('Full name is required.'),
  body('nmc_registration_number')
    .trim()
    .notEmpty().withMessage('NMC registration number is required.'),
  body('consultation_fee')
    .optional()
    .isFloat({ min: 0 }).withMessage('Consultation fee must be a non-negative number.'),
  body('experience_years')
    .optional()
    .isInt({ min: 0 }).withMessage('Experience years must be a non-negative integer.'),
  body('preferred_language')
    .optional()
    .isIn(['ne', 'en']).withMessage("Language must be 'ne' or 'en'."),
];

const loginRules = [
  body('identifier')
    .trim()
    .notEmpty().withMessage('Phone or email is required.'),
  body('password')
    .notEmpty().withMessage('Password is required.'),
];

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

/**
 * @route   POST /api/v1/auth/register/patient
 * @desc    Register a new patient account
 * @access  Public
 */
router.post('/register/patient', patientRegisterRules, validate, registerPatient);

/**
 * @route   POST /api/v1/auth/register/doctor
 * @desc    Register a new doctor account (NMC pending review)
 * @access  Public
 */
router.post('/register/doctor', doctorRegisterRules, validate, registerDoctor);

/**
 * @route   POST /api/v1/auth/login
 * @desc    Login with phone/email + password (patient or doctor)
 * @access  Public
 */
router.post('/login', loginRules, validate, login);

module.exports = router;
