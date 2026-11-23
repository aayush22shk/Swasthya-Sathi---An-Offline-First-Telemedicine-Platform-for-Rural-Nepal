const pool = require('../../db');
const {
  patientToFhir,
  appointmentToFhir,
  diagnosisToFhir,
  prescriptionToFhirRequests,
  bloodPressureToFhir,
  glucoseToFhir,
  buildFhirBundle,
} = require('../../utils/fhir-converter');

/**
 * Access check helper: ensures user is allowed to access patient's FHIR record.
 */
const verifyFhirPatientAccess = async (patientId, userId, role) => {
  if (role === 'admin') return true;

  if (role === 'patient') {
    const res = await pool.query('SELECT id FROM patients WHERE user_id = $1', [userId]);
    if (!res.rows.length || res.rows[0].id !== patientId) {
      throw Object.assign(new Error('Access denied: You can only access your own FHIR record.'), { statusCode: 403 });
    }
    return true;
  }

  if (role === 'doctor') {
    // Doctors can access if they have had an appointment, consultation, or conversation with this patient
    const res = await pool.query(
      `SELECT 1 FROM doctors d
       WHERE d.user_id = $1
         AND (
           EXISTS (SELECT 1 FROM appointments a WHERE a.doctor_id = d.id AND a.patient_id = $2)
           OR EXISTS (SELECT 1 FROM consultations c WHERE c.doctor_id = d.id AND c.patient_id = $2)
           OR EXISTS (SELECT 1 FROM conversations cv WHERE cv.doctor_id = d.id AND cv.patient_id = $2)
         )`,
      [userId, patientId]
    );
    if (!res.rows.length) {
      throw Object.assign(new Error('Access denied: No clinical relationship with this patient.'), { statusCode: 403 });
    }
    return true;
  }

  throw Object.assign(new Error('Access denied.'), { statusCode: 403 });
};

/**
 * Fetches single Patient FHIR resource.
 */
const getFhirPatientResource = async (patientId) => {
  const patientRes = await pool.query(
    `SELECT p.*, u.email, u.phone,
            m.name AS municipality_name,
            d.name AS district_name,
            pr.name AS province_name
     FROM patients p
     JOIN users u ON u.id = p.user_id
     LEFT JOIN municipalities m ON m.id = p.municipality_id
     LEFT JOIN districts d ON d.id = p.district_id
     LEFT JOIN provinces pr ON pr.id = p.province_id
     WHERE p.id = $1`,
    [patientId]
  );

  if (!patientRes.rows.length) {
    throw Object.assign(new Error('Patient not found.'), { statusCode: 404 });
  }

  return patientToFhir(patientRes.rows[0]);
};

/**
 * Compiles and returns a complete HL7 FHIR v4 Bundle ($everything) for a patient.
 */
const getFhirPatientEverything = async (patientId) => {
  const fhirPatient = await getFhirPatientResource(patientId);

  // 1. Appointments / Encounters
  const apptRes = await pool.query(
    `SELECT a.*, d.full_name AS doctor_name, p.full_name AS patient_name
     FROM appointments a
     LEFT JOIN doctors d ON d.id = a.doctor_id
     LEFT JOIN patients p ON p.id = a.patient_id
     WHERE a.patient_id = $1
     ORDER BY a.appointment_date DESC`,
    [patientId]
  );
  const encounters = apptRes.rows.map(appointmentToFhir);

  // 2. Diagnoses & Conditions
  const dxRes = await pool.query(
    `SELECT * FROM diagnosis_results
     WHERE patient_id = $1
     ORDER BY created_at DESC`,
    [patientId]
  );
  const conditions = dxRes.rows.map(diagnosisToFhir);

  // Also include patient_conditions table if records exist
  const condRes = await pool.query(
    `SELECT id, patient_id, condition_name AS title, notes AS description, created_at
     FROM patient_conditions
     WHERE patient_id = $1
     ORDER BY created_at DESC`,
    [patientId]
  );
  for (const c of condRes.rows) {
    conditions.push(diagnosisToFhir(c));
  }

  // 3. Conv Prescriptions & Medicines
  const rxRes = await pool.query(
    `SELECT cp.*, d.full_name AS doctor_name,
            COALESCE(json_agg(cpm.*) FILTER (WHERE cpm.id IS NOT NULL), '[]') AS medicines
     FROM conv_prescriptions cp
     JOIN doctors d ON d.id = cp.doctor_id
     LEFT JOIN conv_prescription_medicines cpm ON cpm.prescription_id = cp.id
     WHERE cp.patient_id = $1
     GROUP BY cp.id, d.full_name
     ORDER BY cp.created_at DESC`,
    [patientId]
  );

  const medicationRequests = [];
  for (const rx of rxRes.rows) {
    const reqs = prescriptionToFhirRequests(rx, rx.medicines || []);
    medicationRequests.push(...reqs);
  }

  // 4. Observations (Blood Pressure)
  const bpRes = await pool.query(
    `SELECT * FROM blood_pressure_readings
     WHERE patient_id = $1
     ORDER BY reading_date DESC LIMIT 50`,
    [patientId]
  );
  const bpObservations = bpRes.rows.map(bloodPressureToFhir);

  // 5. Observations (Glucose)
  const gluRes = await pool.query(
    `SELECT * FROM glucose_readings
     WHERE patient_id = $1
     ORDER BY reading_date DESC LIMIT 50`,
    [patientId]
  );
  const gluObservations = gluRes.rows.map(glucoseToFhir);

  // Aggregate all resources
  const allResources = [
    fhirPatient,
    ...encounters,
    ...conditions,
    ...medicationRequests,
    ...bpObservations,
    ...gluObservations,
  ].filter(Boolean);

  return buildFhirBundle(allResources, patientId);
};

module.exports = {
  verifyFhirPatientAccess,
  getFhirPatientResource,
  getFhirPatientEverything,
};
