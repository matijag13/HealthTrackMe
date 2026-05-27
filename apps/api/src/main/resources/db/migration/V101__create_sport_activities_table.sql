-- Add missing table expected by SportActivity entity/service.
-- Older schema versions only had activity_logs.

CREATE TABLE IF NOT EXISTS sport_activities (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    activity_type VARCHAR(100) NOT NULL,
    activity_date VARCHAR(20) NOT NULL,
    duration INTEGER,
    distance DOUBLE PRECISION,
    calories_burned INTEGER,
    intensity VARCHAR(50),
    average_heart_rate INTEGER,
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sport_activities_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS ix_sport_activities_user_date
    ON sport_activities(user_id, activity_date);

-- Optional bootstrap from activity_logs so users have initial rows in the new table.
INSERT INTO sport_activities (
    user_id,
    activity_type,
    activity_date,
    calories_burned,
    average_heart_rate,
    notes,
    created_at,
    updated_at
)
SELECT
    al.user_id,
    COALESCE(NULLIF(al.source, ''), 'WALKING') AS activity_type,
    TO_CHAR(al.activity_date, 'YYYY-MM-DD') AS activity_date,
    al.calories AS calories_burned,
    al.heart_rate_avg AS average_heart_rate,
    CASE WHEN al.steps IS NULL THEN NULL ELSE CONCAT('steps=', al.steps) END AS notes,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM activity_logs al
WHERE NOT EXISTS (
    SELECT 1
    FROM sport_activities sa
    WHERE sa.user_id = al.user_id
      AND sa.activity_date = TO_CHAR(al.activity_date, 'YYYY-MM-DD')
      AND sa.activity_type = COALESCE(NULLIF(al.source, ''), 'WALKING')
);

