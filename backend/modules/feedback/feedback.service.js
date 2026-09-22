const pool = require('../../db');

// --- Reviews ---
const submitReview = async ({ appointment_id, patient_id, doctor_id, rating, comment }) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Insert review
    const res = await client.query(
      `INSERT INTO reviews (appointment_id, patient_id, doctor_id, rating, comment)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [appointment_id, patient_id, doctor_id, rating, comment || null]
    );
    const review = res.rows[0];

    // 2. Re-calculate and update doctor's average rating
    const avgRes = await client.query(
      'SELECT AVG(rating)::numeric(3,2) AS avg_rating FROM reviews WHERE doctor_id = $1',
      [doctor_id]
    );
    const newRating = avgRes.rows[0]?.avg_rating || 0;

    await client.query(
      'UPDATE doctors SET average_rating = $1, updated_at = now() WHERE id = $2',
      [newRating, doctor_id]
    );

    await client.query('COMMIT');
    return review;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

const getDoctorReviews = async (doctorId) => {
  const res = await pool.query(
    `SELECT
       r.*,
       p.full_name AS patient_name
     FROM reviews r
     JOIN patients p ON p.id = r.patient_id
     WHERE r.doctor_id = $1
     ORDER BY r.created_at DESC`,
    [doctorId]
  );
  return res.rows;
};

// --- Notifications ---
const getUserNotifications = async (userId, { unread_only = false, limit = 50 } = {}) => {
  const query = unread_only
    ? 'SELECT * FROM notifications WHERE user_id = $1 AND is_read = false ORDER BY sent_at DESC LIMIT $2'
    : 'SELECT * FROM notifications WHERE user_id = $1 ORDER BY sent_at DESC LIMIT $2';
  const res = await pool.query(query, [userId, limit]);
  return res.rows;
};

const markNotificationRead = async (id, userId) => {
  const res = await pool.query(
    'UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2 RETURNING *',
    [id, userId]
  );
  if (res.rows.length === 0) {
    const err = new Error('Notification not found.');
    err.statusCode = 404;
    throw err;
  }
  return res.rows[0];
};

const markAllNotificationsRead = async (userId) => {
  await pool.query('UPDATE notifications SET is_read = true WHERE user_id = $1', [userId]);
  return { message: 'All notifications marked as read.' };
};

module.exports = {
  submitReview,
  getDoctorReviews,
  getUserNotifications,
  markNotificationRead,
  markAllNotificationsRead,
};
