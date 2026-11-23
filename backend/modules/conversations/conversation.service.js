const pool = require('../../db');

// ---------------------------------------------------------------------------
// Helper: resolve doctor/patient row IDs from users.id
// ---------------------------------------------------------------------------
const getDoctorId = async (userId) => {
  const r = await pool.query('SELECT id FROM doctors WHERE user_id = $1', [userId]);
  if (!r.rows.length) throw Object.assign(new Error('Doctor profile not found.'), { statusCode: 404 });
  return r.rows[0].id;
};

const getPatientId = async (userId) => {
  const r = await pool.query('SELECT id FROM patients WHERE user_id = $1', [userId]);
  if (!r.rows.length) throw Object.assign(new Error('Patient profile not found.'), { statusCode: 404 });
  return r.rows[0].id;
};

// ---------------------------------------------------------------------------
// Get or create conversation between doctor + patient
// ---------------------------------------------------------------------------
const getOrCreateConversation = async (doctorId, patientId) => {
  // Try to get existing
  const existing = await pool.query(
    `SELECT c.*,
            d.full_name AS doctor_name,
            pat.full_name AS patient_name,
            pat.profile_photo_url AS patient_photo
     FROM conversations c
     JOIN doctors d ON d.id = c.doctor_id
     JOIN patients pat ON pat.id = c.patient_id
     WHERE c.doctor_id = $1 AND c.patient_id = $2`,
    [doctorId, patientId]
  );
  if (existing.rows.length) return existing.rows[0];

  // Create new
  const created = await pool.query(
    `INSERT INTO conversations (doctor_id, patient_id)
     VALUES ($1, $2)
     RETURNING *`,
    [doctorId, patientId]
  );
  const conv = created.rows[0];

  // Enrich with names
  const enriched = await pool.query(
    `SELECT c.*,
            d.full_name AS doctor_name,
            pat.full_name AS patient_name,
            pat.profile_photo_url AS patient_photo
     FROM conversations c
     JOIN doctors d ON d.id = c.doctor_id
     JOIN patients pat ON pat.id = c.patient_id
     WHERE c.id = $1`,
    [conv.id]
  );
  return enriched.rows[0];
};

// ---------------------------------------------------------------------------
// List all conversations for a user (doctor or patient)
// ---------------------------------------------------------------------------
const listConversations = async (userId, role) => {
  if (role === 'doctor') {
    const doctorId = await getDoctorId(userId);
    const r = await pool.query(
      `SELECT c.*,
              pat.full_name AS patient_name,
              pat.profile_photo_url AS patient_photo,
              (SELECT message_content FROM messages m
               WHERE m.conversation_id = c.id
               ORDER BY m.created_at DESC LIMIT 1) AS last_message,
              (SELECT created_at FROM messages m
               WHERE m.conversation_id = c.id
               ORDER BY m.created_at DESC LIMIT 1) AS last_message_at
       FROM conversations c
       JOIN patients pat ON pat.id = c.patient_id
       WHERE c.doctor_id = $1
       ORDER BY c.updated_at DESC`,
      [doctorId]
    );
    return r.rows;
  } else {
    const patientId = await getPatientId(userId);
    const r = await pool.query(
      `SELECT c.*,
              d.full_name AS doctor_name,
              d.profile_photo_url AS doctor_photo,
              (SELECT message_content FROM messages m
               WHERE m.conversation_id = c.id
               ORDER BY m.created_at DESC LIMIT 1) AS last_message,
              (SELECT created_at FROM messages m
               WHERE m.conversation_id = c.id
               ORDER BY m.created_at DESC LIMIT 1) AS last_message_at
       FROM conversations c
       JOIN doctors d ON d.id = c.doctor_id
       WHERE c.patient_id = $1
       ORDER BY c.updated_at DESC`,
      [patientId]
    );
    return r.rows;
  }
};

// ---------------------------------------------------------------------------
// Verify user has access to a conversation (returns conversation row or throws)
// ---------------------------------------------------------------------------
const getConversationWithAccess = async (conversationId, userId, role) => {
  const r = await pool.query(
    `SELECT c.*,
            d.full_name AS doctor_name, d.user_id AS doctor_user_id,
            pat.full_name AS patient_name, pat.user_id AS patient_user_id,
            pat.profile_photo_url AS patient_photo
     FROM conversations c
     JOIN doctors d ON d.id = c.doctor_id
     JOIN patients pat ON pat.id = c.patient_id
     WHERE c.id = $1`,
    [conversationId]
  );
  if (!r.rows.length) throw Object.assign(new Error('Conversation not found.'), { statusCode: 404 });

  const conv = r.rows[0];
  if (conv.doctor_user_id !== userId && conv.patient_user_id !== userId) {
    throw Object.assign(new Error('Access denied.'), { statusCode: 403 });
  }
  return conv;
};

// ---------------------------------------------------------------------------
// Get paginated messages for a conversation
// ---------------------------------------------------------------------------
const getMessages = async (conversationId, userId, role, { limit = 50, before } = {}) => {
  // Access check
  await getConversationWithAccess(conversationId, userId, role);

  const params = [conversationId, limit];
  let whereClause = 'WHERE m.conversation_id = $1';
  if (before) {
    whereClause += ' AND m.created_at < $3';
    params.push(before);
  }

  const r = await pool.query(
    `SELECT m.*,
            u.phone AS sender_phone,
            COALESCE(d.full_name, pat.full_name) AS sender_name
     FROM messages m
     JOIN users u ON u.id = m.sender_id
     LEFT JOIN doctors d ON d.user_id = m.sender_id
     LEFT JOIN patients pat ON pat.user_id = m.sender_id
     ${whereClause}
     ORDER BY m.created_at ASC
     LIMIT $2`,
    params
  );
  return r.rows;
};

// ---------------------------------------------------------------------------
// Send a text message
// ---------------------------------------------------------------------------
const sendMessage = async (conversationId, senderId, role, content) => {
  const conv = await getConversationWithAccess(conversationId, senderId, role);

  const r = await pool.query(
    `INSERT INTO messages (conversation_id, sender_id, sender_role, message_type, message_content)
     VALUES ($1, $2, $3, 'text', $4)
     RETURNING *`,
    [conversationId, senderId, role, content]
  );

  // Enrich with sender name
  const msg = r.rows[0];
  const nameRow = role === 'doctor'
    ? await pool.query('SELECT full_name FROM doctors WHERE user_id = $1', [senderId])
    : await pool.query('SELECT full_name FROM patients WHERE user_id = $1', [senderId]);
  msg.sender_name = nameRow.rows[0]?.full_name ?? '';
  return msg;
};

module.exports = {
  getDoctorId,
  getPatientId,
  getOrCreateConversation,
  listConversations,
  getConversationWithAccess,
  getMessages,
  sendMessage,
};
