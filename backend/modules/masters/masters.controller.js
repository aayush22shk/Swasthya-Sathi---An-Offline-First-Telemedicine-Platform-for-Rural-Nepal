const mastersService = require('./masters.service');
const { sendSuccess, sendError } = require('../../utils/response');

const listProvinces = async (req, res) => {
  try {
    const data = await mastersService.getProvinces();
    return sendSuccess(res, 200, 'Provinces retrieved.', data);
  } catch (err) {
    return sendError(res, 500, err.message);
  }
};

const listDistricts = async (req, res) => {
  try {
    const provinceId = req.query.province_id ? parseInt(req.query.province_id, 10) : null;
    const data = await mastersService.getDistricts(provinceId);
    return sendSuccess(res, 200, 'Districts retrieved.', data);
  } catch (err) {
    return sendError(res, 500, err.message);
  }
};

const listMunicipalities = async (req, res) => {
  try {
    const districtId = req.query.district_id ? parseInt(req.query.district_id, 10) : null;
    const data = await mastersService.getMunicipalities(districtId);
    return sendSuccess(res, 200, 'Municipalities retrieved.', data);
  } catch (err) {
    return sendError(res, 500, err.message);
  }
};

const listSpecializations = async (req, res) => {
  try {
    const data = await mastersService.getSpecializations();
    return sendSuccess(res, 200, 'Specializations retrieved.', data);
  } catch (err) {
    return sendError(res, 500, err.message);
  }
};

const addSpecialization = async (req, res) => {
  try {
    const data = await mastersService.createSpecialization(req.body);
    return sendSuccess(res, 201, 'Specialization created.', data);
  } catch (err) {
    return sendError(res, err.code === '23505' ? 409 : 500, err.message);
  }
};

const listLanguages = async (req, res) => {
  try {
    const data = await mastersService.getLanguages();
    return sendSuccess(res, 200, 'Languages retrieved.', data);
  } catch (err) {
    return sendError(res, 500, err.message);
  }
};

module.exports = {
  listProvinces,
  listDistricts,
  listMunicipalities,
  listSpecializations,
  addSpecialization,
  listLanguages,
};
