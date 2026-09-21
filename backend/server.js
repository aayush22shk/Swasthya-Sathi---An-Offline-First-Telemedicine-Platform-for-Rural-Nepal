require('dotenv').config();
const express = require('express');
const pool = require('./db'); // Imports and runs connection test

// Route modules
const authRoutes = require('./modules/auth/auth.routes');
const patientRoutes = require('./modules/patients/patient.routes');
const doctorRoutes = require('./modules/doctors/doctor.routes');

const { sendSuccess, sendError } = require('./utils/response');

const app = express();
const PORT = process.env.PORT || 5000;

// ---------------------------------------------------------------------------
// Global middlewares
// ---------------------------------------------------------------------------
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// CORS – allow Flutter web / mobile origins in development
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

// Health check
app.get('/api/v1/health', (req, res) => {
  sendSuccess(res, 200, 'SwasthyaSathi API is healthy.', {
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// Database connectivity check
app.get('/api/v1/db-test', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() AS time');
    sendSuccess(res, 200, 'Database connection OK.', { db_time: result.rows[0].time });
  } catch (err) {
    console.error('DB test error:', err);
    sendError(res, 500, 'Database connection failed.');
  }
});

// Auth routes (public)
app.use('/api/v1/auth', authRoutes);

// Patient CRUD (protected – JWT required inside router)
app.use('/api/v1/patients', patientRoutes);

// Doctor CRUD (public list; protected CUD – JWT required inside router)
app.use('/api/v1/doctors', doctorRoutes);

// ---------------------------------------------------------------------------
// 404 handler
// ---------------------------------------------------------------------------
app.use((req, res) => {
  sendError(res, 404, `Route ${req.method} ${req.originalUrl} not found.`);
});

// ---------------------------------------------------------------------------
// Global error handler
// ---------------------------------------------------------------------------
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  sendError(res, err.status || 500, err.message || 'Internal Server Error');
});

// ---------------------------------------------------------------------------
// Start server
// ---------------------------------------------------------------------------
app.listen(PORT, () => {
  console.log(`\n🚀 SwasthyaSathi API running → http://localhost:${PORT}`);
  console.log(`   Health  : GET  /api/v1/health`);
  console.log(`   Auth    : POST /api/v1/auth/register/patient`);
  console.log(`   Auth    : POST /api/v1/auth/register/doctor`);
  console.log(`   Auth    : POST /api/v1/auth/login`);
  console.log(`   Patients: GET|PUT|DELETE /api/v1/patients/:id`);
  console.log(`   Doctors : GET|PUT|DELETE /api/v1/doctors/:id\n`);
});