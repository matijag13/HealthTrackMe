ALTER TABLE users
    ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(32) NOT NULL DEFAULT 'LOCAL';

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS google_sub VARCHAR(255);

ALTER TABLE users
    ALTER COLUMN password_hash DROP NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_users_google_sub
    ON users(google_sub)
    WHERE google_sub IS NOT NULL;
