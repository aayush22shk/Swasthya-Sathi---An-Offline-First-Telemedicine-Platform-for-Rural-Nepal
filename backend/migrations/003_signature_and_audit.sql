-- =============================================================================
-- Migration 003: Signature Hash for Prescriptions & Audit Integrity
-- =============================================================================

ALTER TABLE conv_prescriptions 
ADD COLUMN IF NOT EXISTS signature_hash VARCHAR(64);

CREATE INDEX IF NOT EXISTS idx_conv_rx_sig ON conv_prescriptions(signature_hash);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id);
