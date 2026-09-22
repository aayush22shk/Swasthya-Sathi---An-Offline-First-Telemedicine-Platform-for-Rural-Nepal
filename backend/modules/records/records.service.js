const pool = require('../../db');

// --- Medical Records ---
const getMedicalRecords = async (patientId) => {
  const res = await pool.query(
    'SELECT * FROM medical_records WHERE patient_id = $1 ORDER BY recorded_at DESC',
    [patientId]
  );
  return res.rows;
};

const addMedicalRecord = async (patientId, { record_type, description }) => {
  const res = await pool.query(
    `INSERT INTO medical_records (patient_id, record_type, description)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [patientId, record_type, description]
  );
  return res.rows[0];
};

const deleteMedicalRecord = async (id, patientId) => {
  const res = await pool.query(
    'DELETE FROM medical_records WHERE id = $1 AND patient_id = $2 RETURNING id',
    [id, patientId]
  );
  if (res.rows.length === 0) {
    const err = new Error('Medical record not found or unauthorized.');
    err.statusCode = 404;
    throw err;
  }
  return { message: 'Medical record deleted.' };
};

// --- Vitals ---
const getVitals = async (patientId) => {
  const res = await pool.query(
    'SELECT * FROM vitals WHERE patient_id = $1 ORDER BY recorded_at DESC LIMIT 50',
    [patientId]
  );
  return res.rows;
};

const logVitals = async (patientId, { systolic_bp, diastolic_bp, blood_sugar, weight_kg }) => {
  const res = await pool.query(
    `INSERT INTO vitals (patient_id, systolic_bp, diastolic_bp, blood_sugar, weight_kg)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [patientId, systolic_bp || null, diastolic_bp || null, blood_sugar || null, weight_kg || null]
  );
  return res.rows[0];
};

// --- Lab Reports ---
const getLabReports = async (patientId) => {
  const res = await pool.query(
    'SELECT * FROM lab_reports WHERE patient_id = $1 ORDER BY uploaded_at DESC',
    [patientId]
  );
  return res.rows;
};

const uploadLabReport = async (patientId, uploadedBy, { report_type, file_url }) => {
  const res = await pool.query(
    `INSERT INTO lab_reports (patient_id, uploaded_by, report_type, file_url)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [patientId, uploadedBy || null, report_type || null, file_url]
  );
  return res.rows[0];
};

const deleteLabReport = async (id, patientId) => {
  const res = await pool.query(
    'DELETE FROM lab_reports WHERE id = $1 AND patient_id = $2 RETURNING id',
    [id, patientId]
  );
  if (res.rows.length === 0) {
    const err = new Error('Lab report not found or unauthorized.');
    err.statusCode = 404;
    throw err;
  }
  return { message: 'Lab report deleted.' };
};

module.exports = {
  getMedicalRecords,
  addMedicalRecord,
  deleteMedicalRecord,
  getVitals,
  logVitals,
  getLabReports,
  uploadLabReport,
  deleteLabReport,
};
