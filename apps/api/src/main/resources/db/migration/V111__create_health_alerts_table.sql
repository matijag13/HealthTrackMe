CREATE TABLE IF NOT EXISTS health_alerts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description VARCHAR(255) NOT NULL,
    alert_type VARCHAR(50) NOT NULL DEFAULT 'INFO',
    severity VARCHAR(50) NOT NULL DEFAULT 'LOW',
    trigger_reason VARCHAR(255),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    action_required VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    acknowledged_at TIMESTAMP,

    CONSTRAINT fk_health_alerts_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT ck_health_alert_type CHECK (
        alert_type IN (
            'UNUSUAL_TREND',
            'ABNORMAL_VALUE',
            'MEDICATION_REMINDER',
            'DOCTOR_VISIT_NEEDED',
            'HIGH_RISK_DETECTED',
            'INFO'
        )
    ),
    CONSTRAINT ck_health_alert_severity CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'))
);

CREATE INDEX IF NOT EXISTS ix_health_alerts_user_created ON health_alerts(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS ix_health_alerts_user_read ON health_alerts(user_id, is_read);
