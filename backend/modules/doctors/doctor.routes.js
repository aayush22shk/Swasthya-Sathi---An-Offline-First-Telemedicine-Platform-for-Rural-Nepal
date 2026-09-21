const express = require('express');
const { body, param, query } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate, authorize } = require('../../middlewares/auth.middleware');
const {
  listDoctors, getMyProfile, getDoctor, updateDoctor, deleteDoctor,
} = require('./doctor.controller');

const router = express.Router();

const uuidParam = param('id').isUUID().withMessage('Doctor ID must be a valid UUID.');

const updateRules = [
  body('full_name').optional().trim().notEmpty().withMessage('Full name cannot be blank.'),
  body('bio').optional({ checkFalsy: false }).isString().withMessage('Bio must be text.'),
  body('consultation_fee')
    .optional()
    .isFloat({ min: 0 }).withMessage('Consultation fee must be a non-negative number.'),
  body('experience_years')
    .optional()
    .isInt({ min: 0 }).withMessage('Experience years must be a non-negative integer.'),
  body('is_available')
    .optional()
    .isBoolean().withMessage('is_available must be a boolean.'),
];

const listQueryRules = [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer.'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be 1-100.'),
  query('nmc_status')
    .optional()
    .isIn(['pending', 'verified', 'rejected'])
    .withMessage("nmc_status must be 'pending', 'verified', or 'rejected'."),
];

/**
 * @route   GET /api/v1/doctors
 * @desc    List all doctors (public — filterable by nmc_status)
 * @access  Public
 */
router.get('/', listQueryRules, validate, listDoctors);

/**
 * @route   GET /api/v1/doctors/me
 * @desc    Get own doctor profile (from JWT)
 * @access  Doctor only
 */
router.get('/me', authenticate, authorize('doctor'), getMyProfile);

/**
 * @route   GET /api/v1/doctors/:id
 * @desc    Get doctor profile by UUID
 * @access  Public
 */
router.get('/:id', [uuidParam, validate], getDoctor);

/**
 * @route   PUT /api/v1/doctors/:id
 * @desc    Update doctor profile (own fields only — NMC status updated by admin)
 * @access  Doctor (own) | Admin
 */
router.put('/:id', authenticate, [uuidParam, ...updateRules, validate],
  authorize('doctor', 'admin'), updateDoctor);

/**
 * @route   DELETE /api/v1/doctors/:id
 * @desc    Deactivate doctor account (soft delete)
 * @access  Doctor (own) | Admin
 */
router.delete('/:id', authenticate, [uuidParam, validate],
  authorize('doctor', 'admin'), deleteDoctor);

module.exports = router;
