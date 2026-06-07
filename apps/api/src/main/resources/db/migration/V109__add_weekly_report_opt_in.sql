-- Opt-in flag for the scheduled weekly AI health-report email.
ALTER TABLE users ADD COLUMN weekly_report_enabled BOOLEAN NOT NULL DEFAULT FALSE;
