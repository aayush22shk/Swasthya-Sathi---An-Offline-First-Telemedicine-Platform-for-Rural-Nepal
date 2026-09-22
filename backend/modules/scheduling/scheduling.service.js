const pool = require('../../db');

const getDoctorAvailability = async (doctorId) => {
  const slotsRes = await pool.query(
    `SELECT id, doctor_id, day_of_week, start_time, end_time, slot_duration_minutes, is_active
     FROM doctor_availability
     WHERE doctor_id = $1 AND is_active = true
     ORDER BY CASE day_of_week
       WHEN 'sun' THEN 1 WHEN 'mon' THEN 2 WHEN 'tue' THEN 3
       WHEN 'wed' THEN 4 WHEN 'thu' THEN 5 WHEN 'fri' THEN 6 WHEN 'sat' THEN 7
     END, start_time ASC`,
    [doctorId]
  );

  const timeOffRes = await pool.query(
    `SELECT id, doctor_id, start_at, end_at, reason
     FROM doctor_time_off
     WHERE doctor_id = $1 AND end_at >= now()
     ORDER BY start_at ASC`,
    [doctorId]
  );

  return {
    weekly_slots: slotsRes.rows,
    time_off: timeOffRes.rows,
  };
};

const createAvailabilitySlot = async (doctorId, { day_of_week, start_time, end_time, slot_duration_minutes, is_active }) => {
  const res = await pool.query(
    `INSERT INTO doctor_availability (doctor_id, day_of_week, start_time, end_time, slot_duration_minutes, is_active)
     VALUES ($1, $2, $3, $4, COALESCE($5, 15), COALESCE($6, true))
     RETURNING *`,
    [doctorId, day_of_week, start_time, end_time, slot_duration_minutes, is_active]
  );
  return res.rows[0];
};

const updateAvailabilitySlot = async (slotId, doctorId, fields) => {
  const { day_of_week, start_time, end_time, slot_duration_minutes, is_active } = fields;
  const res = await pool.query(
    `UPDATE doctor_availability
     SET day_of_week = COALESCE($1, day_of_week),
         start_time = COALESCE($2, start_time),
         end_time = COALESCE($3, end_time),
         slot_duration_minutes = COALESCE($4, slot_duration_minutes),
         is_active = COALESCE($5, is_active)
     WHERE id = $6 AND doctor_id = $7
     RETURNING *`,
    [day_of_week, start_time, end_time, slot_duration_minutes, is_active, slotId, doctorId]
  );
  if (res.rows.length === 0) {
    const err = new Error('Slot not found or unauthorized.');
    err.statusCode = 404;
    throw err;
  }
  return res.rows[0];
};

const deleteAvailabilitySlot = async (slotId, doctorId) => {
  const res = await pool.query(
    'DELETE FROM doctor_availability WHERE id = $1 AND doctor_id = $2 RETURNING id',
    [slotId, doctorId]
  );
  if (res.rows.length === 0) {
    const err = new Error('Slot not found or unauthorized.');
    err.statusCode = 404;
    throw err;
  }
  return { message: 'Slot deleted successfully.' };
};

const addTimeOff = async (doctorId, { start_at, end_at, reason }) => {
  const res = await pool.query(
    `INSERT INTO doctor_time_off (doctor_id, start_at, end_at, reason)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [doctorId, start_at, end_at, reason || null]
  );
  return res.rows[0];
};

const deleteTimeOff = async (timeOffId, doctorId) => {
  const res = await pool.query(
    'DELETE FROM doctor_time_off WHERE id = $1 AND doctor_id = $2 RETURNING id',
    [timeOffId, doctorId]
  );
  if (res.rows.length === 0) {
    const err = new Error('Time off record not found or unauthorized.');
    err.statusCode = 404;
    throw err;
  }
  return { message: 'Time off removed.' };
};

module.exports = {
  getDoctorAvailability,
  createAvailabilitySlot,
  updateAvailabilitySlot,
  deleteAvailabilitySlot,
  addTimeOff,
  deleteTimeOff,
};
