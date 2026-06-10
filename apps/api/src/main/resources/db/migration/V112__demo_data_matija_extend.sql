-- Extends matija.gusel@gmail.com demo data to a full ~30-day window ending Jun 14 2026,
-- so the dashboard's "today" and the 1W/1M graphs are populated during the presentation.
-- V107 already seeds May 23–Jun 5; this adds May 16–22 and Jun 6–14, plus per-day WALKING
-- step totals across the whole window. Same idempotent pattern as V107 (NOT EXISTS guards),
-- so re-running never duplicates rows.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Health entries — May 16–22 and Jun 6–14 (one per day)
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
  ('2026-05-16'::DATE, 8, 8, 2, 'GREAT',    57, 116, 73, 99, 78.1, 7.5, 'GOOD',      2700, NULL),
  ('2026-05-17'::DATE, 7, 6, 3, 'NEUTRAL',  61, 118, 75, 98, 78.0, 8.0, 'EXCELLENT', 2200, NULL),
  ('2026-05-18'::DATE, 8, 8, 3, 'GOOD',     59, 117, 74, 99, 77.9, 7.0, 'GOOD',      2500, NULL),
  ('2026-05-19'::DATE, 8, 9, 3, 'GREAT',    60, 118, 74, 98, 77.8, 7.5, 'GOOD',      2700, NULL),
  ('2026-05-20'::DATE, 7, 6, 4, 'NEUTRAL',  64, 120, 78, 98, 78.0, 6.5, 'FAIR',      2300, NULL),
  ('2026-05-21'::DATE, 8, 8, 3, 'GOOD',     58, 116, 73, 99, 77.9, 7.0, 'GOOD',      2500, NULL),
  ('2026-05-22'::DATE, 8, 8, 2, 'GREAT',    58, 116, 72, 99, 77.8, 7.5, 'GOOD',      2600, NULL),
  ('2026-06-06'::DATE, 9, 9, 2, 'GREAT',    56, 115, 72, 99, 77.6, 8.0, 'EXCELLENT', 2800, NULL),
  ('2026-06-07'::DATE, 7, 6, 3, 'NEUTRAL',  61, 118, 75, 98, 77.8, 8.5, 'EXCELLENT', 2100, NULL),
  ('2026-06-08'::DATE, 8, 8, 3, 'GOOD',     58, 116, 73, 99, 77.7, 7.0, 'GOOD',      2600, NULL),
  ('2026-06-09'::DATE, 8, 8, 3, 'GOOD',     60, 117, 74, 98, 77.8, 7.0, 'GOOD',      2500, NULL),
  ('2026-06-10'::DATE, 8, 8, 2, 'GREAT',    57, 115, 72, 99, 77.6, 7.5, 'GOOD',      2700, NULL),
  ('2026-06-11'::DATE, 8, 9, 2, 'GREAT',    58, 116, 73, 99, 77.7, 7.5, 'GOOD',      2600, NULL),
  ('2026-06-12'::DATE, 9, 9, 1, 'GREAT',    56, 115, 71, 99, 77.5, 8.0, 'EXCELLENT', 2800, NULL),
  ('2026-06-13'::DATE, 8, 8, 2, 'GREAT',    57, 116, 72, 99, 77.6, 7.5, 'GOOD',      2600, NULL),
  ('2026-06-14'::DATE, 7, 7, 3, 'GOOD',     60, 117, 74, 98, 77.7, 7.0, 'GOOD',      2400, NULL)
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
-- 2. Workout sessions (runs / rides / gym) on the new days
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO sport_activities (
    user_id, activity_type, activity_date,
    duration, distance, calories_burned, steps,
    average_heart_rate, intensity, notes
)
SELECT u.id, a.*
FROM users u
CROSS JOIN (VALUES
  ('RUNNING',  '2026-05-16', 22,  5.0,  360, NULL::INTEGER, 167, 'HIGH', 'Parkrun 5k'),
  ('RUNNING',  '2026-05-18', 35,  6.5,  430, NULL, 148, 'MODERATE', 'Easy run'),
  ('RUNNING',  '2026-05-19', 40,  8.0,  560, NULL, 162, 'HIGH',     '6x800m intervals'),
  ('WORKOUT',  '2026-05-20', 55,  NULL, 330, NULL, 124, 'MODERATE', 'Full-body strength'),
  ('RUNNING',  '2026-05-22', 38,  7.5,  520, NULL, 158, 'HIGH',     'Tempo run'),
  ('RUNNING',  '2026-06-06', 22,  5.0,  360, NULL, 167, 'HIGH',     'Parkrun 5k'),
  ('RUNNING',  '2026-06-08', 38,  7.5,  520, NULL, 158, 'HIGH',     'Tempo run'),
  ('WORKOUT',  '2026-06-09', 50,  NULL, 300, NULL, 120, 'MODERATE', 'Legs + mobility'),
  ('CYCLING',  '2026-06-11', 45, 18.0,  420, NULL, 138, 'MODERATE', 'Evening ride'),
  ('RUNNING',  '2026-06-12', 30,  6.0,  400, NULL, 150, 'MODERATE', 'Easy run'),
  ('CYCLING',  '2026-06-13', 90, 36.0,  800, NULL, 140, 'MODERATE', 'Long ride')
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
-- 3. Per-day WALKING step totals across the whole window (no duration = daily
--    total, the same shape the Health Connect sync produces) so the Steps graph
--    is full. Skips any day that already has a WALKING row (e.g. V107's May 25).
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO sport_activities (
    user_id, activity_type, activity_date,
    duration, distance, calories_burned, steps,
    average_heart_rate, intensity, notes
)
SELECT u.id, 'WALKING', w.d, NULL, NULL, NULL, w.steps, NULL, NULL, 'Synced from Health Connect'
FROM users u
CROSS JOIN (VALUES
  ('2026-05-16', 9500), ('2026-05-17', 7000), ('2026-05-18', 10500),
  ('2026-05-19', 11000), ('2026-05-20', 8500), ('2026-05-21', 7500),
  ('2026-05-22', 10000), ('2026-05-23', 9500), ('2026-05-24', 11000),
  ('2026-05-26', 8500), ('2026-05-27', 12000), ('2026-05-28', 8000),
  ('2026-05-29', 6500), ('2026-05-30', 9000), ('2026-05-31', 13000),
  ('2026-06-01', 6000), ('2026-06-02', 11000), ('2026-06-03', 8500),
  ('2026-06-04', 9500), ('2026-06-05', 9000), ('2026-06-06', 11000),
  ('2026-06-07', 6500), ('2026-06-08', 11000), ('2026-06-09', 8500),
  ('2026-06-10', 9500), ('2026-06-11', 12000), ('2026-06-12', 9000),
  ('2026-06-13', 13500), ('2026-06-14', 7000)
) AS w(d, steps)
WHERE u.email = 'matija.gusel@gmail.com'
  AND NOT EXISTS (
      SELECT 1 FROM sport_activities sa
      WHERE sa.user_id = u.id
        AND sa.activity_date = w.d
        AND sa.activity_type = 'WALKING'
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Sleep records for the new days
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO sleep_records (user_id, sleep_date, duration_minutes, quality_score, source)
SELECT u.id, s.*
FROM users u
CROSS JOIN (VALUES
  ('2026-05-16'::DATE, 450, 4, 'Samsung Health'),
  ('2026-05-17'::DATE, 480, 5, 'Samsung Health'),
  ('2026-05-18'::DATE, 420, 4, 'Samsung Health'),
  ('2026-05-19'::DATE, 450, 4, 'Samsung Health'),
  ('2026-05-20'::DATE, 390, 3, 'Samsung Health'),
  ('2026-05-21'::DATE, 420, 4, 'Samsung Health'),
  ('2026-05-22'::DATE, 450, 4, 'Samsung Health'),
  ('2026-06-06'::DATE, 480, 5, 'Samsung Health'),
  ('2026-06-07'::DATE, 510, 5, 'Samsung Health'),
  ('2026-06-08'::DATE, 420, 4, 'Samsung Health'),
  ('2026-06-09'::DATE, 420, 4, 'Samsung Health'),
  ('2026-06-10'::DATE, 450, 4, 'Samsung Health'),
  ('2026-06-11'::DATE, 450, 4, 'Samsung Health'),
  ('2026-06-12'::DATE, 480, 5, 'Samsung Health'),
  ('2026-06-13'::DATE, 450, 4, 'Samsung Health'),
  ('2026-06-14'::DATE, 420, 4, 'Samsung Health')
) AS s(sleep_date, duration_minutes, quality_score, source)
WHERE u.email = 'matija.gusel@gmail.com'
  AND NOT EXISTS (
      SELECT 1 FROM sleep_records sr
      WHERE sr.user_id = u.id AND sr.sleep_date = s.sleep_date
  );
