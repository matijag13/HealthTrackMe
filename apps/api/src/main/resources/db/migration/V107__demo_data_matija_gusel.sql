-- Demo data for matija.gusel@gmail.com — May 23 to Jun 5 2026 (14 days, ends "today").
-- matija signs in with Google in the demo; loginWithGoogle() links by email to this seeded
-- row, so the data shows up immediately. A shared demo password_hash is also set so the
-- email/password form works as a fallback (same hash as the other demo accounts).
-- Everything is idempotent: the user is ON CONFLICT DO NOTHING and every seed block is
-- guarded by NOT EXISTS, so re-running the migration set never duplicates rows.

-- ─────────────────────────────────────────────────────────────────────────────
-- 0. The demo user (athlete profile, distinct from ana.novak)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO users (
    email, password_hash, first_name, last_name, role,
    gdpr_consent_accepted, gdpr_consent_accepted_at,
    created_at, updated_at,
    date_of_birth, user_type,
    medical_conditions, allergies,
    height, weight, blood_type,
    is_active
) VALUES (
    'matija.gusel@gmail.com',
    '$2a$10$s5.TkTZWa1V32slUzHPhROFnQGchGU2dcEy2BdsTJkfJ.ZhL5azq2',
    'Matija', 'Gušel', 'USER',
    TRUE, TIMESTAMP '2026-05-20 08:00:00',
    TIMESTAMP '2026-05-20 08:00:00', TIMESTAMP '2026-05-20 08:00:00',
    '2001-04-15', 'ATHLETE',
    NULL, NULL,
    182, 78, 'O+',
    TRUE
)
ON CONFLICT (email) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Health entries  (vitals + sleep + wellbeing — one per day)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO health_entries (
    user_id, entry_date,
    wellbeing_score, energy_level, stress_level, mood,
    heart_rate, systolic_bp, diastolic_bp, spo2,
    weight, sleep_hours, sleep_quality,
    water_intake_ml, symptoms
)
SELECT u.id, v.*
FROM users u
CROSS JOIN (VALUES

  -- May 23 (Fri) — long Saturday-eve run prep, feeling strong
  ('2026-05-23'::DATE, 8, 8, 2, 'GREAT',    58, 118, 74, 99, 78.2, 7.5, 'GOOD',      2600, NULL),
  -- May 24 (Sat) — parkrun morning
  ('2026-05-24'::DATE, 9, 9, 2, 'GREAT',    56, 116, 72, 99, 78.0, 8.0, 'EXCELLENT', 2800, NULL),
  -- May 25 (Sun) — recovery, slightly sore legs
  ('2026-05-25'::DATE, 7, 6, 3, 'GOOD',     62, 119, 76, 98, 78.1, 7.0, 'GOOD',      2200, 'sore legs'),
  -- May 26 (Mon) — back to training week
  ('2026-05-26'::DATE, 8, 8, 3, 'GOOD',     59, 117, 73, 99, 78.0, 7.0, 'GOOD',      2500, NULL),
  -- May 27 (Tue) — interval session, energised
  ('2026-05-27'::DATE, 8, 9, 3, 'GREAT',    60, 118, 74, 98, 77.8, 7.5, 'GOOD',      2700, NULL),
  -- May 28 (Wed) — heavy gym day, tired evening
  ('2026-05-28'::DATE, 7, 6, 4, 'NEUTRAL',  64, 121, 78, 98, 78.2, 6.5, 'FAIR',      2300, NULL),
  -- May 29 (Thu) — exam stress at FERI
  ('2026-05-29'::DATE, 6, 5, 6, 'STRESSED', 68, 123, 80, 97, 78.3, 6.0, 'POOR',      1900, 'tension headache'),
  -- May 30 (Fri) — exam done, relief
  ('2026-05-30'::DATE, 8, 8, 2, 'GREAT',    59, 117, 73, 99, 78.0, 8.0, 'EXCELLENT', 2600, NULL),
  -- May 31 (Sat) — long ride
  ('2026-05-31'::DATE, 9, 9, 2, 'GREAT',    57, 115, 72, 99, 77.7, 7.5, 'GOOD',      3000, NULL),
  -- Jun 1  (Sun) — rest day
  ('2026-06-01'::DATE, 7, 6, 3, 'NEUTRAL',  61, 118, 74, 98, 77.9, 8.5, 'EXCELLENT', 2100, NULL),
  -- Jun 2  (Mon) — tempo run
  ('2026-06-02'::DATE, 8, 8, 3, 'GOOD',     58, 116, 73, 99, 77.8, 7.0, 'GOOD',      2600, NULL),
  -- Jun 3  (Tue) — gym + mobility
  ('2026-06-03'::DATE, 8, 8, 3, 'GOOD',     60, 117, 74, 98, 77.9, 7.0, 'GOOD',      2500, NULL),
  -- Jun 4  (Wed) — easy day, good sleep
  ('2026-06-04'::DATE, 8, 8, 2, 'GREAT',    57, 115, 72, 99, 77.6, 7.5, 'GOOD',      2700, NULL),
  -- Jun 5  (Thu) — today, feeling sharp
  ('2026-06-05'::DATE, 8, 9, 2, 'GREAT',    58, 116, 73, 99, 77.7, 7.5, 'GOOD',      2600, NULL)

) AS v(
    entry_date,
    wellbeing_score, energy_level, stress_level, mood,
    heart_rate, systolic_bp, diastolic_bp, spo2,
    weight, sleep_hours, sleep_quality,
    water_intake_ml, symptoms
)
WHERE u.email = 'matija.gusel@gmail.com'
  AND NOT EXISTS (
      SELECT 1 FROM health_entries he
      WHERE he.user_id = u.id AND he.entry_date = v.entry_date
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Sport activities
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO sport_activities (
    user_id, activity_type, activity_date,
    duration, distance, calories_burned, steps,
    average_heart_rate, intensity, notes
)
SELECT u.id, a.*
FROM users u
CROSS JOIN (VALUES

  -- May 23 (Fri) — easy shakeout run
  ('RUNNING',  '2026-05-23', 35,   6.5,  430, NULL, 148, 'MODERATE', 'Easy shakeout'),
  -- May 24 (Sat) — parkrun 5k
  ('RUNNING',  '2026-05-24', 22,   5.0,  360, NULL, 168, 'HIGH',     'Parkrun 5k PB attempt'),
  -- May 25 (Sun) — recovery walk
  ('WALKING',  '2026-05-25', 50,   4.0,  190, 5400, 104, 'LIGHT',    'Recovery walk'),
  -- May 26 (Mon) — strength session
  ('WORKOUT',  '2026-05-26', 55,   NULL, 320, NULL, 124, 'MODERATE', 'Full-body strength'),
  -- May 27 (Tue) — intervals
  ('RUNNING',  '2026-05-27', 40,   8.0,  560, NULL, 162, 'HIGH',     '6x800m intervals'),
  -- May 28 (Wed) — gym
  ('WORKOUT',  '2026-05-28', 60,   NULL, 350, NULL, 122, 'MODERATE', 'Push/pull gym'),
  -- May 31 (Sat) — long bike ride
  ('CYCLING',  '2026-05-31', 95,  38.0,  820, NULL, 140, 'MODERATE', 'Long ride to Maribor hills'),
  -- Jun 2  (Mon) — tempo run
  ('RUNNING',  '2026-06-02', 38,   7.5,  520, NULL, 158, 'HIGH',     'Tempo run'),
  -- Jun 3  (Tue) — gym + mobility
  ('WORKOUT',  '2026-06-03', 50,   NULL, 300, NULL, 120, 'MODERATE', 'Legs + mobility'),
  -- Jun 4  (Wed) — commute ride
  ('CYCLING',  '2026-06-04', 30,  11.0,  280, NULL, 132, 'MODERATE', 'Commute ride'),
  -- Jun 5  (Thu) — today easy run
  ('RUNNING',  '2026-06-05', 32,   6.0,  410, NULL, 150, 'MODERATE', 'Easy run')

) AS a(
    activity_type, activity_date,
    duration, distance, calories_burned, steps,
    average_heart_rate, intensity, notes
)
WHERE u.email = 'matija.gusel@gmail.com'
  AND NOT EXISTS (
      SELECT 1 FROM sport_activities sa
      WHERE sa.user_id = u.id
        AND sa.activity_date = a.activity_date
        AND sa.activity_type = a.activity_type
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Sleep records
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO sleep_records (user_id, sleep_date, duration_minutes, quality_score, source)
SELECT u.id, s.*
FROM users u
CROSS JOIN (VALUES
  ('2026-05-23'::DATE, 450, 4, 'Samsung Health'),
  ('2026-05-24'::DATE, 480, 5, 'Samsung Health'),
  ('2026-05-25'::DATE, 420, 4, 'Samsung Health'),
  ('2026-05-26'::DATE, 420, 4, 'Samsung Health'),
  ('2026-05-27'::DATE, 450, 4, 'Samsung Health'),
  ('2026-05-28'::DATE, 390, 3, 'Samsung Health'),
  ('2026-05-29'::DATE, 360, 2, 'Samsung Health'),
  ('2026-05-30'::DATE, 480, 5, 'Samsung Health'),
  ('2026-05-31'::DATE, 450, 4, 'Samsung Health'),
  ('2026-06-01'::DATE, 510, 5, 'Samsung Health'),
  ('2026-06-02'::DATE, 420, 4, 'Samsung Health'),
  ('2026-06-03'::DATE, 420, 4, 'Samsung Health'),
  ('2026-06-04'::DATE, 450, 4, 'Samsung Health'),
  ('2026-06-05'::DATE, 450, 4, 'Samsung Health')
) AS s(sleep_date, duration_minutes, quality_score, source)
WHERE u.email = 'matija.gusel@gmail.com'
  AND NOT EXISTS (
      SELECT 1 FROM sleep_records sr
      WHERE sr.user_id = u.id AND sr.sleep_date = s.sleep_date
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Supplements (so the Medicines insight on the Reports screen has data)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, item_type, is_active)
SELECT u.id, m.*
FROM users u
CROSS JOIN (VALUES
  ('Vitamin D3',  '1000 IU', 'Once daily',  'Bone & immune support', '2026-05-01'::DATE, 'VITAMIN',    TRUE),
  ('Magnesium',   '300 mg',  'Once daily',  'Muscle recovery',       '2026-05-01'::DATE, 'SUPPLEMENT', TRUE)
) AS m(name, dosage, frequency, reason, start_date, item_type, is_active)
WHERE u.email = 'matija.gusel@gmail.com'
  AND NOT EXISTS (
      SELECT 1 FROM medicines md
      WHERE md.user_id = u.id AND md.name = m.name
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. A connected Samsung wearable so the Wearables screen shows a device
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO wearable_devices (
    user_id, device_name, device_type, device_id,
    is_active, last_sync_time, connected_at, updated_at
)
SELECT u.id,
       'Samsung Galaxy Watch', 'SAMSUNG', 'samsung_galaxy_demo_matija',
       TRUE, TIMESTAMP '2026-06-05 07:30:00',
       TIMESTAMP '2026-05-20 08:05:00', TIMESTAMP '2026-06-05 07:30:00'
FROM users u
WHERE u.email = 'matija.gusel@gmail.com'
  AND NOT EXISTS (
      SELECT 1 FROM wearable_devices wd
      WHERE wd.device_id = 'samsung_galaxy_demo_matija'
  );
