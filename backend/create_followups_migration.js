const pool = require('./db');

async function migrate() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS follow_ups (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
        patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
        consultation_id UUID REFERENCES consultations(id) ON DELETE SET NULL,
        appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
        follow_up_date DATE NOT NULL,
        notes TEXT,
        status VARCHAR(20) NOT NULL DEFAULT 'upcoming',
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );
      CREATE INDEX IF NOT EXISTS idx_follow_ups_doctor ON follow_ups(doctor_id);
      CREATE INDEX IF NOT EXISTS idx_follow_ups_patient ON follow_ups(patient_id);
      CREATE INDEX IF NOT EXISTS idx_follow_ups_status ON follow_ups(status);
    `);
    console.log('Follow-ups table migration completed successfully.');
    process.exit(0);
  } catch (err) {
    console.error('Migration failed:', err);
    process.exit(1);
  }
}

migrate();
