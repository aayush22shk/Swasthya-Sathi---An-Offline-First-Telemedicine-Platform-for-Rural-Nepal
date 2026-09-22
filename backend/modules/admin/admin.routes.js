const express = require('express');
const { body, query } = require('express-validator');
const { validate } = require('../../middlewares/validate.middleware');
const { authenticate, authorize } = require('../../middlewares/auth.middleware');
const {
  getAdmins,
  makeAdmin,
  getLogs,
} = require('./admin.controller');

const router = express.Router();
router.use(authenticate, authorize('admin'));

router.get('/', getAdmins);

router.post(
  '/',
  [
    body('user_id').isUUID().withMessage('Valid user_id UUID required.'),
    body('permission_level')
      .optional()
      .isIn(['super_admin', 'support_admin', 'content_admin']),
    validate,
  ],
  makeAdmin
);

router.get(
  '/audit-logs',
  [
    query('limit').optional().isInt({ min: 1, max: 200 }),
    query('offset').optional().isInt({ min: 0 }),
    validate,
  ],
  getLogs
);

module.exports = router;
