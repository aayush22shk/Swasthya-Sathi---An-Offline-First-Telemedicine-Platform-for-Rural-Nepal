const pool = require('../../db');

const createPrescription = async ({ consultation_id, doctor_id, patient_id, notes, items = [] }) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Insert prescription
    const rxRes = await client.query(
      `INSERT INTO prescriptions (consultation_id, doctor_id, patient_id, notes)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [consultation_id, doctor_id, patient_id, notes || null]
    );
    const prescription = rxRes.rows[0];

    // 2. Insert items
    const insertedItems = [];
    for (const item of items) {
      const itemRes = await client.query(
        `INSERT INTO prescription_items (prescription_id, medicine_name, dosage, route, frequency, duration_days, instructions)
         VALUES ($1, $2, $3, COALESCE($4, 'oral'), $5, $6, $7)
         RETURNING *`,
        [
          prescription.id,
          item.medicine_name,
          item.dosage || null,
          item.route || 'oral',
          item.frequency || null,
          item.duration_days || null,
          item.instructions || null,
        ]
      );
      insertedItems.push(itemRes.rows[0]);
    }

    // 3. Notify patient
    const patUser = await client.query('SELECT user_id FROM patients WHERE id = $1', [patient_id]);
    if (patUser.rows.length > 0) {
      await client.query(
        `INSERT INTO notifications (user_id, type, title, message)
         VALUES ($1, 'prescription_issued', 'New Prescription Issued', 'Your doctor has issued a digital prescription for your consultation.')`,
        [patUser.rows[0].user_id]
      );
    }

    await client.query('COMMIT');
    return { ...prescription, items: insertedItems };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

const getPrescriptionById = async (id) => {
  const rxRes = await pool.query(
    `SELECT
       p.*,
       d.full_name AS doctor_name, d.nmc_registration_number,
       pat.full_name AS patient_name, pat.dob AS patient_dob, pat.gender AS patient_gender
     FROM prescriptions p
     JOIN doctors d ON d.id = p.doctor_id
     JOIN patients pat ON pat.id = p.patient_id
     WHERE p.id = $1`,
    [id]
  );
  if (rxRes.rows.length === 0) {
    const err = new Error('Prescription not found.');
    err.statusCode = 404;
    throw err;
  }

  const itemsRes = await pool.query(
    'SELECT * FROM prescription_items WHERE prescription_id = $1 ORDER BY id ASC',
    [id]
  );

  return { ...rxRes.rows[0], items: itemsRes.rows };
};

const getPrescriptionsByPatient = async (patientId) => {
  const rxRes = await pool.query(
    `SELECT
       p.*,
       d.full_name AS doctor_name,
       COALESCE(json_agg(pi.*) FILTER (WHERE pi.id IS NOT NULL), '[]') AS items
     FROM prescriptions p
     JOIN doctors d ON d.id = p.doctor_id
     LEFT JOIN prescription_items pi ON pi.prescription_id = p.id
     WHERE p.patient_id = $1
     GROUP BY p.id, d.full_name
     ORDER BY p.issued_at DESC`,
    [patientId]
  );
  return rxRes.rows;
};

module.exports = {
  createPrescription,
  getPrescriptionById,
  getPrescriptionsByPatient,
};
