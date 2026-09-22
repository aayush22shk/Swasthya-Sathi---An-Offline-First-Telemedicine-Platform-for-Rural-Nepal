const adminService = require('./admin.service');
const { sendSuccess, sendError } = require('../../utils/response');

const getAdmins = async (req, res) => {
  try {
    const data = await adminService.listAdmins();
    return sendSuccess(res, 200, 'Admins retrieved.', data);
  } catch (err) {
    return sendError(res, 500, err.message);
  }
};

const makeAdmin = async (req, res) => {
  try {
    const data = await adminService.assignAdmin(req.body);
    return sendSuccess(res, 201, 'Admin role assigned.', data);
  } catch (err) {
    return sendError(res, 500, err.message);
  }
};

const getLogs = async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 100, 200);
    const offset = parseInt(req.query.offset, 10) || 0;
    const entity_type = req.query.entity_type;
    const data = await adminService.getAuditLogs({ entity_type, limit, offset });
    return sendSuccess(res, 200, 'Audit logs retrieved.', data);
  } catch (err) {
    return sendError(res, 500, err.message);
  }
};

module.exports = {
  getAdmins,
  makeAdmin,
  getLogs,
};
