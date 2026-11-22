const pool = require('../../db');

const startConsultation = async ({ appointment_id, video_room_id }) => {
  // Check if consultation already exists for this appointment
  const existing = await pool.query('SELECT * FROM consultations WHERE appointment_id = $1', [appointment_id]);
  if (existing.rows.length > 0) {
    return existing.rows[0];
  }

  const res = await pool.query(
    `INSERT INTO consultations (appointment_id, video_room_id, started_at)
     VALUES ($1, $2, now())
     RETURNING *`,
    [appointment_id, video_room_id || `room_${appointment_id}`]
  );
  return res.rows[0];
};

const getConsultationById = async (id) => {
  const res = await pool.query(
    `SELECT
       c.*,
       a.scheduled_at, a.mode, a.fee, a.reason_for_visit,
       p.id AS patient_id, p.full_name AS patient_name,
       d.id AS doctor_id, d.full_name AS doctor_name
     FROM consultations c
     JOIN appointments a ON a.id = c.appointment_id
     JOIN patients p ON p.id = a.patient_id
     JOIN doctors d ON d.id = a.doctor_id
     WHERE c.id = $1 OR c.appointment_id = $1`,
    [id]
  );
  if (res.rows.length === 0) {
    const err = new Error('Consultation not found.');
    err.statusCode = 404;
    throw err;
  }
  return res.rows[0];
};

const endConsultation = async (id, { doctor_notes, diagnosis }) => {
  const res = await pool.query(
    `UPDATE consultations
     SET doctor_notes = COALESCE($1, doctor_notes),
         diagnosis = COALESCE($2, diagnosis),
         ended_at = now()
     WHERE id = $3 OR appointment_id = $3
     RETURNING *`,
    [doctor_notes, diagnosis, id]
  );
  if (res.rows.length === 0) {
    const err = new Error('Consultation not found.');
    err.statusCode = 404;
    throw err;
  }
  return res.rows[0];
};

const getChatMessages = async (consultationId, { limit = 100, offset = 0 } = {}) => {
  const res = await pool.query(
    `SELECT
       m.id, m.consultation_id, m.sender_id, m.message, m.attachment_url, m.sent_at,
       u.role AS sender_role,
       COALESCE(p.full_name, d.full_name, 'User') AS sender_name
     FROM chat_messages m
     JOIN users u ON u.id = m.sender_id
     LEFT JOIN patients p ON p.user_id = u.id
     LEFT JOIN doctors d ON d.user_id = u.id
     WHERE m.consultation_id = $1
        OR m.consultation_id = (SELECT id FROM consultations WHERE appointment_id = $1 LIMIT 1)
     ORDER BY m.sent_at ASC
     LIMIT $2 OFFSET $3`,
    [consultationId, limit, offset]
  );
  return res.rows;
};

const sendChatMessage = async (consultationOrAppointmentId, senderId, { message, attachment_url }) => {
  let consultationId = consultationOrAppointmentId;

  // Verify if given ID is consultations.id; if not, check/create by appointment_id
  const consCheck = await pool.query('SELECT id FROM consultations WHERE id = $1', [consultationOrAppointmentId]);
  if (consCheck.rows.length > 0) {
    consultationId = consCheck.rows[0].id;
  } else {
    const apptCheck = await pool.query('SELECT id FROM consultations WHERE appointment_id = $1', [consultationOrAppointmentId]);
    if (apptCheck.rows.length > 0) {
      consultationId = apptCheck.rows[0].id;
    } else {
      // Auto-start consultation session for this appointment if not exists yet
      const newCons = await pool.query(
        `INSERT INTO consultations (appointment_id, video_room_id, started_at)
         VALUES ($1, $2, now())
         RETURNING id`,
        [consultationOrAppointmentId, `room_${consultationOrAppointmentId}`]
      );
      consultationId = newCons.rows[0].id;
    }
  }

  const res = await pool.query(
    `INSERT INTO chat_messages (consultation_id, sender_id, message, attachment_url)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [consultationId, senderId, message || null, attachment_url || null]
  );

  const newMsg = res.rows[0];

  // Fetch sender info for instant client reflection
  const senderInfo = await pool.query(
    `SELECT u.role AS sender_role, COALESCE(p.full_name, d.full_name, 'User') AS sender_name
     FROM users u
     LEFT JOIN patients p ON p.user_id = u.id
     LEFT JOIN doctors d ON d.user_id = u.id
     WHERE u.id = $1`,
    [senderId]
  );

  if (senderInfo.rows.length > 0) {
    newMsg.sender_role = senderInfo.rows[0].sender_role;
    newMsg.sender_name = senderInfo.rows[0].sender_name;
  }

  return newMsg;
};

module.exports = {
  startConsultation,
  getConsultationById,
  endConsultation,
  getChatMessages,
  sendChatMessage,
};
