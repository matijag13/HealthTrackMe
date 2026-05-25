-- Flyway migration V5: extend health_entries and users with vitals and profile fields

ALTER TABLE health_entries
    ADD COLUMN weight DOUBLE PRECISION,
    ADD COLUMN heart_rate INTEGER,
    ADD COLUMN systolic_bp INTEGER,
    ADD COLUMN diastolic_bp INTEGER,
    ADD COLUMN blood_glucose DOUBLE PRECISION,
    ADD COLUMN body_temperature DOUBLE PRECISION,
    ADD COLUMN spo2 INTEGER,
    ADD COLUMN water_intake_ml INTEGER,
    ADD COLUMN calories_consumed INTEGER,
    ADD COLUMN alcohol_units DOUBLE PRECISION,
    ADD COLUMN pain_level INTEGER,
    ADD COLUMN bedtime TIME,
    ADD COLUMN wake_time TIME,
    ADD COLUMN sleep_quality_stars INTEGER,
    ADD COLUMN tags TEXT;

ALTER TABLE users
    ADD COLUMN height DOUBLE PRECISION,
    ADD COLUMN weight DOUBLE PRECISION,
    ADD COLUMN blood_type VARCHAR(20),
    ADD COLUMN emergency_contact_name VARCHAR(200),
    ADD COLUMN emergency_contact_phone VARCHAR(100),
    ADD COLUMN chronic_conditions TEXT,
    ADD COLUMN past_surgeries TEXT,
    ADD COLUMN family_history TEXT,
    ADD COLUMN vaccinations TEXT,
    ADD COLUMN organ_donor BOOLEAN,
    ADD COLUMN doctor_name VARCHAR(200),
    ADD COLUMN doctor_clinic VARCHAR(255),
    ADD COLUMN doctor_phone VARCHAR(100),
    ADD COLUMN insurance_provider VARCHAR(255),
    ADD COLUMN insurance_policy_number VARCHAR(255),
    ADD COLUMN profile_photo_base64 TEXT;

