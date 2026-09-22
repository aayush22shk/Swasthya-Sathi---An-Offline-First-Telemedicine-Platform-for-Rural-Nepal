const recordsService = require('./records.service');
const { sendSuccess, sendError } = require('../../utils/response');

const listMedicalRecords = async (req, res) => {
  try {
    const data = await recordsService.getMedicalRecords(req.params.patientId);
    return sendSuccess(res, 200, 'Medical records retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const createMedicalRecord = async (req, res) => {
  try {
    const data = await recordsService.addMedicalRecord(req.params.patientId, req.body);
    return sendSuccess(res, 201, 'Medical record added.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const removeMedicalRecord = async (req, res) => {
  try {
    const result = await recordsService.deleteMedicalRecord(req.params.id, req.params.patientId);
    return sendSuccess(res, 200, result.message);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const listVitals = async (req, res) => {
  try {
    const data = await recordsService.getVitals(req.params.patientId);
    return sendSuccess(res, 200, 'Vitals retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const addVitals = async (req, res) => {
  try {
    const data = await recordsService.logVitals(req.params.patientId, req.body);
    return sendSuccess(res, 201, 'Vitals logged.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const listLabReports = async (req, res) => {
  try {
    const data = await recordsService.getLabReports(req.params.patientId);
    return sendSuccess(res, 200, 'Lab reports retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const createLabReport = async (req, res) => {
  try {
    const data = await recordsService.uploadLabReport(
      req.params.patientId,
      req.user.id,
      req.body
    );
    return sendSuccess(res, 201, 'Lab report uploaded.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const removeLabReport = async (req, res) => {
  try {
    const result = await recordsService.deleteLabReport(req.params.id, req.params.patientId);
    return sendSuccess(res, 200, result.message);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = {
  listMedicalRecords,
  createMedicalRecord,
  removeMedicalRecord,
  listVitals,
  addVitals,
  listLabReports,
  createLabReport,
  removeLabReport,
};
