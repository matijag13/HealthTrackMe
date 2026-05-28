-- Create detective_insights table for storing AI-generated health insights

CREATE TABLE IF NOT EXISTS detective_insights (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    badge VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    finding TEXT NOT NULL,
    correlations TEXT,
    time_range VARCHAR(50) NOT NULL DEFAULT 'WEEK',
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_detective_insights_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT ck_time_range CHECK (time_range IN ('WEEK', 'MONTH', 'ALL_TIME'))
);

-- Create index for efficient queries
CREATE INDEX idx_detective_insights_user_id ON detective_insights(user_id);
CREATE INDEX idx_detective_insights_generated_at ON detective_insights(generated_at);
CREATE INDEX idx_detective_insights_user_time_range ON detective_insights(user_id, time_range, generated_at DESC);
