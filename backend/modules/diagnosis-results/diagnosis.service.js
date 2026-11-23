const pool = require('../../db');
const { getConversationWithAccess, getDoctorId, getPatientId } = require('../conversations/conversation.service');

// ---------------------------------------------------------------------------
// Create a diagnosis result (doctor only) — transaction
// ---------------------------------------------------------------------------
const createDiagnosis = async (conversationId, doctorUserId, {
  title, description, findings, recommended_treatment, additional_notes,
}) => {
  const doctorId = await getDoctorId(doctorUserId);
  const conv = await getConversationWithAccess(conversationId, doctorUserId, 'doctor');

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const dxRes = await client.query(
      `INSERT INTO diagnosis_results
         (conversation_id, doctor_id, patient_id, title, description,
          findings, recommended_treatment, additional_notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        conversationId, doctorId, conv.patient_id,
        title, description || null, findings || null,
        recommended_treatment || null, additional_notes || null,
      ]
    );
    const dx = dxRes.rows[0];

    // Create message row of type 'diagnosis'
    const msgRes = await client.query(
      `INSERT INTO messages (conversation_id, sender_id, sender_role, message_type,
                             message_content, reference_id)
       VALUES ($1, $2, 'doctor', 'diagnosis', $3, $4)
       RETURNING *`,
      [conversationId, doctorUserId, title, dx.id]
    );

    // Audit log
    await client.query(
      `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, metadata)
       VALUES ($1, 'RECORD_DIAGNOSIS', 'diagnosis_results', $2, $3)`,
      [
        doctorUserId,
        dx.id,
        JSON.stringify({
          conversation_id: conversationId,
          patient_id: conv.patient_id,
          title: dx.title,
        }),
      ]
    );

    // Notify patient
    await client.query(
      `INSERT INTO notifications (user_id, type, title, message)
       VALUES ($1, 'diagnosis_shared', 'Diagnosis Results Available',
               'Your doctor has shared diagnosis results with you.')`,
      [conv.patient_user_id]
    );

    await client.query('COMMIT');
    return { ...dx, message: msgRes.rows[0] };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

// ---------------------------------------------------------------------------
// Get a single diagnosis result with access check
// ---------------------------------------------------------------------------
const getDiagnosisById = async (id, userId, role) => {
  const r = await pool.query(
    `SELECT dr.*,
            d.full_name AS doctor_name,
            pat.full_name AS patient_name
     FROM diagnosis_results dr
     JOIN doctors d ON d.id = dr.doctor_id
     JOIN patients pat ON pat.id = dr.patient_id
     WHERE dr.id = $1`,
    [id]
  );
  if (!r.rows.length) throw Object.assign(new Error('Diagnosis not found.'), { statusCode: 404 });

  const dx = r.rows[0];
  await getConversationWithAccess(dx.conversation_id, userId, role);
  return dx;
};

// ---------------------------------------------------------------------------
// Get all diagnoses for a patient
// ---------------------------------------------------------------------------
const getDiagnosesByPatient = async (patientId, userId, role) => {
  if (role === 'patient') {
    const myId = await getPatientId(userId);
    if (myId !== patientId) throw Object.assign(new Error('Access denied.'), { statusCode: 403 });
  }

  const r = await pool.query(
    `SELECT dr.*, d.full_name AS doctor_name
     FROM diagnosis_results dr
     JOIN doctors d ON d.id = dr.doctor_id
     WHERE dr.patient_id = $1
     ORDER BY dr.created_at DESC`,
    [patientId]
  );
  return r.rows;
};

module.exports = { createDiagnosis, getDiagnosisById, getDiagnosesByPatient };
