const pool = require('../../db');

const listPharmacies = async ({ municipality_id } = {}) => {
  const query = municipality_id
    ? 'SELECT * FROM pharmacies WHERE municipality_id = $1 ORDER BY name ASC'
    : 'SELECT * FROM pharmacies ORDER BY name ASC';
  const params = municipality_id ? [municipality_id] : [];
  const res = await pool.query(query, params);
  return res.rows;
};

const createPharmacy = async ({ name, license_no, municipality_id, address_line, contact_phone }) => {
  const res = await pool.query(
    `INSERT INTO pharmacies (name, license_no, municipality_id, address_line, contact_phone)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [name, license_no, municipality_id || null, address_line || null, contact_phone || null]
  );
  return res.rows[0];
};

const placeOrder = async ({ prescription_id, pharmacy_id, patient_id, delivery_address, total_amount }) => {
  const res = await pool.query(
    `INSERT INTO pharmacy_orders (prescription_id, pharmacy_id, patient_id, delivery_address, total_amount, status)
     VALUES ($1, $2, $3, $4, $5, 'placed')
     RETURNING *`,
    [prescription_id, pharmacy_id, patient_id, delivery_address || null, total_amount || 0]
  );
  return res.rows[0];
};

const getOrderById = async (orderId) => {
  const res = await pool.query(
    `SELECT
       po.*,
       ph.name AS pharmacy_name, ph.contact_phone AS pharmacy_phone,
       p.full_name AS patient_name, p.emergency_contact_phone AS patient_phone
     FROM pharmacy_orders po
     JOIN pharmacies ph ON ph.id = po.pharmacy_id
     JOIN patients p ON p.id = po.patient_id
     WHERE po.id = $1`,
    [orderId]
  );
  if (res.rows.length === 0) {
    const err = new Error('Pharmacy order not found.');
    err.statusCode = 404;
    throw err;
  }
  return res.rows[0];
};

const updateOrderStatus = async (orderId, newStatus) => {
  const res = await pool.query(
    `UPDATE pharmacy_orders
     SET status = $1, updated_at = now()
     WHERE id = $2
     RETURNING *`,
    [newStatus, orderId]
  );
  if (res.rows.length === 0) {
    const err = new Error('Order not found.');
    err.statusCode = 404;
    throw err;
  }
  return res.rows[0];
};

module.exports = {
  listPharmacies,
  createPharmacy,
  placeOrder,
  getOrderById,
  updateOrderStatus,
};
