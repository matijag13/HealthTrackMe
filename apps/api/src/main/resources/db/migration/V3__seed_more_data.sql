-- Seed data for demo users, attached by email so IDs do not matter

INSERT INTO health_entries (user_id, entry_date, wellbeing_score, energy_level, stress_level, mood, symptoms, doctor_notes, created_at, updated_at, sleep_hours, sleep_quality)
SELECT u.id, CURRENT_DATE, 7, 70, 30, 'good', 'cough', NULL, NOW(), NOW(), 7.5, 'good'
FROM users u
WHERE u.email = 'ana.novak@example.com'
  AND NOT EXISTS (
    SELECT 1 FROM health_entries he WHERE he.user_id = u.id AND he.entry_date = CURRENT_DATE
  );

INSERT INTO health_entries (user_id, entry_date, wellbeing_score, energy_level, stress_level, mood, symptoms, doctor_notes, created_at, updated_at, sleep_hours, sleep_quality)
SELECT u.id, CURRENT_DATE, 9, 85, 10, 'energized', '', NULL, NOW(), NOW(), 8.0, 'excellent'
FROM users u
WHERE u.email = 'luka.horvat@example.com'
  AND NOT EXISTS (
    SELECT 1 FROM health_entries he WHERE he.user_id = u.id AND he.entry_date = CURRENT_DATE
  );

INSERT INTO health_entries (user_id, entry_date, wellbeing_score, energy_level, stress_level, mood, symptoms, doctor_notes, created_at, updated_at, sleep_hours, sleep_quality)
SELECT u.id, CURRENT_DATE, 6, 60, 40, 'tired', 'joint pain', NULL, NOW(), NOW(), 6.0, 'fair'
FROM users u
WHERE u.email = 'maja.kovac@example.com'
  AND NOT EXISTS (
    SELECT 1 FROM health_entries he WHERE he.user_id = u.id AND he.entry_date = CURRENT_DATE
  );

INSERT INTO health_entries (user_id, entry_date, wellbeing_score, energy_level, stress_level, mood, symptoms, doctor_notes, created_at, updated_at, sleep_hours, sleep_quality)
SELECT u.id, CURRENT_DATE, 5, 50, 60, 'ok', 'headache', NULL, NOW(), NOW(), 5.5, 'poor'
FROM users u
WHERE u.email = 'nina.zupan@example.com'
  AND NOT EXISTS (
    SELECT 1 FROM health_entries he WHERE he.user_id = u.id AND he.entry_date = CURRENT_DATE
  );

INSERT INTO sleep_records (user_id, sleep_date, duration_minutes, quality_score, source)
SELECT u.id, CURRENT_DATE, 450, 8, 'manual'
FROM users u
WHERE u.email = 'ana.novak@example.com'
  AND NOT EXISTS (
    SELECT 1 FROM sleep_records sr WHERE sr.user_id = u.id AND sr.sleep_date = CURRENT_DATE
  );

INSERT INTO sleep_records (user_id, sleep_date, duration_minutes, quality_score, source)
SELECT u.id, CURRENT_DATE, 480, 9, 'wearable'
FROM users u
WHERE u.email = 'luka.horvat@example.com'
  AND NOT EXISTS (
    SELECT 1 FROM sleep_records sr WHERE sr.user_id = u.id AND sr.sleep_date = CURRENT_DATE
  );

INSERT INTO sleep_records (user_id, sleep_date, duration_minutes, quality_score, source)
SELECT u.id, CURRENT_DATE, 360, 6, 'manual'
FROM users u
WHERE u.email = 'maja.kovac@example.com'
  AND NOT EXISTS (
    SELECT 1 FROM sleep_records sr WHERE sr.user_id = u.id AND sr.sleep_date = CURRENT_DATE
  );

INSERT INTO sleep_records (user_id, sleep_date, duration_minutes, quality_score, source)
SELECT u.id, CURRENT_DATE, 330, 5, 'manual'
FROM users u
WHERE u.email = 'nina.zupan@example.com'
  AND NOT EXISTS (
    SELECT 1 FROM sleep_records sr WHERE sr.user_id = u.id AND sr.sleep_date = CURRENT_DATE
  );

INSERT INTO activity_logs (user_id, activity_date, steps, calories, heart_rate_avg, source)
SELECT u.id, CURRENT_DATE, 8000, 400, 110, 'fitbit'
FROM users u
WHERE u.email = 'ana.novak@example.com'
  AND NOT EXISTS (
    SELECT 1 FROM activity_logs al WHERE al.user_id = u.id AND al.activity_date = CURRENT_DATE
  );

INSERT INTO activity_logs (user_id, activity_date, steps, calories, heart_rate_avg, source)
SELECT u.id, CURRENT_DATE, 12000, 700, 125, 'watch'
FROM users u
WHERE u.email = 'luka.horvat@example.com'
  AND NOT EXISTS (
    SELECT 1 FROM activity_logs al WHERE al.user_id = u.id AND al.activity_date = CURRENT_DATE
  );

INSERT INTO activity_logs (user_id, activity_date, steps, calories, heart_rate_avg, source)
SELECT u.id, CURRENT_DATE, 3000, 150, 80, 'manual'
FROM users u
WHERE u.email = 'maja.kovac@example.com'
  AND NOT EXISTS (
    SELECT 1 FROM activity_logs al WHERE al.user_id = u.id AND al.activity_date = CURRENT_DATE
  );

INSERT INTO activity_logs (user_id, activity_date, steps, calories, heart_rate_avg, source)
SELECT u.id, CURRENT_DATE, 2000, 100, 78, 'phone'
FROM users u
WHERE u.email = 'nina.zupan@example.com'
  AND NOT EXISTS (
    SELECT 1 FROM activity_logs al WHERE al.user_id = u.id AND al.activity_date = CURRENT_DATE
  );

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Ventolin', '100mcg', 'As needed', 'Use as prescribed', NULL, NULL, NULL, 'MEDICATION', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'ana.novak@example.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Ventolin');

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Omega 3', '1000mg', 'Daily', 'Take with food', NULL, NULL, NULL, 'SUPPLEMENT', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'luka.horvat@example.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Omega 3');

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Amlodipine', '5mg', 'Daily', 'Take in the morning', NULL, NULL, NULL, 'MEDICATION', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'maja.kovac@example.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Amlodipine');

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Sumatriptan', '50mg', 'As needed', 'Use when migraine starts', NULL, NULL, NULL, 'MEDICATION', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'nina.zupan@example.com'
  AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.user_id = u.id AND m.name = 'Sumatriptan');

INSERT INTO dose_logs (medicine_id, scheduled_time, taken_time, status, note)
SELECT m.id, NOW() - INTERVAL '8 hours', NOW() - INTERVAL '8 hours', 'TAKEN', 'Morning dose'
FROM medicines m
JOIN users u ON u.id = m.user_id
WHERE u.email = 'ana.novak@example.com'
  AND m.name = 'Ventolin'
  AND NOT EXISTS (SELECT 1 FROM dose_logs d WHERE d.medicine_id = m.id AND d.status = 'TAKEN');

INSERT INTO dose_logs (medicine_id, scheduled_time, taken_time, status, note)
SELECT m.id, NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours', 'TAKEN', 'Breakfast'
FROM medicines m
JOIN users u ON u.id = m.user_id
WHERE u.email = 'luka.horvat@example.com'
  AND m.name = 'Omega 3'
  AND NOT EXISTS (SELECT 1 FROM dose_logs d WHERE d.medicine_id = m.id AND d.status = 'TAKEN');

INSERT INTO dose_logs (medicine_id, scheduled_time, taken_time, status, note)
SELECT m.id, NOW() - INTERVAL '20 hours', NOW() - INTERVAL '20 hours', 'TAKEN', 'Morning dose'
FROM medicines m
JOIN users u ON u.id = m.user_id
WHERE u.email = 'maja.kovac@example.com'
  AND m.name = 'Amlodipine'
  AND NOT EXISTS (SELECT 1 FROM dose_logs d WHERE d.medicine_id = m.id AND d.status = 'TAKEN');

INSERT INTO dose_logs (medicine_id, scheduled_time, taken_time, status, note)
SELECT m.id, NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours', 'TAKEN', 'PRN dose'
FROM medicines m
JOIN users u ON u.id = m.user_id
WHERE u.email = 'nina.zupan@example.com'
  AND m.name = 'Sumatriptan'
  AND NOT EXISTS (SELECT 1 FROM dose_logs d WHERE d.medicine_id = m.id AND d.status = 'TAKEN');

INSERT INTO health_shield_status (user_id, total_consistency_points, current_level, consecutive_failed_days, last_calculated_date, created_at, updated_at)
SELECT u.id, 120, 2, 0, CURRENT_DATE, NOW(), NOW()
FROM users u
WHERE u.email = 'ana.novak@example.com'
  AND NOT EXISTS (SELECT 1 FROM health_shield_status hs WHERE hs.user_id = u.id);

INSERT INTO health_shield_status (user_id, total_consistency_points, current_level, consecutive_failed_days, last_calculated_date, created_at, updated_at)
SELECT u.id, 300, 3, 0, CURRENT_DATE, NOW(), NOW()
FROM users u
WHERE u.email = 'luka.horvat@example.com'
  AND NOT EXISTS (SELECT 1 FROM health_shield_status hs WHERE hs.user_id = u.id);

INSERT INTO health_shield_status (user_id, total_consistency_points, current_level, consecutive_failed_days, last_calculated_date, created_at, updated_at)
SELECT u.id, 80, 1, 1, CURRENT_DATE, NOW(), NOW()
FROM users u
WHERE u.email = 'maja.kovac@example.com'
  AND NOT EXISTS (SELECT 1 FROM health_shield_status hs WHERE hs.user_id = u.id);

INSERT INTO health_shield_status (user_id, total_consistency_points, current_level, consecutive_failed_days, last_calculated_date, created_at, updated_at)
SELECT u.id, 50, 1, 2, CURRENT_DATE, NOW(), NOW()
FROM users u
WHERE u.email = 'nina.zupan@example.com'
  AND NOT EXISTS (SELECT 1 FROM health_shield_status hs WHERE hs.user_id = u.id);



