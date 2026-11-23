const fhirService = require('./fhir.service');
const { sendSuccess, sendError } = require('../../utils/response');

const getPatientResource = async (req, res) => {
  try {
    const { id } = req.params;
    await fhirService.verifyFhirPatientAccess(id, req.user.id, req.user.role);
    const resource = await fhirService.getFhirPatientResource(id);
    return res.status(200).json(resource);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const getPatientEverything = async (req, res) => {
  try {
    const { id } = req.params;
    await fhirService.verifyFhirPatientAccess(id, req.user.id, req.user.role);
    const bundle = await fhirService.getFhirPatientEverything(id);
    return res.status(200).json(bundle);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = {
  getPatientResource,
  getPatientEverything,
};
