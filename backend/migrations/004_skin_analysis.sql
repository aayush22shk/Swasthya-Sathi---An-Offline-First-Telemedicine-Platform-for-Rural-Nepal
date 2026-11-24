-- =============================================================================
-- Migration 004: AI Skin Disease Detection Schema
-- Stores on-device or uploaded skin analysis results, confidence, top predictions,
-- and doctor review / authorization sharing.
-- =============================================================================

CREATE TABLE IF NOT EXISTS skin_analyses (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id            UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  image_url             TEXT NOT NULL,
  predicted_condition   VARCHAR(100) NOT NULL,
  confidence_score      NUMERIC(5, 4) NOT NULL,
  top_predictions       JSONB NOT NULL DEFAULT '[]',
  is_uncertain          BOOLEAN NOT NULL DEFAULT false,
  uncertainty_reason    TEXT,
  model_version         VARCHAR(50) NOT NULL DEFAULT 'mobilenetv3_nepal_v1',
  is_shared_with_doctor BOOLEAN NOT NULL DEFAULT false,
  doctor_id             UUID REFERENCES doctors(id) ON DELETE SET NULL,
  doctor_notes          TEXT,
  reviewed_at           TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_skin_analyses_patient ON skin_analyses(patient_id);
CREATE INDEX IF NOT EXISTS idx_skin_analyses_doctor  ON skin_analyses(doctor_id);
CREATE INDEX IF NOT EXISTS idx_skin_analyses_shared  ON skin_analyses(is_shared_with_doctor);
CREATE INDEX IF NOT EXISTS idx_skin_analyses_created ON skin_analyses(created_at DESC);
