const pool = require('../../db');

const listAdmins = async () => {
  const res = await pool.query(
    `SELECT a.id, a.user_id, a.permission_level, a.created_at, u.phone, u.email, u.status
     FROM admins a
     JOIN users u ON u.id = a.user_id
     ORDER BY a.created_at DESC`
  );
  return res.rows;
};

const assignAdmin = async ({ user_id, permission_level = 'support_admin' }) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Update user role to admin
    await client.query("UPDATE users SET role = 'admin', updated_at = now() WHERE id = $1", [user_id]);

    const res = await client.query(
      `INSERT INTO admins (user_id, permission_level)
       VALUES ($1, $2)
       ON CONFLICT (user_id) DO UPDATE SET permission_level = $2
       RETURNING *`,
      [user_id, permission_level]
    );

    await client.query('COMMIT');
    return res.rows[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

const getAuditLogs = async ({ entity_type, limit = 100, offset = 0 } = {}) => {
  const query = entity_type
    ? `SELECT al.*, u.phone AS user_phone, u.role AS user_role
       FROM audit_logs al
       LEFT JOIN users u ON u.id = al.user_id
       WHERE al.entity_type = $1
       ORDER BY al.created_at DESC LIMIT $2 OFFSET $3`
    : `SELECT al.*, u.phone AS user_phone, u.role AS user_role
       FROM audit_logs al
       LEFT JOIN users u ON u.id = al.user_id
       ORDER BY al.created_at DESC LIMIT $1 OFFSET $2`;
  const params = entity_type ? [entity_type, limit, offset] : [limit, offset];
  const res = await pool.query(query, params);
  return res.rows;
};

const logAudit = async ({ user_id, action, entity_type, entity_id, metadata }) => {
  const res = await pool.query(
    `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, metadata)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [user_id || null, action, entity_type || null, entity_id || null, metadata ? JSON.stringify(metadata) : null]
  );
  return res.rows[0];
};

module.exports = {
  listAdmins,
  assignAdmin,
  getAuditLogs,
  logAudit,
};
