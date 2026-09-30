-- =====================================================================
-- MIGRATION 001: Health Analysis System Schema
-- SwasthyaSathi — Health Analysis & AI Integration
-- Run this migration ONCE to add the health tracking subsystem.
-- All existing tables remain unchanged.
-- =====================================================================

BEGIN;

-- =====================================================================
-- PHASE 1A: Health Measurement Tables (Time-Series)
-- Replaces the generic `vitals` table with specialized time-series tables
-- =====================================================================

-- 1. Blood Pressure Readings
CREATE TABLE IF NOT EXISTS blood_pressure_readings (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id           UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    systolic             SMALLINT NOT NULL,
    diastolic            SMALLINT NOT NULL,
    heart_rate           SMALLINT,
    measured_at          TIMESTAMPTZ NOT NULL,
    measurement_context  VARCHAR(50) NOT NULL DEFAULT 'manual',
    source               VARCHAR(30) NOT NULL DEFAULT 'manual',
    device_id            UUID,
    notes                TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (systolic > 0),
    CHECK (diastolic > 0),
    CHECK (heart_rate IS NULL OR heart_rate > 0)
);

CREATE INDEX IF NOT EXISTS idx_bp_patient_date
    ON blood_pressure_readings(patient_id, measured_at DESC);

-- 2. Glucose Readings
CREATE TABLE IF NOT EXISTS glucose_readings (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id           UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    glucose_value        NUMERIC(6,2) NOT NULL,
    unit                 VARCHAR(10) NOT NULL DEFAULT 'mg/dl',
    measurement_type     VARCHAR(50) NOT NULL DEFAULT 'random',
    -- fasting | before_meal | after_meal | random | bedtime
    measured_at          TIMESTAMPTZ NOT NULL,
    source               VARCHAR(30) NOT NULL DEFAULT 'manual',
    device_id            UUID,
    notes                TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (glucose_value > 0)
);

CREATE INDEX IF NOT EXISTS idx_glucose_patient_date
    ON glucose_readings(patient_id, measured_at DESC);

-- 3. Weight Readings
CREATE TABLE IF NOT EXISTS weight_readings (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id   UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    weight_kg    NUMERIC(5,2) NOT NULL,
    measured_at  TIMESTAMPTZ NOT NULL,
    source       VARCHAR(30) NOT NULL DEFAULT 'manual',
    notes        TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (weight_kg > 0)
);

CREATE INDEX IF NOT EXISTS idx_weight_patient_date
    ON weight_readings(patient_id, measured_at DESC);

-- =====================================================================
-- PHASE 1B: Patient Health Context
-- =====================================================================

-- 4. Patient Conditions (Chronic conditions, diagnoses)
CREATE TABLE IF NOT EXISTS patient_conditions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    condition_name  VARCHAR(150) NOT NULL,
    condition_type  VARCHAR(100),
    diagnosis_date  DATE,
    status          VARCHAR(30) NOT NULL DEFAULT 'active',
    -- active | resolved | managed | suspected
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_conditions_patient
    ON patient_conditions(patient_id);

-- 5. Active Patient Medications
-- Complements (but does not replace) the prescriptions/prescription_items tables.
-- prescriptions = historical dispensing record
-- patient_medications = what the patient is currently taking
CREATE TABLE IF NOT EXISTS patient_medications (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id           UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    prescription_item_id UUID REFERENCES prescription_items(id) ON DELETE SET NULL,
    medicine_name        VARCHAR(200) NOT NULL,
    dosage               VARCHAR(100),
    route                prescription_item_route DEFAULT 'oral',
    frequency            VARCHAR(100),
    start_date           DATE NOT NULL,
    end_date             DATE,
    is_active            BOOLEAN NOT NULL DEFAULT true,
    instructions         TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_patient_medications_patient
    ON patient_medications(patient_id, is_active);

-- 6. Medication Adherence Events
CREATE TABLE IF NOT EXISTS medication_events (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    medication_id UUID NOT NULL REFERENCES patient_medications(id) ON DELETE CASCADE,
    scheduled_at  TIMESTAMPTZ NOT NULL,
    taken_at      TIMESTAMPTZ,
    status        VARCHAR(20) NOT NULL DEFAULT 'pending',
    -- pending | taken | missed | skipped
    notes         TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_medication_events_medication
    ON medication_events(medication_id);

-- 7. Symptom Records
CREATE TABLE IF NOT EXISTS symptom_records (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id    UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    symptom_name  VARCHAR(150) NOT NULL,
    severity      SMALLINT,
    started_at    TIMESTAMPTZ,
    ended_at      TIMESTAMPTZ,
    notes         TEXT,
    recorded_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (severity IS NULL OR severity BETWEEN 1 AND 10)
);

CREATE INDEX IF NOT EXISTS idx_symptoms_patient
    ON symptom_records(patient_id, recorded_at DESC);

-- =====================================================================
-- PHASE 2: Analysis & AI Tables
-- =====================================================================

-- 8. Health Analyses (versioned, reproducible analysis results)
CREATE TABLE IF NOT EXISTS health_analyses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    analysis_type   VARCHAR(50) NOT NULL DEFAULT 'comprehensive',
    -- comprehensive | blood_pressure | glucose | weight
    period_start    TIMESTAMPTZ NOT NULL,
    period_end      TIMESTAMPTZ NOT NULL,
    engine_version  VARCHAR(50),
    rule_version    VARCHAR(50),
    input_snapshot  JSONB,
    result          JSONB NOT NULL,
    generated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (period_end >= period_start)
);

CREATE INDEX IF NOT EXISTS idx_health_analyses_patient
    ON health_analyses(patient_id, generated_at DESC);

CREATE INDEX IF NOT EXISTS idx_health_analyses_type
    ON health_analyses(patient_id, analysis_type);

-- 9. AI Health Feedback (persists LLM explanation for auditability)
CREATE TABLE IF NOT EXISTS ai_health_feedback (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    analysis_id     UUID REFERENCES health_analyses(id) ON DELETE SET NULL,
    model_provider  VARCHAR(50),
    model_name      VARCHAR(100),
    prompt_version  VARCHAR(50),
    context         JSONB,
    response        JSONB,
    generated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_feedback_patient
    ON ai_health_feedback(patient_id, generated_at DESC);

-- 10. AI Conversations (for conversational health AI feature)
CREATE TABLE IF NOT EXISTS ai_conversations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id  UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    title       VARCHAR(200),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_conversations_patient
    ON ai_conversations(patient_id, updated_at DESC);

-- 11. AI Messages
CREATE TABLE IF NOT EXISTS ai_messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
    role            VARCHAR(20) NOT NULL,
    -- user | assistant | system
    content         TEXT NOT NULL,
    metadata        JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation
    ON ai_messages(conversation_id, created_at ASC);

COMMIT;

-- =====================================================================
-- VERIFICATION QUERY (run to confirm tables were created)
-- =====================================================================
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public'
-- AND table_name IN (
--   'blood_pressure_readings','glucose_readings','weight_readings',
--   'patient_conditions','patient_medications','medication_events',
--   'symptom_records','health_analyses','ai_health_feedback',
--   'ai_conversations','ai_messages'
-- )
-- ORDER BY table_name;
