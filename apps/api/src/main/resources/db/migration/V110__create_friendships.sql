-- Friendships power the gamification leaderboard (compare streaks + Health Shield
-- points between friends). Only the social connection and its status are stored
-- here — no health data is ever shared through a friendship.
CREATE TABLE IF NOT EXISTS friendships (
    id BIGSERIAL PRIMARY KEY,
    requester_id BIGINT NOT NULL REFERENCES users(id),
    addressee_id BIGINT NOT NULL REFERENCES users(id),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_friendship_pair UNIQUE (requester_id, addressee_id),
    CONSTRAINT chk_friendship_not_self CHECK (requester_id <> addressee_id)
);

CREATE INDEX IF NOT EXISTS idx_friendship_requester ON friendships(requester_id);
CREATE INDEX IF NOT EXISTS idx_friendship_addressee ON friendships(addressee_id);
