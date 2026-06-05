-- Demo data for ana.novak@example.com — May 30 to June 12 2026.
-- Also fixes the wearable_devices CHECK constraint to accept brand-specific
-- device types added to the DeviceType enum in the backend.

-- ─────────────────────────────────────────────────────────────────────────────
-- 0. Fix wearable_devices CHECK constraint to include brand device types
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE wearable_devices
    DROP CONSTRAINT IF EXISTS ck_wearable_devices_device_type;

ALTER TABLE wearable_devices
    ADD CONSTRAINT ck_wearable_devices_device_type CHECK (
        device_type IN (
            'SMARTWATCH','FITNESS_TRACKER','HEART_MONITOR',
            'BLOOD_PRESSURE_MONITOR','GLUCOSE_MONITOR','SLEEP_TRACKER','OTHER',
            'APPLEWATCH','FITBIT','GARMIN','OURA','WHOOP','SAMSUNG','GOOGLEFIT'
        )
    );

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

  -- May 30 (Fri) — active day after work
  ('2026-05-30'::DATE, 7, 7, 3, 'GOOD',     72, 114, 74, 98, 62.1, 7.5, 'GOOD',      1800, NULL),
  -- May 31 (Sat) — relaxed weekend morning
  ('2026-05-31'::DATE, 8, 8, 2, 'GREAT',    68, 112, 72, 99, 62.0, 8.0, 'EXCELLENT', 2000, NULL),
  -- Jun 1  (Sun) — lazy Sunday, slightly tired
  ('2026-06-01'::DATE, 6, 5, 3, 'NEUTRAL',  74, 116, 75, 98, 62.2, 7.0, 'GOOD',      1600, NULL),
  -- Jun 2  (Mon) — Monday motivation
  ('2026-06-02'::DATE, 7, 7, 4, 'GOOD',     71, 113, 73, 99, 62.1, 6.5, 'FAIR',      1900, NULL),
  -- Jun 3  (Tue) — mild asthma irritation after outdoor walk
  ('2026-06-03'::DATE, 6, 6, 4, 'NEUTRAL',  76, 117, 76, 96, 62.3, 7.0, 'FAIR',      2100, 'mild chest tightness'),
  -- Jun 4  (Wed) — recovered, good cycling day
  ('2026-06-04'::DATE, 8, 8, 2, 'GREAT',    70, 111, 72, 98, 62.0, 7.5, 'GOOD',      2200, NULL),
  -- Jun 5  (Thu) — stressful day at work, rest
  ('2026-06-05'::DATE, 5, 4, 7, 'STRESSED', 80, 119, 78, 97, 62.4, 6.0, 'POOR',      1500, 'headache; tense shoulders'),
  -- Jun 6  (Fri) — bouncing back
  ('2026-06-06'::DATE, 7, 7, 4, 'GOOD',     73, 115, 74, 98, 62.2, 7.5, 'GOOD',      1800, NULL),
  -- Jun 7  (Sat) — long walk, great mood
  ('2026-06-07'::DATE, 9, 9, 2, 'GREAT',    67, 110, 71, 99, 61.9, 8.0, 'EXCELLENT', 2300, NULL),
  -- Jun 8  (Sun) — full rest day
  ('2026-06-08'::DATE, 7, 6, 3, 'NEUTRAL',  71, 113, 73, 98, 62.0, 8.5, 'EXCELLENT', 1700, NULL),
  -- Jun 9  (Mon) — back to routine
  ('2026-06-09'::DATE, 7, 7, 3, 'GOOD',     72, 114, 74, 98, 62.1, 7.0, 'GOOD',      1900, NULL),
  -- Jun 10 (Tue) — workout day, energised
  ('2026-06-10'::DATE, 8, 8, 3, 'GREAT',    69, 111, 72, 99, 61.8, 7.5, 'GOOD',      2100, NULL),
  -- Jun 11 (Wed) — good running day
  ('2026-06-11'::DATE, 8, 8, 2, 'GREAT',    70, 112, 73, 99, 61.9, 7.5, 'GOOD',      2000, NULL),
  -- Jun 12 (Thu) — today, feeling good
  ('2026-06-12'::DATE, 7, 7, 3, 'GOOD',     73, 115, 74, 98, 62.0, 7.0, 'GOOD',      1800, NULL)

) AS v(
    entry_date,
    wellbeing_score, energy_level, stress_level, mood,
    heart_rate, systolic_bp, diastolic_bp, spo2,
    weight, sleep_hours, sleep_quality,
    water_intake_ml, symptoms
)
WHERE u.email = 'ana.novak@example.com'
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

  -- May 30 (Fri) — after-work walk
  ('WALKING',  '2026-05-30', 45,   4.2,  210, 5800, 118, 'MODERATE', 'Evening walk'),
  -- May 31 (Sat) — morning run
  ('RUNNING',  '2026-05-31', 25,   4.5,  285, NULL, 152, 'HIGH',     'Park run'),
  -- Jun 2  (Mon) — strength workout
  ('WORKOUT',  '2026-06-02', 40,   NULL, 230, NULL, 128, 'MODERATE', 'Home workout'),
  -- Jun 3  (Tue) — short walk (asthma day — kept it light)
  ('WALKING',  '2026-06-03', 30,   2.8,  140, 3800, 108, 'LIGHT',    'Light walk'),
  -- Jun 4  (Wed) — cycling
  ('CYCLING',  '2026-06-04', 45,  12.0,  320, NULL, 138, 'MODERATE', 'Bike ride'),
  -- Jun 6  (Fri) — run after stressful week
  ('RUNNING',  '2026-06-06', 30,   5.0,  310, NULL, 155, 'HIGH',     'Stress relief run'),
  -- Jun 7  (Sat) — long Saturday walk
  ('WALKING',  '2026-06-07', 65,   5.5,  275, 7500, 115, 'MODERATE', 'Long morning walk'),
  -- Jun 9  (Mon) — cycling commute
  ('CYCLING',  '2026-06-09', 35,  10.0,  260, NULL, 132, 'MODERATE', 'Cycling'),
  -- Jun 10 (Tue) — workout
  ('WORKOUT',  '2026-06-10', 35,   NULL, 210, NULL, 125, 'MODERATE', 'Circuit training'),
  -- Jun 11 (Wed) — run
  ('RUNNING',  '2026-06-11', 28,   4.8,  295, NULL, 153, 'HIGH',     'Interval run'),
  -- Jun 12 (Thu) — today walk
  ('WALKING',  '2026-06-12', 40,   3.8,  190, 5200, 112, 'MODERATE', 'Lunch walk')

) AS a(
    activity_type, activity_date,
    duration, distance, calories_burned, steps,
    average_heart_rate, intensity, notes
)
WHERE u.email = 'ana.novak@example.com'
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
  ('2026-05-30'::DATE, 450, 4, 'Manual'),
  ('2026-05-31'::DATE, 480, 5, 'Manual'),
  ('2026-06-01'::DATE, 420, 4, 'Manual'),
  ('2026-06-02'::DATE, 390, 3, 'Manual'),
  ('2026-06-03'::DATE, 420, 3, 'Manual'),
  ('2026-06-04'::DATE, 450, 4, 'Manual'),
  ('2026-06-05'::DATE, 360, 2, 'Manual'),
  ('2026-06-06'::DATE, 450, 4, 'Manual'),
  ('2026-06-07'::DATE, 480, 5, 'Manual'),
  ('2026-06-08'::DATE, 510, 5, 'Manual'),
  ('2026-06-09'::DATE, 420, 4, 'Manual'),
  ('2026-06-10'::DATE, 450, 4, 'Manual'),
  ('2026-06-11'::DATE, 450, 4, 'Manual'),
  ('2026-06-12'::DATE, 420, 4, 'Manual')
) AS s(sleep_date, duration_minutes, quality_score, source)
WHERE u.email = 'ana.novak@example.com'
  AND NOT EXISTS (
      SELECT 1 FROM sleep_records sr
      WHERE sr.user_id = u.id AND sr.sleep_date = s.sleep_date
  );
