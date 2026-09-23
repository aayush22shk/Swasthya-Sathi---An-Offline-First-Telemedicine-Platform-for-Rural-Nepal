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

/**
 * Compute bookable time slots for a doctor on a specific date.
 * - Pulls the weekly availability row matching the weekday
 * - Generates slot times at slot_duration_minutes intervals
 * - Removes slots already booked in `appointments` (pending/confirmed)
 * - Removes slots that fall inside an active `doctor_time_off` block
 *
 * @param {string} doctorId
 * @param {string} date  – ISO date string, e.g. "2026-09-25"
 * @returns {Promise<{ date: string, slots: string[] }>}
 */
const getAvailableSlots = async (doctorId, date) => {
  // Day-of-week mapping  (0=Sun … 6=Sat)
  const dayNames = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
  const dayIndex = new Date(date).getDay();
  const dayOfWeek = dayNames[dayIndex];

  // Fetch weekly availability for this weekday
  const availRes = await pool.query(
    `SELECT start_time, end_time, slot_duration_minutes
     FROM doctor_availability
     WHERE doctor_id = $1 AND day_of_week = $2 AND is_active = true
     LIMIT 1`,
    [doctorId, dayOfWeek]
  );

  if (availRes.rows.length === 0) {
    return { date, slots: [] };
  }

  const { start_time, end_time, slot_duration_minutes } = availRes.rows[0];

  // Check if this date falls inside any time-off block
  const startOfDay = `${date}T00:00:00Z`;
  const endOfDay   = `${date}T23:59:59Z`;
  const timeOffRes = await pool.query(
    `SELECT 1 FROM doctor_time_off
     WHERE doctor_id = $1 AND start_at <= $2 AND end_at >= $3`,
    [doctorId, endOfDay, startOfDay]
  );
  if (timeOffRes.rows.length > 0) {
    return { date, slots: [] };
  }

  // Generate all candidate slot start-times
  const [sh, sm] = start_time.split(':').map(Number);
  const [eh, em] = end_time.split(':').map(Number);
  const startMins = sh * 60 + sm;
  const endMins   = eh * 60 + em;
  const duration  = slot_duration_minutes || 15;

  const allSlots = [];
  for (let t = startMins; t + duration <= endMins; t += duration) {
    const hh = String(Math.floor(t / 60)).padStart(2, '0');
    const mm = String(t % 60).padStart(2, '0');
    allSlots.push(`${hh}:${mm}`);
  }

  // Fetch already-booked slots on this date
  const bookedRes = await pool.query(
    `SELECT to_char(scheduled_at AT TIME ZONE 'UTC', 'HH24:MI') AS slot_time
     FROM appointments
     WHERE doctor_id = $1
       AND DATE(scheduled_at AT TIME ZONE 'UTC') = $2::date
       AND status IN ('pending', 'confirmed')`,
    [doctorId, date]
  );
  const bookedTimes = new Set(bookedRes.rows.map(r => r.slot_time.substring(0, 5)));

  const freeSlots = allSlots.filter(s => !bookedTimes.has(s));
  return { date, slots: freeSlots };
};

module.exports = {
  getDoctorAvailability,
  createAvailabilitySlot,
  updateAvailabilitySlot,
  deleteAvailabilitySlot,
  addTimeOff,
  deleteTimeOff,
  getAvailableSlots,
};
