const pool = require('../../db');

// ─── BLOOD PRESSURE ──────────────────────────────────────────────────────────

const addBPReading = async ({ patient_id, systolic, diastolic, heart_rate, measured_at, measurement_context, source, notes }) => {
  const res = await pool.query(
    `INSERT INTO blood_pressure_readings
       (patient_id, systolic, diastolic, heart_rate, measured_at, measurement_context, source, notes)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING *`,
    [patient_id, systolic, diastolic, heart_rate || null, measured_at, measurement_context || 'manual', source || 'manual', notes || null]
  );
  return res.rows[0];
};

const getBPHistory = async ({ patient_id, limit = 30, offset = 0, from, to }) => {
  const params = [patient_id];
  let dateFilter = '';
  if (from) { params.push(from); dateFilter += ` AND measured_at >= $${params.length}`; }
  if (to)   { params.push(to);   dateFilter += ` AND measured_at <= $${params.length}`; }
  params.push(limit, offset);

  const res = await pool.query(
    `SELECT * FROM blood_pressure_readings
     WHERE patient_id = $1 ${dateFilter}
     ORDER BY measured_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );
  return res.rows;
};

// ─── GLUCOSE ─────────────────────────────────────────────────────────────────

const addGlucoseReading = async ({ patient_id, glucose_value, unit, measurement_type, measured_at, source, notes }) => {
  const res = await pool.query(
    `INSERT INTO glucose_readings
       (patient_id, glucose_value, unit, measurement_type, measured_at, source, notes)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [patient_id, glucose_value, unit || 'mg/dl', measurement_type || 'random', measured_at, source || 'manual', notes || null]
  );
  return res.rows[0];
};

const getGlucoseHistory = async ({ patient_id, limit = 30, offset = 0, from, to }) => {
  const params = [patient_id];
  let dateFilter = '';
  if (from) { params.push(from); dateFilter += ` AND measured_at >= $${params.length}`; }
  if (to)   { params.push(to);   dateFilter += ` AND measured_at <= $${params.length}`; }
  params.push(limit, offset);

  const res = await pool.query(
    `SELECT * FROM glucose_readings
     WHERE patient_id = $1 ${dateFilter}
     ORDER BY measured_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );
  return res.rows;
};

// ─── WEIGHT ──────────────────────────────────────────────────────────────────

const addWeightReading = async ({ patient_id, weight_kg, measured_at, source, notes }) => {
  const res = await pool.query(
    `INSERT INTO weight_readings (patient_id, weight_kg, measured_at, source, notes)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [patient_id, weight_kg, measured_at, source || 'manual', notes || null]
  );
  return res.rows[0];
};

const getWeightHistory = async ({ patient_id, limit = 30, offset = 0, from, to }) => {
  const params = [patient_id];
  let dateFilter = '';
  if (from) { params.push(from); dateFilter += ` AND measured_at >= $${params.length}`; }
  if (to)   { params.push(to);   dateFilter += ` AND measured_at <= $${params.length}`; }
  params.push(limit, offset);

  const res = await pool.query(
    `SELECT * FROM weight_readings
     WHERE patient_id = $1 ${dateFilter}
     ORDER BY measured_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );
  return res.rows;
};

// ─── SYMPTOMS ─────────────────────────────────────────────────────────────────

const addSymptom = async ({ patient_id, symptom_name, severity, started_at, ended_at, notes }) => {
  const res = await pool.query(
    `INSERT INTO symptom_records (patient_id, symptom_name, severity, started_at, ended_at, notes)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [patient_id, symptom_name, severity || null, started_at || null, ended_at || null, notes || null]
  );
  return res.rows[0];
};

const getSymptoms = async ({ patient_id, limit = 20, offset = 0 }) => {
  const res = await pool.query(
    `SELECT * FROM symptom_records
     WHERE patient_id = $1
     ORDER BY recorded_at DESC
     LIMIT $2 OFFSET $3`,
    [patient_id, limit, offset]
  );
  return res.rows;
};

// ─── CONDITIONS ──────────────────────────────────────────────────────────────

const addCondition = async ({ patient_id, condition_name, condition_type, diagnosis_date, status, notes }) => {
  const res = await pool.query(
    `INSERT INTO patient_conditions (patient_id, condition_name, condition_type, diagnosis_date, status, notes)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [patient_id, condition_name, condition_type || null, diagnosis_date || null, status || 'active', notes || null]
  );
  return res.rows[0];
};

const getConditions = async (patient_id) => {
  const res = await pool.query(
    `SELECT * FROM patient_conditions WHERE patient_id = $1 ORDER BY created_at DESC`,
    [patient_id]
  );
  return res.rows;
};

const updateCondition = async (id, patient_id, updates) => {
  const { condition_name, status, notes, diagnosis_date, condition_type } = updates;
  const res = await pool.query(
    `UPDATE patient_conditions
     SET condition_name = COALESCE($1, condition_name),
         condition_type = COALESCE($2, condition_type),
         diagnosis_date = COALESCE($3, diagnosis_date),
         status = COALESCE($4, status),
         notes = COALESCE($5, notes),
         updated_at = now()
     WHERE id = $6 AND patient_id = $7
     RETURNING *`,
    [condition_name, condition_type, diagnosis_date, status, notes, id, patient_id]
  );
  if (res.rows.length === 0) {
    const err = new Error('Condition not found.');
    err.statusCode = 404;
    throw err;
  }
  return res.rows[0];
};

// ─── MEDICATIONS ─────────────────────────────────────────────────────────────

const addMedication = async ({ patient_id, prescription_item_id, medicine_name, dosage, route, frequency, start_date, end_date, instructions }) => {
  const res = await pool.query(
    `INSERT INTO patient_medications
       (patient_id, prescription_item_id, medicine_name, dosage, route, frequency, start_date, end_date, instructions)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
     RETURNING *`,
    [patient_id, prescription_item_id || null, medicine_name, dosage || null, route || 'oral', frequency || null, start_date, end_date || null, instructions || null]
  );
  return res.rows[0];
};

const getMedications = async (patient_id, active_only = true) => {
  const res = await pool.query(
    `SELECT * FROM patient_medications
     WHERE patient_id = $1 ${active_only ? 'AND is_active = true' : ''}
     ORDER BY created_at DESC`,
    [patient_id]
  );
  return res.rows;
};

const updateMedication = async (id, patient_id, updates) => {
  const { is_active, end_date, dosage, frequency, instructions } = updates;
  const res = await pool.query(
    `UPDATE patient_medications
     SET is_active = COALESCE($1, is_active),
         end_date = COALESCE($2, end_date),
         dosage = COALESCE($3, dosage),
         frequency = COALESCE($4, frequency),
         instructions = COALESCE($5, instructions),
         updated_at = now()
     WHERE id = $6 AND patient_id = $7
     RETURNING *`,
    [is_active, end_date, dosage, frequency, instructions, id, patient_id]
  );
  if (res.rows.length === 0) {
    const err = new Error('Medication not found.');
    err.statusCode = 404;
    throw err;
  }
  return res.rows[0];
};

// ─── LATEST VITALS SUMMARY ───────────────────────────────────────────────────

const getLatestVitalsSummary = async (patient_id) => {
  const [bpRes, glucoseRes, weightRes] = await Promise.all([
    pool.query(
      `SELECT systolic, diastolic, heart_rate, measured_at
       FROM blood_pressure_readings WHERE patient_id = $1 ORDER BY measured_at DESC LIMIT 1`,
      [patient_id]
    ),
    pool.query(
      `SELECT glucose_value, unit, measurement_type, measured_at
       FROM glucose_readings WHERE patient_id = $1 ORDER BY measured_at DESC LIMIT 1`,
      [patient_id]
    ),
    pool.query(
      `SELECT weight_kg, measured_at
       FROM weight_readings WHERE patient_id = $1 ORDER BY measured_at DESC LIMIT 1`,
      [patient_id]
    ),
  ]);
  return {
    blood_pressure: bpRes.rows[0] || null,
    glucose: glucoseRes.rows[0] || null,
    weight: weightRes.rows[0] || null,
  };
};

module.exports = {
  addBPReading, getBPHistory,
  addGlucoseReading, getGlucoseHistory,
  addWeightReading, getWeightHistory,
  addSymptom, getSymptoms,
  addCondition, getConditions, updateCondition,
  addMedication, getMedications, updateMedication,
  getLatestVitalsSummary,
};
