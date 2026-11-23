require('dotenv').config();
const http = require('http');
const express = require('express');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
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
const followupRoutes = require('./modules/followups/followup.routes');

// Chat System (Phase 2)
const conversationRoutes     = require('./modules/conversations/conversation.routes');
const convPrescriptionRoutes = require('./modules/conv-prescriptions/conv-prescription.routes');
const diagnosisRoutes        = require('./modules/diagnosis-results/diagnosis.routes');

// Health Analysis System (Phase 1)
const healthRoutes         = require('./modules/health/health.routes');
const healthAnalysisRoutes = require('./modules/health-analysis/analysis.routes');
const aiRoutes             = require('./modules/ai/ai.routes');

const { sendSuccess, sendError } = require('./utils/response');

const app = express();
const PORT = process.env.PORT || 5000;
const httpServer = http.createServer(app);

// ---------------------------------------------------------------------------
// Socket.IO setup with JWT auth
// ---------------------------------------------------------------------------
const io = new Server(httpServer, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
});

// Auth middleware for Socket.IO
io.use((socket, next) => {
  const token = socket.handshake.auth?.token;
  if (!token) return next(new Error('Authentication required.'));
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.user = decoded; // { id, role, phone }
    next();
  } catch {
    next(new Error('Invalid token.'));
  }
});

// Socket event handlers
io.on('connection', (socket) => {
  const { id: userId, role } = socket.user;

  // Join a conversation room (after verifying access)
  socket.on('join_conversation', async ({ conversationId }) => {
    try {
      const r = await pool.query(
        `SELECT c.*, d.user_id AS doctor_user_id, pat.user_id AS patient_user_id
         FROM conversations c
         JOIN doctors d ON d.id = c.doctor_id
         JOIN patients pat ON pat.id = c.patient_id
         WHERE c.id = $1`,
        [conversationId]
      );
      if (!r.rows.length) return socket.emit('error', { message: 'Conversation not found.' });
      const conv = r.rows[0];
      if (conv.doctor_user_id !== userId && conv.patient_user_id !== userId) {
        return socket.emit('error', { message: 'Access denied.' });
      }
      socket.join(`conv_${conversationId}`);
      socket.emit('joined', { conversationId });
    } catch (err) {
      socket.emit('error', { message: err.message });
    }
  });

  // Send a text message via socket (persists to DB + broadcasts)
  socket.on('send_message', async ({ conversationId, content }) => {
    try {
      if (!content || !content.trim()) return;
      const r = await pool.query(
        `INSERT INTO messages (conversation_id, sender_id, sender_role, message_type, message_content)
         VALUES ($1, $2, $3, 'text', $4) RETURNING *`,
        [conversationId, userId, role, content.trim()]
      );
      const msg = r.rows[0];
      const nameRow = role === 'doctor'
        ? await pool.query('SELECT full_name FROM doctors WHERE user_id = $1', [userId])
        : await pool.query('SELECT full_name FROM patients WHERE user_id = $1', [userId]);
      msg.sender_name = nameRow.rows[0]?.full_name ?? '';
      io.to(`conv_${conversationId}`).emit('new_message', msg);
    } catch (err) {
      socket.emit('error', { message: err.message });
    }
  });

  socket.on('disconnect', () => {});
});

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

// Root endpoint info
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'SwasthyaSathi Backend API is running.',
    api_docs: 'Endpoints are mounted under /api/v1',
    frontend_url: 'http://localhost:3000',
  });
});

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

// 13. Follow-ups
app.use('/api/v1/follow-ups', followupRoutes);

// 14. Health Data (BP, Glucose, Weight, Symptoms, Conditions, Medications)
app.use('/api/v1/health', healthRoutes);

// 15. Health Analysis (Orchestration + Clinical Rules)
app.use('/api/v1/health-analysis', healthAnalysisRoutes);

// 16. AI (LLM Explanation + Conversations)
app.use('/api/v1/ai', aiRoutes);

// 17. Chat System (Conversations, Conv-Prescriptions, Diagnosis Results)
app.use('/api/v1/conversations',      conversationRoutes);
app.use('/api/v1/conv-prescriptions', convPrescriptionRoutes);
app.use('/api/v1/diagnosis-results',  diagnosisRoutes);

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
// Start server (use httpServer for Socket.IO)
// ---------------------------------------------------------------------------
httpServer.listen(PORT, '0.0.0.0', () => {
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
  console.log('   • /api/v1/admins');
  console.log('   • /api/v1/health        (BP, Glucose, Weight, Conditions, Medications)');
  console.log('   • /api/v1/health-analysis (Analysis Orchestration)');
  console.log('   • /api/v1/ai            (LLM Explanation + Chat)\n');
});