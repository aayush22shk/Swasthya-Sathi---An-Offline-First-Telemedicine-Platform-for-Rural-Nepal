const pool = require('../../db');

const getProvinces = async () => {
  const res = await pool.query('SELECT id, name FROM provinces ORDER BY id ASC');
  return res.rows;
};

const getDistricts = async (provinceId) => {
  const query = provinceId
    ? 'SELECT id, province_id, name FROM districts WHERE province_id = $1 ORDER BY name ASC'
    : 'SELECT id, province_id, name FROM districts ORDER BY name ASC';
  const params = provinceId ? [provinceId] : [];
  const res = await pool.query(query, params);
  return res.rows;
};

const getMunicipalities = async (districtId) => {
  const query = districtId
    ? 'SELECT id, district_id, name FROM municipalities WHERE district_id = $1 ORDER BY name ASC'
    : 'SELECT id, district_id, name FROM municipalities ORDER BY name ASC';
  const params = districtId ? [districtId] : [];
  const res = await pool.query(query, params);
  return res.rows;
};

const getSpecializations = async () => {
  const res = await pool.query('SELECT id, name, description FROM specializations ORDER BY name ASC');
  return res.rows;
};

const createSpecialization = async ({ name, description }) => {
  const res = await pool.query(
    'INSERT INTO specializations (name, description) VALUES ($1, $2) RETURNING *',
    [name, description || null]
  );
  return res.rows[0];
};

const getLanguages = async () => {
  const res = await pool.query('SELECT id, code, name FROM languages ORDER BY name ASC');
  return res.rows;
};

module.exports = {
  getProvinces,
  getDistricts,
  getMunicipalities,
  getSpecializations,
  createSpecialization,
  getLanguages,
};
