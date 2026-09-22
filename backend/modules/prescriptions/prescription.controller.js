const prescriptionService = require('./prescription.service');
const pool = require('../../db');
const { sendSuccess, sendError } = require('../../utils/response');

const issuePrescription = async (req, res) => {
  try {
    let { consultation_id, doctor_id, patient_id, notes, items } = req.body;

    if (req.user.role === 'doctor' && !doctor_id) {
      const docRes = await pool.query('SELECT id FROM doctors WHERE user_id = $1', [req.user.id]);
      doctor_id = docRes.rows[0]?.id;
    }

    if (!doctor_id) {
      return sendError(res, 400, 'Doctor ID is required.');
    }

    const data = await prescriptionService.createPrescription({
      consultation_id,
      doctor_id,
      patient_id,
      notes,
      items,
    });
    return sendSuccess(res, 201, 'Prescription issued successfully.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const getPrescription = async (req, res) => {
  try {
    const data = await prescriptionService.getPrescriptionById(req.params.id);
    return sendSuccess(res, 200, 'Prescription retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const getPatientPrescriptions = async (req, res) => {
  try {
    const data = await prescriptionService.getPrescriptionsByPatient(req.params.patientId);
    return sendSuccess(res, 200, 'Patient prescriptions retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = {
  issuePrescription,
  getPrescription,
  getPatientPrescriptions,
};
