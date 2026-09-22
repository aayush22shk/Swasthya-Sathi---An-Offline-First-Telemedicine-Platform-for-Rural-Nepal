-- =====================================================================
-- SWASTHYASATHI DATABASE SCHEMA
-- An Offline-First Telemedicine Platform for Rural Nepal
-- =====================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================================
-- ENUM TYPES (Safe idempotent creation)
-- =====================================================================

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('patient', 'doctor', 'admin');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_status') THEN
        CREATE TYPE user_status AS ENUM ('active', 'suspended', 'deactivated');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'language_pref') THEN
        CREATE TYPE language_pref AS ENUM ('ne', 'en');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'gender_type') THEN
        CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'verification_status') THEN
        CREATE TYPE verification_status AS ENUM ('pending', 'verified', 'rejected');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'facility_type') THEN
        CREATE TYPE facility_type AS ENUM ('hospital', 'clinic', 'diagnostic_center');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'weekday_type') THEN
        CREATE TYPE weekday_type AS ENUM ('sun','mon','tue','wed','thu','fri','sat');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'consultation_mode') THEN
        CREATE TYPE consultation_mode AS ENUM ('video', 'audio', 'chat', 'in_person');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'appointment_status') THEN
        CREATE TYPE appointment_status AS ENUM ('pending', 'confirmed', 'completed', 'cancelled', 'no_show');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'prescription_item_route') THEN
        CREATE TYPE prescription_item_route AS ENUM ('oral', 'topical', 'injection', 'other');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'pharmacy_order_status') THEN
        CREATE TYPE pharmacy_order_status AS ENUM ('placed', 'processing', 'out_for_delivery', 'delivered', 'cancelled');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
        CREATE TYPE payment_status AS ENUM ('pending', 'success', 'failed', 'refunded');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'otp_purpose') THEN
        CREATE TYPE otp_purpose AS ENUM ('signup', 'login', 'password_reset');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'device_platform') THEN
        CREATE TYPE device_platform AS ENUM ('android', 'ios', 'web');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'admin_permission_level') THEN
        CREATE TYPE admin_permission_level AS ENUM ('super_admin', 'support_admin', 'content_admin');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'refund_status') THEN
        CREATE TYPE refund_status AS ENUM ('requested', 'approved', 'rejected', 'processed');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_gateway') THEN
        CREATE TYPE payment_gateway AS ENUM ('esewa', 'khalti', 'ime_pay', 'connectips', 'card', 'cash');
    END IF;
END $$;

-- =====================================================================
-- 1. LOCATION & MASTER DATA
-- =====================================================================

CREATE TABLE IF NOT EXISTS provinces (
    id          SMALLSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS districts (
    id          SERIAL PRIMARY KEY,
    province_id SMALLINT NOT NULL REFERENCES provinces(id) ON DELETE RESTRICT,
    name        VARCHAR(100) NOT NULL,
    UNIQUE (province_id, name)
);

CREATE TABLE IF NOT EXISTS municipalities (
    id          SERIAL PRIMARY KEY,
    district_id INTEGER NOT NULL REFERENCES districts(id) ON DELETE RESTRICT,
    name        VARCHAR(150) NOT NULL,
    UNIQUE (district_id, name)
);
 
CREATE TABLE IF NOT EXISTS specializations (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);
 
CREATE TABLE IF NOT EXISTS languages (
    id          SMALLSERIAL PRIMARY KEY,
    code        VARCHAR(10) NOT NULL UNIQUE,
    name        VARCHAR(50) NOT NULL
);

-- =====================================================================
-- 2. IDENTITY & ACCESS
-- =====================================================================

CREATE TABLE IF NOT EXISTS users (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone              VARCHAR(20) NOT NULL UNIQUE,
    email              VARCHAR(255) UNIQUE,
    password_hash      TEXT NOT NULL,
    role               user_role NOT NULL,
    preferred_language language_pref NOT NULL DEFAULT 'en',
    status             user_status NOT NULL DEFAULT 'active',
    phone_verified_at  TIMESTAMPTZ,
    email_verified_at  TIMESTAMPTZ,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
 
CREATE TABLE IF NOT EXISTS otp_verifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
    phone       VARCHAR(20) NOT NULL,
    otp_code    VARCHAR(10) NOT NULL,
    purpose     otp_purpose NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);	

CREATE INDEX IF NOT EXISTS idx_otp_phone ON otp_verifications(phone);
 
CREATE TABLE IF NOT EXISTS devices (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_token   TEXT NOT NULL,
    platform       device_platform NOT NULL,
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, device_token)
);

-- =====================================================================
-- 3. PATIENT & DOCTOR PROFILES
-- =====================================================================

CREATE TABLE IF NOT EXISTS patients (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    full_name               VARCHAR(150) NOT NULL,
    dob                     DATE,
    gender                  gender_type,
    blood_group             VARCHAR(5),
    municipality_id         INTEGER REFERENCES municipalities(id) ON DELETE SET NULL,
    ward_no                 VARCHAR(10),
    address_line            VARCHAR(255),
    emergency_contact_name  VARCHAR(150),
    emergency_contact_phone VARCHAR(20),
    profile_photo_url       TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_patients_user_id ON patients(user_id);

CREATE TABLE IF NOT EXISTS doctors (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    full_name               VARCHAR(150) NOT NULL,
    nmc_registration_number VARCHAR(50) NOT NULL UNIQUE,
    nmc_status              verification_status NOT NULL DEFAULT 'pending',
    nmc_verified_at         TIMESTAMPTZ,
    experience_years        SMALLINT DEFAULT 0,
    consultation_fee        NUMERIC(10,2) NOT NULL DEFAULT 0,
    bio                     TEXT,
    profile_photo_url       TEXT,
    is_available            BOOLEAN NOT NULL DEFAULT true,
    average_rating          NUMERIC(3,2) DEFAULT 0,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE INDEX IF NOT EXISTS idx_doctors_user_id ON doctors(user_id);
CREATE INDEX IF NOT EXISTS idx_doctors_nmc_status ON doctors(nmc_status);
CREATE INDEX IF NOT EXISTS idx_doctors_available ON doctors(is_available);

CREATE TABLE IF NOT EXISTS doctor_qualifications (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id      UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    degree         VARCHAR(100) NOT NULL,
    institution    VARCHAR(200) NOT NULL,
    country        VARCHAR(100),
    year_completed SMALLINT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE TABLE IF NOT EXISTS doctor_documents (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id     UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL,
    file_url      TEXT NOT NULL,
    status        verification_status NOT NULL DEFAULT 'pending',
    uploaded_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE TABLE IF NOT EXISTS doctor_verifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id   UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    result      verification_status NOT NULL,
    notes       TEXT,
    verified_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE TABLE IF NOT EXISTS doctor_specializations (
    doctor_id         UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    specialization_id INTEGER NOT NULL REFERENCES specializations(id) ON DELETE CASCADE,
    PRIMARY KEY (doctor_id, specialization_id)
);
 
CREATE TABLE IF NOT EXISTS doctor_languages (
    doctor_id   UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    language_id SMALLINT NOT NULL REFERENCES languages(id) ON DELETE CASCADE,
    PRIMARY KEY (doctor_id, language_id)
);
 
CREATE TABLE IF NOT EXISTS facilities (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(200) NOT NULL,
    type            facility_type NOT NULL,
    municipality_id INTEGER REFERENCES municipalities(id) ON DELETE SET NULL,
    address_line    VARCHAR(255),
    contact_phone   VARCHAR(20),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE TABLE IF NOT EXISTS doctor_facilities (
    doctor_id   UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
    PRIMARY KEY (doctor_id, facility_id)
);
 
-- =====================================================================
-- 4. SCHEDULING & AVAILABILITY
-- =====================================================================
 
CREATE TABLE IF NOT EXISTS doctor_availability (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id             UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    day_of_week           weekday_type NOT NULL,
    start_time            TIME NOT NULL,
    end_time              TIME NOT NULL,
    slot_duration_minutes SMALLINT NOT NULL DEFAULT 15,
    is_active             BOOLEAN NOT NULL DEFAULT true,
    CHECK (end_time > start_time)
);
 
CREATE INDEX IF NOT EXISTS idx_doctor_availability_doctor ON doctor_availability(doctor_id);
 
CREATE TABLE IF NOT EXISTS doctor_time_off (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id   UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    start_at    TIMESTAMPTZ NOT NULL,
    end_at      TIMESTAMPTZ NOT NULL,
    reason      VARCHAR(255),
    CHECK (end_at > start_at)
);
 
-- =====================================================================
-- 5. APPOINTMENTS
-- =====================================================================
 
CREATE TABLE IF NOT EXISTS appointments (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id       UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    doctor_id        UUID NOT NULL REFERENCES doctors(id) ON DELETE RESTRICT,
    scheduled_at     TIMESTAMPTZ NOT NULL,
    mode             consultation_mode NOT NULL DEFAULT 'video',
    status           appointment_status NOT NULL DEFAULT 'pending',
    fee              NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    reason_for_visit TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE INDEX IF NOT EXISTS idx_appointments_patient ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor  ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_status  ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_scheduled_at ON appointments(scheduled_at);
 
CREATE TABLE IF NOT EXISTS appointment_status_history (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
    old_status     appointment_status,
    new_status     appointment_status NOT NULL,
    changed_by     UUID REFERENCES users(id) ON DELETE SET NULL,
    changed_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    note           VARCHAR(255)
);
 
-- =====================================================================
-- 6. CONSULTATIONS & MEDICAL DATA
-- =====================================================================
 
CREATE TABLE IF NOT EXISTS consultations (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID NOT NULL UNIQUE REFERENCES appointments(id) ON DELETE CASCADE,
    video_room_id  VARCHAR(150),
    started_at     TIMESTAMPTZ,
    ended_at       TIMESTAMPTZ,
    doctor_notes   TEXT,
    diagnosis      TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE TABLE IF NOT EXISTS chat_messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consultation_id UUID NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message         TEXT,
    attachment_url  TEXT,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE INDEX IF NOT EXISTS idx_chat_messages_consultation ON chat_messages(consultation_id);
 
CREATE TABLE IF NOT EXISTS medical_records (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id  UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    record_type VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE TABLE IF NOT EXISTS lab_reports (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id  UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    uploaded_by UUID REFERENCES users(id) ON DELETE SET NULL,
    report_type VARCHAR(100),
    file_url    TEXT NOT NULL,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE TABLE IF NOT EXISTS vitals (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id   UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    systolic_bp  SMALLINT,
    diastolic_bp SMALLINT,
    blood_sugar  NUMERIC(5,2),
    weight_kg    NUMERIC(5,2),
    recorded_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
-- =====================================================================
-- 7. PRESCRIPTIONS & PHARMACY
-- =====================================================================
 
CREATE TABLE IF NOT EXISTS prescriptions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consultation_id UUID NOT NULL UNIQUE REFERENCES consultations(id) ON DELETE CASCADE,
    doctor_id       UUID NOT NULL REFERENCES doctors(id) ON DELETE RESTRICT,
    patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
    issued_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes           TEXT
);
 
CREATE TABLE IF NOT EXISTS prescription_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    medicine_name   VARCHAR(200) NOT NULL,
    dosage          VARCHAR(100),
    route           prescription_item_route DEFAULT 'oral',
    frequency       VARCHAR(100),
    duration_days   SMALLINT,
    instructions    TEXT
);
 
CREATE TABLE IF NOT EXISTS pharmacies (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(200) NOT NULL,
    license_no      VARCHAR(50) NOT NULL UNIQUE,
    municipality_id INTEGER REFERENCES municipalities(id) ON DELETE SET NULL,
    address_line    VARCHAR(255),
    contact_phone   VARCHAR(20),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE TABLE IF NOT EXISTS pharmacy_orders (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id  UUID NOT NULL REFERENCES prescriptions(id) ON DELETE RESTRICT,
    pharmacy_id      UUID NOT NULL REFERENCES pharmacies(id) ON DELETE RESTRICT,
    patient_id       UUID NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
    status           pharmacy_order_status NOT NULL DEFAULT 'placed',
    delivery_address VARCHAR(255),
    total_amount     NUMERIC(10,2),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
-- =====================================================================
-- 8. PAYMENTS & REFUNDS
-- =====================================================================
 
CREATE TABLE IF NOT EXISTS payments (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id    UUID REFERENCES appointments(id) ON DELETE SET NULL,
    pharmacy_order_id UUID REFERENCES pharmacy_orders(id) ON DELETE SET NULL,
    patient_id        UUID NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
    amount            NUMERIC(10,2) NOT NULL,
    gateway           payment_gateway NOT NULL,
    gateway_txn_id    VARCHAR(150),
    status            payment_status NOT NULL DEFAULT 'pending',
    paid_at           TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (appointment_id IS NOT NULL OR pharmacy_order_id IS NOT NULL)
);
 
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_patient ON payments(patient_id);
 
CREATE TABLE IF NOT EXISTS refunds (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id   UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    amount       NUMERIC(10,2) NOT NULL,
    reason       VARCHAR(255),
    status       refund_status NOT NULL DEFAULT 'requested',
    processed_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
-- =====================================================================
-- 9. REVIEWS & NOTIFICATIONS
-- =====================================================================
 
CREATE TABLE IF NOT EXISTS reviews (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID NOT NULL UNIQUE REFERENCES appointments(id) ON DELETE CASCADE,
    patient_id     UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    doctor_id      UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    rating         SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment        TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE INDEX IF NOT EXISTS idx_reviews_doctor ON reviews(doctor_id);
 
CREATE TABLE IF NOT EXISTS notifications (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type       VARCHAR(50) NOT NULL,
    title      VARCHAR(150) NOT NULL,
    message    TEXT NOT NULL,
    is_read    BOOLEAN NOT NULL DEFAULT false,
    sent_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read);
 
-- =====================================================================
-- 10. ADMIN & AUDIT LOGS
-- =====================================================================
 
CREATE TABLE IF NOT EXISTS admins (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    permission_level admin_permission_level NOT NULL DEFAULT 'support_admin',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE TABLE IF NOT EXISTS audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES users(id) ON DELETE SET NULL,
    action      VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100),
    entity_id   UUID,
    metadata    JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
