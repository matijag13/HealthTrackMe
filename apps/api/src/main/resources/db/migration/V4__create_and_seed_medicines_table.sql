CREATE TABLE IF NOT EXISTS medicines (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    dosage VARCHAR(255),
    frequency VARCHAR(100),
    reason TEXT,
    start_date DATE,
    end_date DATE,
    side_effects TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_medicines_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS ix_medicines_user_active ON medicines(user_id, is_active);

INSERT INTO medicines (
    user_id,
    name,
    dosage,
    frequency,
    reason,
    start_date,
    end_date,
    side_effects,
    is_active,
    created_at,
    updated_at
)
SELECT
    m.user_id,
    m.name,
    m.dosage,
    m.frequency,
    m.instructions,
    NULL,
    NULL,
    NULL,
    m.active,
    m.created_at,
    m.updated_at
FROM medications m
WHERE NOT EXISTS (
    SELECT 1
    FROM medicines x
    WHERE x.user_id = m.user_id
      AND x.name = m.name
);
