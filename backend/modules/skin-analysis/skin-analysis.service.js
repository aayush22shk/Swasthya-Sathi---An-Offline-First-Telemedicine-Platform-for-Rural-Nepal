const pool = require('../../db');

const getPatientId = async (userId) => {
  const r = await pool.query('SELECT id FROM patients WHERE user_id = $1', [userId]);
  if (!r.rows.length) throw Object.assign(new Error('Patient profile not found.'), { statusCode: 404 });
  return r.rows[0].id;
};

const getDoctorId = async (userId) => {
  const r = await pool.query('SELECT id FROM doctors WHERE user_id = $1', [userId]);
  if (!r.rows.length) throw Object.assign(new Error('Doctor profile not found.'), { statusCode: 404 });
  return r.rows[0].id;
};

/**
 * Creates a new skin analysis record.
 */
const createSkinAnalysis = async (userId, {
  image_url,
  predicted_condition,
  confidence_score,
  top_predictions = [],
  is_uncertain = false,
  uncertainty_reason = null,
  model_version = 'mobilenetv3_nepal_v1',
}) => {
  const patientId = await getPatientId(userId);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const res = await client.query(
      `INSERT INTO skin_analyses (
        patient_id, image_url, predicted_condition, confidence_score,
        top_predictions, is_uncertain, uncertainty_reason, model_version
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *`,
      [
        patientId,
        image_url,
        predicted_condition,
        confidence_score,
        JSON.stringify(top_predictions),
        is_uncertain,
        uncertainty_reason,
        model_version,
      ]
    );
    const analysis = res.rows[0];

    // Audit log
    await client.query(
      `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, metadata)
       VALUES ($1, 'CREATE_SKIN_ANALYSIS', 'skin_analyses', $2, $3)`,
      [
        userId,
        analysis.id,
        JSON.stringify({
          predicted_condition,
          confidence_score,
          is_uncertain,
        }),
      ]
    );

    await client.query('COMMIT');
    return analysis;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

/**
 * Fetches all skin analyses for the requesting patient.
 */
const getPatientAnalyses = async (userId) => {
  const patientId = await getPatientId(userId);
  const r = await pool.query(
    `SELECT sa.*, d.full_name AS doctor_name
     FROM skin_analyses sa
     LEFT JOIN doctors d ON d.id = sa.doctor_id
     WHERE sa.patient_id = $1
     ORDER BY sa.created_at DESC`,
    [patientId]
  );
  return r.rows;
};

/**
 * Gets single analysis with access control.
 */
const getSkinAnalysisById = async (id, userId, role) => {
  const r = await pool.query(
    `SELECT sa.*,
            p.full_name AS patient_name, p.dob AS patient_dob, p.gender AS patient_gender,
            d.full_name AS doctor_name, d.nmc_registration_number
     FROM skin_analyses sa
     JOIN patients p ON p.id = sa.patient_id
     LEFT JOIN doctors d ON d.id = sa.doctor_id
     WHERE sa.id = $1`,
    [id]
  );
  if (!r.rows.length) throw Object.assign(new Error('Skin analysis not found.'), { statusCode: 404 });
  const analysis = r.rows[0];

  if (role === 'patient') {
    const myPatientId = await getPatientId(userId);
    if (analysis.patient_id !== myPatientId) {
      throw Object.assign(new Error('Access denied: not your record.'), { statusCode: 403 });
    }
  } else if (role === 'doctor') {
    const myDoctorId = await getDoctorId(userId);
    // Doctor can view if directly shared with them or if they have an active consultation/conversation
    if (analysis.doctor_id !== myDoctorId && !analysis.is_shared_with_doctor) {
      throw Object.assign(new Error('Access denied: analysis not shared with you.'), { statusCode: 403 });
    }
  }

  return analysis;
};

/**
 * Shares an AI analysis with a doctor and optionally sends it to chat.
 */
const shareAnalysisWithDoctor = async (id, userId, { doctor_id, conversation_id }) => {
  const patientId = await getPatientId(userId);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const updateRes = await client.query(
      `UPDATE skin_analyses
       SET is_shared_with_doctor = true,
           doctor_id = $1,
           updated_at = now()
       WHERE id = $2 AND patient_id = $3
       RETURNING *`,
      [doctor_id, id, patientId]
    );

    if (!updateRes.rows.length) {
      throw Object.assign(new Error('Skin analysis not found or not owned by you.'), { statusCode: 404 });
    }
    const analysis = updateRes.rows[0];

    // Get doctor user_id to notify
    const docRes = await client.query('SELECT user_id, full_name FROM doctors WHERE id = $1', [doctor_id]);
    if (docRes.rows.length) {
      const doc = docRes.rows[0];
      await client.query(
        `INSERT INTO notifications (user_id, type, title, message)
         VALUES ($1, 'skin_analysis_shared', 'Patient Shared Skin Analysis',
                 $2)`,
        [
          doc.user_id,
          `A patient has shared an AI skin screening for ${analysis.predicted_condition} (${Math.round(analysis.confidence_score * 100)}% confidence).`,
        ]
      );
    }

    // If conversation_id is provided, post a chat message
    if (conversation_id) {
      await client.query(
        `INSERT INTO messages (conversation_id, sender_id, sender_role, message_type,
                               message_content, reference_id)
         VALUES ($1, $2, 'patient', 'text', $3, $4)`,
        [
          conversation_id,
          userId,
          `[AI Skin Screening] I shared my ${analysis.predicted_condition} image analysis (${Math.round(analysis.confidence_score * 100)}% confidence) for your medical review.`,
          analysis.id,
        ]
      );
    }

    await client.query('COMMIT');
    return analysis;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

/**
 * Doctor submits clinical review & assessment of the AI screening.
 */
const reviewSkinAnalysis = async (id, userId, { doctor_notes }) => {
  const doctorId = await getDoctorId(userId);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const res = await client.query(
      `UPDATE skin_analyses
       SET doctor_notes = $1,
           doctor_id = $2,
           reviewed_at = now(),
           updated_at = now()
       WHERE id = $3
       RETURNING *`,
      [doctor_notes, doctorId, id]
    );

    if (!res.rows.length) {
      throw Object.assign(new Error('Analysis record not found.'), { statusCode: 404 });
    }
    const updated = res.rows[0];

    // Notify patient
    const patRes = await client.query('SELECT user_id FROM patients WHERE id = $1', [updated.patient_id]);
    if (patRes.rows.length) {
      await client.query(
        `INSERT INTO notifications (user_id, type, title, message)
         VALUES ($1, 'skin_analysis_reviewed', 'Doctor Reviewed Your Skin Analysis',
                 'Your doctor has reviewed your skin screening and provided clinical notes.')`,
        [patRes.rows[0].user_id]
      );
    }

    // Audit log
    await client.query(
      `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, metadata)
       VALUES ($1, 'REVIEW_SKIN_ANALYSIS', 'skin_analyses', $2, $3)`,
      [userId, id, JSON.stringify({ doctor_id: doctorId })]
    );

    await client.query('COMMIT');
    return updated;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  createSkinAnalysis,
  getPatientAnalyses,
  getSkinAnalysisById,
  shareAnalysisWithDoctor,
  reviewSkinAnalysis,
};
