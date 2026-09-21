-- Enable UUID generator (PostgreSQL 13+ has gen_random_uuid() natively)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Patients Table
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

-- Doctors Table
CREATE TABLE IF NOT EXISTS doctors (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    full_name               VARCHAR(150) NOT NULL,
    nmc_registration_number VARCHAR(50)  NOT NULL UNIQUE,
    nmc_status              verification_status NOT NULL DEFAULT 'pending',
    nmc_verified_at         TIMESTAMPTZ,
    experience_years        INTEGER NOT NULL DEFAULT 0,
    consultation_fee        NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    bio                     TEXT,
    is_available            BOOLEAN NOT NULL DEFAULT true,
    average_rating          NUMERIC(3, 2) NOT NULL DEFAULT 0.00,
    profile_photo_url       TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Doctor Specializations Join Table
CREATE TABLE IF NOT EXISTS doctor_specializations (
    id                SERIAL PRIMARY KEY,
    doctor_id         UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    specialization_id INTEGER NOT NULL REFERENCES specializations(id) ON DELETE CASCADE,
    is_primary        BOOLEAN NOT NULL DEFAULT false,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(doctor_id, specialization_id)
);

-- Facilities Table
CREATE TABLE IF NOT EXISTS facilities (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(200) NOT NULL,
    type            facility_type NOT NULL DEFAULT 'clinic',
    municipality_id INTEGER REFERENCES municipalities(id) ON DELETE SET NULL,
    ward_no         VARCHAR(10),
    address_line    VARCHAR(255),
    contact_phone   VARCHAR(20),
    email           VARCHAR(100),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Doctor Facilities Join Table
CREATE TABLE IF NOT EXISTS doctor_facilities (
    id          SERIAL PRIMARY KEY,
    doctor_id   UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    facility_id INTEGER NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(doctor_id, facility_id)
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_patients_user_id ON patients(user_id);
CREATE INDEX IF NOT EXISTS idx_doctors_user_id ON doctors(user_id);
CREATE INDEX IF NOT EXISTS idx_doctors_nmc_status ON doctors(nmc_status);
CREATE INDEX IF NOT EXISTS idx_doctor_specializations_doctor_id ON doctor_specializations(doctor_id);
CREATE INDEX IF NOT EXISTS idx_doctor_specializations_spec_id ON doctor_specializations(specialization_id);
