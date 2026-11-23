-- =============================================================================
-- Migration 002: Persistent Doctor–Patient Chat System
-- Creates: conversations, messages, conv_prescriptions,
--          conv_prescription_medicines, diagnosis_results
-- Does NOT touch existing tables (chat_messages, prescriptions, etc.)
-- =============================================================================

-- 1. Conversations — a unique doctor+patient chat channel
CREATE TABLE IF NOT EXISTS conversations (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id  UUID NOT NULL REFERENCES doctors(id)  ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(doctor_id, patient_id)
);
CREATE INDEX IF NOT EXISTS idx_conversations_doctor  ON conversations(doctor_id);
CREATE INDEX IF NOT EXISTS idx_conversations_patient ON conversations(patient_id);

-- Auto-update updated_at on new messages
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE conversations SET updated_at = now() WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$;

-- 2. Messages — supports text, prescription card, diagnosis card
CREATE TABLE IF NOT EXISTS messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id       UUID NOT NULL REFERENCES users(id)         ON DELETE CASCADE,
  sender_role     user_role NOT NULL,
  message_type    VARCHAR(20) NOT NULL DEFAULT 'text'
                  CHECK (message_type IN ('text', 'prescription', 'diagnosis')),
  message_content TEXT,
  reference_id    UUID,          -- FK to conv_prescriptions.id or diagnosis_results.id
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_messages_conv_created ON messages(conversation_id, created_at);

DROP TRIGGER IF EXISTS trg_update_conv_ts ON messages;
CREATE TRIGGER trg_update_conv_ts
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION update_conversation_timestamp();

-- 3. Conv Prescriptions (separate from consultation-based prescriptions)
CREATE TABLE IF NOT EXISTS conv_prescriptions (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id        UUID NOT NULL REFERENCES conversations(id)  ON DELETE CASCADE,
  doctor_id              UUID NOT NULL REFERENCES doctors(id)        ON DELETE RESTRICT,
  patient_id             UUID NOT NULL REFERENCES patients(id)       ON DELETE RESTRICT,
  title                  VARCHAR(200),
  additional_instructions TEXT,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_conv_rx_patient ON conv_prescriptions(patient_id);
CREATE INDEX IF NOT EXISTS idx_conv_rx_conv    ON conv_prescriptions(conversation_id);

-- 4. Medicines for conv prescriptions
CREATE TABLE IF NOT EXISTS conv_prescription_medicines (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_id UUID NOT NULL REFERENCES conv_prescriptions(id) ON DELETE CASCADE,
  medicine_name   VARCHAR(200) NOT NULL,
  dosage          VARCHAR(100),
  frequency       VARCHAR(100),
  duration        VARCHAR(100),
  instructions    TEXT
);

-- 5. Diagnosis Results
CREATE TABLE IF NOT EXISTS diagnosis_results (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id       UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  doctor_id             UUID NOT NULL REFERENCES doctors(id)       ON DELETE RESTRICT,
  patient_id            UUID NOT NULL REFERENCES patients(id)      ON DELETE RESTRICT,
  title                 VARCHAR(200) NOT NULL,
  description           TEXT,
  findings              TEXT,
  recommended_treatment TEXT,
  additional_notes      TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_diagnosis_patient ON diagnosis_results(patient_id);
CREATE INDEX IF NOT EXISTS idx_diagnosis_conv    ON diagnosis_results(conversation_id);
