const feedbackService = require('./feedback.service');
const pool = require('../../db');
const { sendSuccess, sendError } = require('../../utils/response');

const createReview = async (req, res) => {
  try {
    let { appointment_id, patient_id, doctor_id, rating, comment } = req.body;

    if (req.user.role === 'patient' && !patient_id) {
      const patRes = await pool.query('SELECT id FROM patients WHERE user_id = $1', [req.user.id]);
      patient_id = patRes.rows[0]?.id;
    }

    const data = await feedbackService.submitReview({
      appointment_id,
      patient_id,
      doctor_id,
      rating,
      comment,
    });
    return sendSuccess(res, 201, 'Review submitted.', data);
  } catch (err) {
    return sendError(res, err.code === '23505' ? 409 : (err.statusCode || 500), err.message);
  }
};

const getReviews = async (req, res) => {
  try {
    const data = await feedbackService.getDoctorReviews(req.params.doctorId);
    return sendSuccess(res, 200, 'Doctor reviews retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const getNotifications = async (req, res) => {
  try {
    const unread_only = req.query.unread_only === 'true';
    const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);
    const data = await feedbackService.getUserNotifications(req.user.id, { unread_only, limit });
    return sendSuccess(res, 200, 'Notifications retrieved.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const markRead = async (req, res) => {
  try {
    const data = await feedbackService.markNotificationRead(req.params.id, req.user.id);
    return sendSuccess(res, 200, 'Notification marked as read.', data);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

const markAllRead = async (req, res) => {
  try {
    const result = await feedbackService.markAllNotificationsRead(req.user.id);
    return sendSuccess(res, 200, result.message);
  } catch (err) {
    return sendError(res, err.statusCode || 500, err.message);
  }
};

module.exports = {
  createReview,
  getReviews,
  getNotifications,
  markRead,
  markAllRead,
};
