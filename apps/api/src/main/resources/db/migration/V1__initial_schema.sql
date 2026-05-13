CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(30) NOT NULL,
    gdpr_consent_accepted BOOLEAN NOT NULL DEFAULT FALSE,
    gdpr_consent_accepted_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Legacy compatibility columns for current service layer
    date_of_birth VARCHAR(50) NOT NULL DEFAULT '',
    user_type VARCHAR(50) NOT NULL DEFAULT 'PATIENT',
    medical_conditions TEXT,
    allergies TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS health_entries (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    entry_date DATE NOT NULL,
    wellbeing_score INTEGER NOT NULL,
    energy_level INTEGER,
    stress_level INTEGER,
    mood VARCHAR(100),
    symptoms TEXT,
    doctor_notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Legacy compatibility columns for current service layer
    sleep_hours DOUBLE PRECISION,
    sleep_quality VARCHAR(50),

    CONSTRAINT fk_health_entries_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT ck_health_entries_wellbeing CHECK (wellbeing_score BETWEEN 1 AND 10)
);

CREATE TABLE IF NOT EXISTS medications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    dosage VARCHAR(255) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    instructions TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_medications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS dose_logs (
    id BIGSERIAL PRIMARY KEY,
    medication_id BIGINT NOT NULL,
    scheduled_time TIMESTAMP NOT NULL,
    taken_time TIMESTAMP,
    status VARCHAR(20) NOT NULL,
    note TEXT,
    CONSTRAINT fk_dose_logs_medication FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS sleep_records (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    sleep_date DATE NOT NULL,
    duration_minutes INTEGER NOT NULL,
    quality_score INTEGER,
    source VARCHAR(100),
    CONSTRAINT fk_sleep_records_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS activity_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    activity_date DATE NOT NULL,
    steps INTEGER,
    calories INTEGER,
    heart_rate_avg INTEGER,
    source VARCHAR(100),
    CONSTRAINT fk_activity_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_users_email ON users(email);
CREATE INDEX IF NOT EXISTS ix_health_entries_user_date ON health_entries(user_id, entry_date);
CREATE INDEX IF NOT EXISTS ix_medications_user_active ON medications(user_id, active);
CREATE INDEX IF NOT EXISTS ix_dose_logs_medication_time ON dose_logs(medication_id, scheduled_time);
CREATE INDEX IF NOT EXISTS ix_sleep_records_user_date ON sleep_records(user_id, sleep_date);
CREATE INDEX IF NOT EXISTS ix_activity_logs_user_date ON activity_logs(user_id, activity_date);