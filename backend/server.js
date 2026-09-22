require('dotenv').config();
const express = require('express');
const pool = require('./db');

// Route modules
const authRoutes = require('./modules/auth/auth.routes');
const patientRoutes = require('./modules/patients/patient.routes');
const doctorRoutes = require('./modules/doctors/doctor.routes');
const mastersRoutes = require('./modules/masters/masters.routes');
const schedulingRoutes = require('./modules/scheduling/scheduling.routes');
const appointmentRoutes = require('./modules/appointments/appointment.routes');
const consultationRoutes = require('./modules/consultations/consultation.routes');
const recordsRoutes = require('./modules/records/records.routes');
const prescriptionRoutes = require('./modules/prescriptions/prescription.routes');
const pharmacyRoutes = require('./modules/pharmacy/pharmacy.routes');
const paymentRoutes = require('./modules/payments/payment.routes');
const feedbackRoutes = require('./modules/feedback/feedback.routes');
const adminRoutes = require('./modules/admin/admin.routes');

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
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
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

// 1. Auth routes (public)
app.use('/api/v1/auth', authRoutes);

// 2. Patient & Doctor Profile CRUD
app.use('/api/v1/patients', patientRoutes);
app.use('/api/v1/doctors', doctorRoutes);

// 3. Location & Masters Data
app.use('/api/v1/masters', mastersRoutes);

// 4. Scheduling & Availability
app.use('/api/v1/scheduling', schedulingRoutes);

// 5. Appointments & Status History
app.use('/api/v1/appointments', appointmentRoutes);

// 6. Consultations & In-call Chat
app.use('/api/v1/consultations', consultationRoutes);

// 7. Medical Records, Vitals & Lab Reports
app.use('/api/v1/records', recordsRoutes);

// 8. Prescriptions & Prescription Items
app.use('/api/v1/prescriptions', prescriptionRoutes);

// 9. Pharmacies & Pharmacy Orders
app.use('/api/v1/pharmacies', pharmacyRoutes);

// 10. Payments & Refunds
app.use('/api/v1/payments', paymentRoutes);

// 11. Feedback (Reviews & Notifications)
app.use('/api/v1/feedback', feedbackRoutes);

// 12. Admin & Audit Logs
app.use('/api/v1/admins', adminRoutes);

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
  console.log('   Mounted Endpoints:');
  console.log('   • /api/v1/health');
  console.log('   • /api/v1/auth');
  console.log('   • /api/v1/patients');
  console.log('   • /api/v1/doctors');
  console.log('   • /api/v1/masters');
  console.log('   • /api/v1/scheduling');
  console.log('   • /api/v1/appointments');
  console.log('   • /api/v1/consultations');
  console.log('   • /api/v1/records');
  console.log('   • /api/v1/prescriptions');
  console.log('   • /api/v1/pharmacies');
  console.log('   • /api/v1/payments');
  console.log('   • /api/v1/feedback');
  console.log('   • /api/v1/admins\n');
});