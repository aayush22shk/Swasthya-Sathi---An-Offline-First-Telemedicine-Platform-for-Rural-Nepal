const crypto = require('crypto');
const pool = require('../../db');
const { getConversationWithAccess, getDoctorId, getPatientId } = require('../conversations/conversation.service');

/**
 * Computes deterministic SHA-256 integrity hash for prescription tampering detection.
 */
const computePrescriptionHash = (doctorId, patientId, createdAt, medicines) => {
  const canonicalMeds = (medicines || []).map((m) => ({
    name: (m.medicine_name || '').trim().toLowerCase(),
    dosage: (m.dosage || '').trim().toLowerCase(),
    frequency: (m.frequency || '').trim().toLowerCase(),
    duration: (m.duration || '').trim().toLowerCase(),
    instructions: (m.instructions || '').trim().toLowerCase(),
  })).sort((a, b) => a.name.localeCompare(b.name));

  const canonicalString = `${doctorId}:${patientId}:${new Date(createdAt).toISOString()}:${JSON.stringify(canonicalMeds)}`;
  return crypto.createHash('sha256').update(canonicalString).digest('hex');
};

// ---------------------------------------------------------------------------
// Create a prescription (doctor only) — uses DB transaction
// ---------------------------------------------------------------------------
const createConvPrescription = async (conversationId, doctorUserId, { title, additional_instructions, medicines = [] }) => {
  const doctorId = await getDoctorId(doctorUserId);

  // Access check
  const conv = await getConversationWithAccess(conversationId, doctorUserId, 'doctor');

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Insert prescription
    const rxRes = await client.query(
      `INSERT INTO conv_prescriptions (conversation_id, doctor_id, patient_id, title, additional_instructions)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [conversationId, doctorId, conv.patient_id, title || null, additional_instructions || null]
    );
    const rx = rxRes.rows[0];

    // 2. Insert medicines
    const insertedMeds = [];
    for (const med of medicines) {
      const medRes = await client.query(
        `INSERT INTO conv_prescription_medicines (prescription_id, medicine_name, dosage, frequency, duration, instructions)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [rx.id, med.medicine_name, med.dosage || null, med.frequency || null, med.duration || null, med.instructions || null]
      );
      insertedMeds.push(medRes.rows[0]);
    }

    // 3. Compute SHA-256 Tamper-Evident Hash & persist
    const signatureHash = computePrescriptionHash(doctorId, conv.patient_id, rx.created_at, insertedMeds);
    await client.query(
      'UPDATE conv_prescriptions SET signature_hash = $1 WHERE id = $2',
      [signatureHash, rx.id]
    );
    rx.signature_hash = signatureHash;

    // 4. Create a message row of type 'prescription'
    const msgRes = await client.query(
      `INSERT INTO messages (conversation_id, sender_id, sender_role, message_type,
                             message_content, reference_id)
       VALUES ($1, $2, 'doctor', 'prescription', $3, $4)
       RETURNING *`,
      [conversationId, doctorUserId, title || 'Prescription issued', rx.id]
    );

    // 5. Medical Governance & Audit Logging
    await client.query(
      `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, metadata)
       VALUES ($1, 'ISSUE_PRESCRIPTION', 'conv_prescriptions', $2, $3)`,
      [
        doctorUserId,
        rx.id,
        JSON.stringify({
          conversation_id: conversationId,
          patient_id: conv.patient_id,
          signature_hash: signatureHash,
          item_count: insertedMeds.length,
        }),
      ]
    );

    // 6. Notify patient
    await client.query(
      `INSERT INTO notifications (user_id, type, title, message)
       VALUES ($1, 'prescription_issued', 'New Prescription',
               'Your doctor has issued a prescription for your consultation.')`,
      [conv.patient_user_id]
    );

    await client.query('COMMIT');
    return { ...rx, medicines: insertedMeds, message: msgRes.rows[0] };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

// ---------------------------------------------------------------------------
// Get a single prescription (doctor or patient of that conversation)
// ---------------------------------------------------------------------------
const getConvPrescriptionById = async (id, userId, role) => {
  const rxRes = await pool.query(
    `SELECT cp.*,
            d.full_name AS doctor_name, d.nmc_registration_number,
            pat.full_name AS patient_name, pat.dob AS patient_dob, pat.gender AS patient_gender
     FROM conv_prescriptions cp
     JOIN doctors d ON d.id = cp.doctor_id
     JOIN patients pat ON pat.id = cp.patient_id
     WHERE cp.id = $1`,
    [id]
  );
  if (!rxRes.rows.length) throw Object.assign(new Error('Prescription not found.'), { statusCode: 404 });

  const rx = rxRes.rows[0];
  // Access check via conversation
  await getConversationWithAccess(rx.conversation_id, userId, role);

  const medsRes = await pool.query(
    'SELECT * FROM conv_prescription_medicines WHERE prescription_id = $1 ORDER BY id ASC',
    [id]
  );
  return { ...rx, medicines: medsRes.rows };
};

// ---------------------------------------------------------------------------
// Get all prescriptions for patient (by either patient or their doctor)
// ---------------------------------------------------------------------------
const getConvPrescriptionsByPatient = async (patientId, userId, role) => {
  // Authorization: either the patient themselves or a doctor
  if (role === 'patient') {
    const myPatientId = await getPatientId(userId);
    if (myPatientId !== patientId) throw Object.assign(new Error('Access denied.'), { statusCode: 403 });
  }

  const r = await pool.query(
    `SELECT cp.*,
            d.full_name AS doctor_name,
            COALESCE(json_agg(cpm.*) FILTER (WHERE cpm.id IS NOT NULL), '[]') AS medicines
     FROM conv_prescriptions cp
     JOIN doctors d ON d.id = cp.doctor_id
     LEFT JOIN conv_prescription_medicines cpm ON cpm.prescription_id = cp.id
     WHERE cp.patient_id = $1
     GROUP BY cp.id, d.full_name
     ORDER BY cp.created_at DESC`,
    [patientId]
  );
  return r.rows;
};

module.exports = { createConvPrescription, getConvPrescriptionById, getConvPrescriptionsByPatient };
