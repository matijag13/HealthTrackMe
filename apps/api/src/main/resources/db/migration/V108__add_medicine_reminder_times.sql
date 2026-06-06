-- Store per-medicine daily reminder times as a comma-separated list of HH:mm
-- values (e.g. '08:00,20:00'). NULL/empty means no reminders configured.
ALTER TABLE medicines ADD COLUMN reminder_times TEXT;
