const pool = require('../../db');

const initiatePayment = async ({ appointment_id, pharmacy_order_id, patient_id, amount, gateway }) => {
  const res = await pool.query(
    `INSERT INTO payments (appointment_id, pharmacy_order_id, patient_id, amount, gateway, status)
     VALUES ($1, $2, $3, $4, $5, 'pending')
     RETURNING *`,
    [appointment_id || null, pharmacy_order_id || null, patient_id, amount, gateway]
  );
  return res.rows[0];
};

const verifyPayment = async (paymentId, { gateway_txn_id, status = 'success' }) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const res = await client.query(
      `UPDATE payments
       SET gateway_txn_id = $1, status = $2, paid_at = CASE WHEN $2 = 'success' THEN now() ELSE NULL END
       WHERE id = $3
       RETURNING *`,
      [gateway_txn_id || null, status, paymentId]
    );

    if (res.rows.length === 0) {
      const err = new Error('Payment not found.');
      err.statusCode = 404;
      throw err;
    }
    const payment = res.rows[0];

    // If payment belongs to an appointment and succeeded, update appointment status to confirmed
    if (payment.appointment_id && status === 'success') {
      await client.query(
        "UPDATE appointments SET status = 'confirmed', updated_at = now() WHERE id = $1 AND status = 'pending'",
        [payment.appointment_id]
      );
      await client.query(
        `INSERT INTO appointment_status_history (appointment_id, old_status, new_status, note)
         VALUES ($1, 'pending', 'confirmed', 'Payment verified successfully.')`,
        [payment.appointment_id]
      );
    }

    await client.query('COMMIT');
    return payment;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

const getPaymentById = async (id) => {
  const res = await pool.query(
    `SELECT
       p.*,
       pat.full_name AS patient_name,
       r.id AS refund_id, r.amount AS refund_amount, r.status AS refund_status
     FROM payments p
     JOIN patients pat ON pat.id = p.patient_id
     LEFT JOIN refunds r ON r.payment_id = p.id
     WHERE p.id = $1`,
    [id]
  );
  if (res.rows.length === 0) {
    const err = new Error('Payment not found.');
    err.statusCode = 404;
    throw err;
  }
  return res.rows[0];
};

const requestRefund = async (paymentId, { amount, reason }) => {
  const paymentRes = await pool.query('SELECT amount, status FROM payments WHERE id = $1', [paymentId]);
  if (paymentRes.rows.length === 0) {
    const err = new Error('Payment not found.');
    err.statusCode = 404;
    throw err;
  }
  const payment = paymentRes.rows[0];

  const refundAmount = amount || payment.amount;
  const res = await pool.query(
    `INSERT INTO refunds (payment_id, amount, reason, status)
     VALUES ($1, $2, $3, 'requested')
     RETURNING *`,
    [paymentId, refundAmount, reason || null]
  );
  return res.rows[0];
};

module.exports = {
  initiatePayment,
  verifyPayment,
  getPaymentById,
  requestRefund,
};
