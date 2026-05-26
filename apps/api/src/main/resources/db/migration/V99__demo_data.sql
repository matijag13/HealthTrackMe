-- Demo data for local development: users, medicines, daily health entries, activity logs and dose logs
-- GENERATED for testing purposes. Safe to re-run (uses NOT EXISTS guards).

-- 1) Insert demo users
INSERT INTO users (email, password_hash, first_name, last_name, role, gdpr_consent_accepted, gdpr_consent_accepted_at, created_at, updated_at, date_of_birth, medical_conditions, is_active)
SELECT 'alice@demo.com', '$2a$10$7EqJtq98hPqEX7fNZaFWoO', 'Alice', 'Johnson', 'USER', TRUE, NOW(), NOW(), NOW(), '1990-05-14', 'Diabetes;Hypertension', TRUE
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.email = 'alice@demo.com');

INSERT INTO users (email, password_hash, first_name, last_name, role, gdpr_consent_accepted, gdpr_consent_accepted_at, created_at, updated_at, date_of_birth, medical_conditions, is_active)
SELECT 'bob@demo.com', '$2a$10$7EqJtq98hPqEX7fNZaFWoO', 'Bob', 'Smith', 'USER', TRUE, NOW(), NOW(), NOW(), '1985-03-22', 'Asthma', TRUE
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.email = 'bob@demo.com');

INSERT INTO users (email, password_hash, first_name, last_name, role, gdpr_consent_accepted, gdpr_consent_accepted_at, created_at, updated_at, date_of_birth, medical_conditions, is_active)
SELECT 'sara@demo.com', '$2a$10$7EqJtq98hPqEX7fNZaFWoO', 'Sara', 'Lee', 'USER', TRUE, NOW(), NOW(), NOW(), '1995-11-08', NULL, TRUE
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.email = 'sara@demo.com');

-- Convenience: fetch user ids
-- Use subselects in subsequent inserts: (SELECT id FROM users WHERE email = ...)

-- 2) Insert medicines for each user (single canonical medicines table)
INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Metformin', '500mg', 'Twice daily', 'Take with meals', NULL, NULL, NULL, 'MEDICATION', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'alice@demo.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Metformin');

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Lisinopril', '10mg', 'Once daily', 'Take in the morning', NULL, NULL, NULL, 'MEDICATION', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'alice@demo.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Lisinopril');

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Vitamin D', '1000IU', 'Once daily', 'Take with food', NULL, NULL, NULL, 'SUPPLEMENT', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'alice@demo.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Vitamin D');

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Aspirin', '100mg', 'Once daily', 'Low-dose aspirin', NULL, NULL, NULL, 'MEDICATION', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'alice@demo.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Aspirin');

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Ventolin Inhaler', '100mcg', 'As needed', 'Use as prescribed', NULL, NULL, NULL, 'MEDICATION', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'bob@demo.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Ventolin Inhaler');

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Omega-3', '1000mg', 'Once daily', 'Take with food', NULL, NULL, NULL, 'SUPPLEMENT', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'bob@demo.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Omega-3');

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Vitamin D', '1000IU', 'Once daily', 'Take with food', NULL, NULL, NULL, 'SUPPLEMENT', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'bob@demo.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Vitamin D');

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Aspirin', '100mg', 'Once daily', 'Low-dose aspirin', NULL, NULL, NULL, 'MEDICATION', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'bob@demo.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Aspirin');

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Vitamin D', '1000IU', 'Once daily', 'Take with food', NULL, NULL, NULL, 'SUPPLEMENT', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'sara@demo.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Vitamin D');

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Omega-3', '1000mg', 'Once daily', 'Take with food', NULL, NULL, NULL, 'SUPPLEMENT', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'sara@demo.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Omega-3');

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Aspirin', '100mg', 'Once daily', 'Low-dose aspirin', NULL, NULL, NULL, 'MEDICATION', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'sara@demo.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Aspirin');

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Multivitamin', '1 tablet', 'Once daily', 'Take with food', NULL, NULL, NULL, 'SUPPLEMENT', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'sara@demo.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Multivitamin');

-- 3) Insert daily health entries for the past ~2 years per user (~730 rows each)
-- Uses generate_series and lateral to compute energy/stress and wellbeing consistently per row

-- Alice
INSERT INTO health_entries (user_id, entry_date, wellbeing_score, energy_level, stress_level, mood, symptoms, doctor_notes, created_at, updated_at, sleep_hours, sleep_quality)
SELECT
  (SELECT id FROM users WHERE email = 'alice@demo.com'),
  d::date,
  GREATEST(1, LEAST(10, FLOOR(((r.energy*0.6 + (100 - r.stress)*0.4)/10))::int)),
  r.energy,
  r.stress,
  (ARRAY['😊','😐','🤩','😔','😰'])[FLOOR(random()*5+1)],
  (CASE WHEN random() < 0.25 THEN (ARRAY['Headache','Fatigue','Pain','Nausea','Dizziness'])[FLOOR(random()*5+1)] ELSE NULL END),
  (ARRAY['Felt okay','Tired day','Productive','Stressful day at work','Slept well','Mild headache'])[FLOOR(random()*6+1)],
  NOW(), NOW(),
  ROUND((5.0 + random()*4.0)::numeric, 1),
  (ARRAY['GOOD','FAIR','POOR'])[FLOOR(random()*3+1)]
FROM generate_series(CURRENT_DATE - INTERVAL '2 years', CURRENT_DATE, '1 day') AS d
CROSS JOIN LATERAL (SELECT (30 + random()*60)::int AS energy, (10 + random()*70)::int AS stress) r
WHERE NOT EXISTS (
  SELECT 1 FROM health_entries he WHERE he.user_id = (SELECT id FROM users WHERE email = 'alice@demo.com') AND he.entry_date = d::date
);

-- Bob
INSERT INTO health_entries (user_id, entry_date, wellbeing_score, energy_level, stress_level, mood, symptoms, doctor_notes, created_at, updated_at, sleep_hours, sleep_quality)
SELECT
  (SELECT id FROM users WHERE email = 'bob@demo.com'),
  d::date,
  GREATEST(1, LEAST(10, FLOOR(((r.energy*0.55 + (100 - r.stress)*0.45)/10))::int)),
  r.energy,
  r.stress,
  (ARRAY['😐','😊','😔','😰','🤩'])[FLOOR(random()*5+1)],
  (CASE WHEN random() < 0.2 THEN (ARRAY['Shortness of breath','Cough','Fatigue','Headache'])[FLOOR(random()*4+1)] ELSE NULL END),
  (ARRAY['Morning run','Indoor cycling','Rest day','Gym session','Light walk'])[FLOOR(random()*5+1)],
  NOW(), NOW(),
  ROUND((5.0 + random()*4.0)::numeric, 1),
  (ARRAY['GOOD','FAIR','POOR'])[FLOOR(random()*3+1)]
FROM generate_series(CURRENT_DATE - INTERVAL '2 years', CURRENT_DATE, '1 day') AS d
CROSS JOIN LATERAL (SELECT (35 + random()*55)::int AS energy, (10 + random()*60)::int AS stress) r
WHERE NOT EXISTS (
  SELECT 1 FROM health_entries he WHERE he.user_id = (SELECT id FROM users WHERE email = 'bob@demo.com') AND he.entry_date = d::date
);

-- Sara
INSERT INTO health_entries (user_id, entry_date, wellbeing_score, energy_level, stress_level, mood, symptoms, doctor_notes, created_at, updated_at, sleep_hours, sleep_quality)
SELECT
  (SELECT id FROM users WHERE email = 'sara@demo.com'),
  d::date,
  GREATEST(1, LEAST(10, FLOOR(((r.energy*0.65 + (100 - r.stress)*0.35)/10))::int)),
  r.energy,
  r.stress,
  (ARRAY['😊','🤩','😐','😔','😰'])[FLOOR(random()*5+1)],
  (CASE WHEN random() < 0.15 THEN (ARRAY['Fatigue','Headache','Pain'])[FLOOR(random()*3+1)] ELSE NULL END),
  (ARRAY['Good day','Light fatigue','Great sleep','Busy day','Relaxed'])[FLOOR(random()*5+1)],
  NOW(), NOW(),
  ROUND((5.5 + random()*3.5)::numeric, 1),
  (ARRAY['GOOD','FAIR','POOR'])[FLOOR(random()*3+1)]
FROM generate_series(CURRENT_DATE - INTERVAL '2 years', CURRENT_DATE, '1 day') AS d
CROSS JOIN LATERAL (SELECT (40 + random()*50)::int AS energy, (10 + random()*60)::int AS stress) r
WHERE NOT EXISTS (
  SELECT 1 FROM health_entries he WHERE he.user_id = (SELECT id FROM users WHERE email = 'sara@demo.com') AND he.entry_date = d::date
);

-- 4) Activity logs: approx 3 per week per user (every 3 days)
-- Alice activities
INSERT INTO activity_logs (user_id, activity_date, steps, calories, heart_rate_avg, source)
SELECT (SELECT id FROM users WHERE email = 'alice@demo.com'), d::date,
  (2000 + (random()*10000))::int,
  (150 + (random()*700))::int,
  (80 + (random()*60))::int,
  (ARRAY['phone','watch','fitbit'])[FLOOR(random()*3+1)]
FROM generate_series(CURRENT_DATE - INTERVAL '2 years', CURRENT_DATE, '3 days') AS d
WHERE NOT EXISTS (SELECT 1 FROM activity_logs al WHERE al.user_id = (SELECT id FROM users WHERE email = 'alice@demo.com') AND al.activity_date = d::date);

-- Bob activities
INSERT INTO activity_logs (user_id, activity_date, steps, calories, heart_rate_avg, source)
SELECT (SELECT id FROM users WHERE email = 'bob@demo.com'), d::date,
  (1000 + (random()*9000))::int,
  (120 + (random()*600))::int,
  (75 + (random()*50))::int,
  (ARRAY['phone','watch','manual'])[FLOOR(random()*3+1)]
FROM generate_series(CURRENT_DATE - INTERVAL '2 years', CURRENT_DATE, '3 days') AS d
WHERE NOT EXISTS (SELECT 1 FROM activity_logs al WHERE al.user_id = (SELECT id FROM users WHERE email = 'bob@demo.com') AND al.activity_date = d::date);

-- Sara activities
INSERT INTO activity_logs (user_id, activity_date, steps, calories, heart_rate_avg, source)
SELECT (SELECT id FROM users WHERE email = 'sara@demo.com'), d::date,
  (1500 + (random()*8000))::int,
  (130 + (random()*500))::int,
  (70 + (random()*50))::int,
  (ARRAY['phone','watch','manual'])[FLOOR(random()*3+1)]
FROM generate_series(CURRENT_DATE - INTERVAL '2 years', CURRENT_DATE, '3 days') AS d
WHERE NOT EXISTS (SELECT 1 FROM activity_logs al WHERE al.user_id = (SELECT id FROM users WHERE email = 'sara@demo.com') AND al.activity_date = d::date);

-- 5) Dose logs: Insert daily dose logs for each medicine using pure SQL without loops
-- Uses CASE WHEN to determine start date per medicine name, then generate_series for all days
INSERT INTO dose_logs (medicine_id, scheduled_time, taken_time, status, note)
SELECT
  m.id,
  gs.day_ts + TIME '08:00',
  CASE
    WHEN random() < 0.8 THEN (gs.day_ts::timestamp + TIME '08:00' + make_interval(mins => (random()*60)::int))
    ELSE NULL
  END AS taken_time,
  CASE
    WHEN random() < 0.8 THEN 'TAKEN'
    ELSE 'MISSED'
  END AS status,
  NULL
FROM medicines m
CROSS JOIN generate_series(
  CASE
    WHEN m.name = 'Metformin' THEN CURRENT_DATE - INTERVAL '500 days'
    WHEN m.name = 'Lisinopril' THEN CURRENT_DATE - INTERVAL '450 days'
    WHEN m.name = 'Ventolin Inhaler' THEN CURRENT_DATE - INTERVAL '300 days'
    WHEN m.name = 'Vitamin D' THEN CURRENT_DATE - INTERVAL '400 days'
    WHEN m.name = 'Omega-3' THEN CURRENT_DATE - INTERVAL '380 days'
    WHEN m.name = 'Aspirin' THEN CURRENT_DATE - INTERVAL '420 days'
    ELSE CURRENT_DATE - INTERVAL '360 days'
  END,
  CURRENT_DATE,
  '1 day'::interval
) AS gs(day_ts)
WHERE m.name IN ('Metformin','Lisinopril','Vitamin D','Aspirin','Ventolin Inhaler','Omega-3','Multivitamin')
  AND NOT EXISTS (
    SELECT 1 FROM dose_logs d
    WHERE d.medicine_id = m.id
    AND d.scheduled_time = (gs.day_ts + TIME '08:00')
  );


-- End of demo data migration

