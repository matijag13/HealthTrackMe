-- Unified demo dataset for local development.
-- This migration clears the previous demo content seeded by V2/V3/V99
-- and replaces it with one richer dataset for one admin account and five demo users.

-- 0) Remove previously seeded app data so the database starts clean.
-- Do not reset identities here to avoid shifting IDs for already-cached clients.
TRUNCATE TABLE
    dose_logs,
    health_shield_daily_points,
    health_shield_status,
    activity_logs,
    sleep_records,
    health_entries,
    medicines,
    users
CASCADE;

-- 1) Insert demo accounts
INSERT INTO users (
    email,
    password_hash,
    first_name,
    last_name,
    role,
    gdpr_consent_accepted,
    gdpr_consent_accepted_at,
    created_at,
    updated_at,
    date_of_birth,
    user_type,
    medical_conditions,
    allergies,
    height,
    weight,
    blood_type,
    emergency_contact_name,
    emergency_contact_phone,
    doctor_name,
    doctor_clinic,
    doctor_phone,
    insurance_provider,
    insurance_policy_number,
    is_active
) VALUES
    (
        'admin@healthtrackme.local',
        '$2a$10$6wDFziOs3jO9MUAhxOZce.MX4W6/Ne/GbGqSzHVhD2F//LvHroIhm',
        'System',
        'Administrator',
        'ADMIN',
        TRUE,
        TIMESTAMP '2026-05-24 09:00:00',
        TIMESTAMP '2026-05-24 09:00:00',
        TIMESTAMP '2026-05-24 09:00:00',
        '1988-01-01',
        'HEALTHCARE_WORKER',
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        'Emergency Contact',
        '+38600000000',
        'Dr. Admin',
        'HealthTrackMe Clinic',
        '+38611111111',
        'Internal',
        'ADMIN-001',
        TRUE
    ),
    (
        'ana.novak@example.com',
        '$2a$10$s5.TkTZWa1V32slUzHPhROFnQGchGU2dcEy2BdsTJkfJ.ZhL5azq2',
        'Ana',
        'Novak',
        'USER',
        TRUE,
        TIMESTAMP '2026-05-24 09:10:00',
        TIMESTAMP '2026-05-24 09:10:00',
        TIMESTAMP '2026-05-24 09:10:00',
        '1994-03-10',
        'PATIENT',
        'mild asthma; seasonal allergies',
        'peanuts',
        168,
        62,
        'A+',
        'Mark Novak',
        '+38640111001',
        'Dr. Maja Kranjc',
        'Ljubljana Health Center',
        '+38615100011',
        'HealthPlus',
        'HP-AN-2044',
        TRUE
    ),
    (
        'luka.horvat@example.com',
        '$2a$10$s5.TkTZWa1V32slUzHPhROFnQGchGU2dcEy2BdsTJkfJ.ZhL5azq2',
        'Luka',
        'Horvat',
        'USER',
        TRUE,
        TIMESTAMP '2026-05-24 09:15:00',
        TIMESTAMP '2026-05-24 09:15:00',
        TIMESTAMP '2026-05-24 09:15:00',
        '1990-11-22',
        'ATHLETE',
        'none',
        NULL,
        184,
        79,
        'O+',
        'Petra Horvat',
        '+38640111002',
        'Dr. Sara Zajc',
        'Sports Medicine Center',
        '+38615100022',
        'FitCare',
        'FC-LH-7731',
        TRUE
    ),
    (
        'maja.kovac@example.com',
        '$2a$10$s5.TkTZWa1V32slUzHPhROFnQGchGU2dcEy2BdsTJkfJ.ZhL5azq2',
        'Maja',
        'Kovač',
        'USER',
        TRUE,
        TIMESTAMP '2026-05-24 09:20:00',
        TIMESTAMP '2026-05-24 09:20:00',
        TIMESTAMP '2026-05-24 09:20:00',
        '1958-07-18',
        'ELDERLY',
        'hypertension; osteoarthritis',
        'penicillin',
        160,
        71,
        'B-',
        'Nina Kovač',
        '+38640111003',
        'Dr. Tina Kosem',
        'City Polyclinic',
        '+38615100033',
        'SeniorHealth',
        'SH-MK-1098',
        TRUE
    ),
    (
        'nina.zupan@example.com',
        '$2a$10$s5.TkTZWa1V32slUzHPhROFnQGchGU2dcEy2BdsTJkfJ.ZhL5azq2',
        'Nina',
        'Župan',
        'USER',
        TRUE,
        TIMESTAMP '2026-05-24 09:25:00',
        TIMESTAMP '2026-05-24 09:25:00',
        TIMESTAMP '2026-05-24 09:25:00',
        '1987-05-04',
        'PATIENT',
        'migraine',
        'latex',
        170,
        58,
        'AB+',
        'Matej Župan',
        '+38640111004',
        'Dr. Eva Sterle',
        'Neurology Clinic',
        '+38615100044',
        'BlueShield',
        'BS-NZ-3322',
        TRUE
    ),
    (
        'sara@demo.com',
        '$2a$10$s5.TkTZWa1V32slUzHPhROFnQGchGU2dcEy2BdsTJkfJ.ZhL5azq2',
        'Sara',
        'Lee',
        'USER',
        TRUE,
        TIMESTAMP '2026-05-24 09:30:00',
        TIMESTAMP '2026-05-24 09:30:00',
        TIMESTAMP '2026-05-24 09:30:00',
        '1993-09-30',
        'PATIENT',
        'type 2 diabetes',
        'none',
        165,
        66,
        'A-',
        'Mia Lee',
        '+38640111005',
        'Dr. Andrej Novak',
        'Endocrinology Unit',
        '+38615100055',
        'MediCare',
        'MC-SL-5509',
        TRUE
    )
ON CONFLICT (email) DO NOTHING;

-- 2) Medicines
INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Ventolin Inhaler', '100mcg', 'As needed', 'Asthma relief', CURRENT_DATE - INTERVAL '180 days', NULL, 'dry mouth', 'MEDICATION', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'ana.novak@example.com';

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Cetirizine', '10mg', 'Once daily', 'Seasonal allergies', CURRENT_DATE - INTERVAL '90 days', NULL, 'sleepiness', 'MEDICATION', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'ana.novak@example.com';

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Omega-3', '1000mg', 'Once daily', 'Recovery and heart health', CURRENT_DATE - INTERVAL '150 days', NULL, NULL, 'SUPPLEMENT', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'luka.horvat@example.com';

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Magnesium', '400mg', 'Once daily', 'Muscle recovery', CURRENT_DATE - INTERVAL '120 days', NULL, NULL, 'SUPPLEMENT', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'luka.horvat@example.com';

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Amlodipine', '5mg', 'Once daily', 'Blood pressure control', CURRENT_DATE - INTERVAL '300 days', NULL, 'dizziness', 'MEDICATION', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'maja.kovac@example.com';

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Paracetamol', '500mg', 'As needed', 'Joint pain', CURRENT_DATE - INTERVAL '45 days', NULL, NULL, 'MEDICATION', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'maja.kovac@example.com';

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Sumatriptan', '50mg', 'As needed', 'Migraine attacks', CURRENT_DATE - INTERVAL '210 days', NULL, 'drowsiness', 'MEDICATION', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'nina.zupan@example.com';

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Melatonin', '3mg', 'Nightly', 'Sleep support', CURRENT_DATE - INTERVAL '75 days', NULL, NULL, 'SUPPLEMENT', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'nina.zupan@example.com';

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Metformin', '500mg', 'Twice daily', 'Blood sugar control', CURRENT_DATE - INTERVAL '365 days', NULL, 'stomach upset', 'MEDICATION', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'sara@demo.com';

INSERT INTO medicines (user_id, name, dosage, frequency, reason, start_date, end_date, side_effects, item_type, is_active, created_at, updated_at)
SELECT u.id, 'Vitamin D', '1000IU', 'Once daily', 'Bone and immune support', CURRENT_DATE - INTERVAL '200 days', NULL, NULL, 'VITAMIN', TRUE, NOW(), NOW()
FROM users u
WHERE u.email = 'sara@demo.com';

-- 3) Health entries: 21-day history for each demo user
INSERT INTO health_entries (
    user_id, entry_date, wellbeing_score, energy_level, stress_level, mood, symptoms, doctor_notes,
    sleep_hours, sleep_quality, weight, heart_rate, systolic_bp, diastolic_bp, blood_glucose,
    body_temperature, spo2, water_intake_ml, calories_consumed, alcohol_units, pain_level,
    bedtime, wake_time, sleep_quality_stars, tags, created_at, updated_at
)
SELECT
    u.id,
    gs.day_ts::date,
    6 + (gs.n::int % 4),
    54 + (gs.n::int % 6) * 3,
    18 + (gs.n::int % 5) * 4,
    CASE (gs.n::int % 5)
        WHEN 0 THEN 'calm'
        WHEN 1 THEN 'focused'
        WHEN 2 THEN 'good'
        WHEN 3 THEN 'tired'
        ELSE 'motivated'
    END,
    CASE
        WHEN gs.n::int % 7 = 0 THEN 'seasonal symptoms'
        WHEN gs.n::int % 4 = 0 THEN 'mild fatigue'
        ELSE NULL
    END,
    CASE WHEN gs.n::int % 6 = 0 THEN 'Track routine and keep logging.' ELSE 'Stable day.' END,
    ROUND((6.7 + ((gs.n::int % 3) * 0.3))::numeric, 1),
    CASE (gs.n::int % 3)
        WHEN 0 THEN 'GOOD'
        WHEN 1 THEN 'FAIR'
        ELSE 'EXCELLENT'
    END,
    62 + (gs.n::int % 3),
    72 + (gs.n::int % 11),
    112 + (gs.n::int % 6),
    72 + (gs.n::int % 5),
    NULL,
    36.5 + ((gs.n::int % 3) * 0.1),
    97 + (gs.n::int % 3),
    1750 + (gs.n::int % 5) * 110,
    1900 + (gs.n::int % 4) * 120,
    0.0,
    CASE WHEN gs.n::int % 5 = 0 THEN 2 ELSE 1 END,
    CASE (gs.n::int % 3)
        WHEN 0 THEN TIME '22:15'
        WHEN 1 THEN TIME '22:45'
        ELSE TIME '23:00'
    END,
    CASE (gs.n::int % 3)
        WHEN 0 THEN TIME '06:30'
        WHEN 1 THEN TIME '06:45'
        ELSE TIME '07:00'
    END,
    3 + (gs.n::int % 3),
    CASE (gs.n::int % 4)
        WHEN 0 THEN 'daily routine'
        WHEN 1 THEN 'sleep tracking'
        WHEN 2 THEN 'medicine reminder'
        ELSE 'wellbeing log'
    END,
    NOW(),
    NOW()
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '20 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'ana.novak@example.com';

INSERT INTO health_entries (
    user_id, entry_date, wellbeing_score, energy_level, stress_level, mood, symptoms, doctor_notes,
    sleep_hours, sleep_quality, weight, heart_rate, systolic_bp, diastolic_bp, blood_glucose,
    body_temperature, spo2, water_intake_ml, calories_consumed, alcohol_units, pain_level,
    bedtime, wake_time, sleep_quality_stars, tags, created_at, updated_at
)
SELECT
    u.id,
    gs.day_ts::date,
    7 + (gs.n::int % 3),
    72 + (gs.n::int % 5) * 4,
    10 + (gs.n::int % 5) * 2,
    CASE (gs.n::int % 5)
        WHEN 0 THEN 'energized'
        WHEN 1 THEN 'focused'
        WHEN 2 THEN 'recovered'
        WHEN 3 THEN 'strong'
        ELSE 'ready'
    END,
    CASE WHEN gs.n::int % 6 = 0 THEN 'muscle soreness' ELSE NULL END,
    CASE WHEN gs.n::int % 4 = 0 THEN 'Hydration and recovery are on track.' ELSE 'Training load looks good.' END,
    ROUND((79 + ((gs.n::int % 3) * 0.2))::numeric, 1),
    58 + (gs.n::int % 13),
    118 + (gs.n::int % 5),
    72 + (gs.n::int % 4),
    NULL,
    36.4 + ((gs.n::int % 2) * 0.1),
    97 + (gs.n::int % 2),
    2500 + (gs.n::int % 4) * 120,
    2400 + (gs.n::int % 4) * 150,
    0.0,
    0,
    CASE (gs.n::int % 3)
        WHEN 0 THEN TIME '22:00'
        WHEN 1 THEN TIME '22:20'
        ELSE TIME '22:40'
    END,
    CASE (gs.n::int % 3)
        WHEN 0 THEN TIME '06:00'
        WHEN 1 THEN TIME '06:15'
        ELSE TIME '06:30'
    END,
    4 + (gs.n::int % 2),
    CASE (gs.n::int % 4)
        WHEN 0 THEN 'training'
        WHEN 1 THEN 'recovery'
        WHEN 2 THEN 'nutrition'
        ELSE 'performance'
    END,
    NOW(),
    NOW()
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '20 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'luka.horvat@example.com';

INSERT INTO health_entries (
    user_id, entry_date, wellbeing_score, energy_level, stress_level, mood, symptoms, doctor_notes,
    sleep_hours, sleep_quality, weight, heart_rate, systolic_bp, diastolic_bp, blood_glucose,
    body_temperature, spo2, water_intake_ml, calories_consumed, alcohol_units, pain_level,
    bedtime, wake_time, sleep_quality_stars, tags, created_at, updated_at
)
SELECT
    u.id,
    gs.day_ts::date,
    5 + (gs.n::int % 4),
    48 + (gs.n::int % 5) * 3,
    22 + (gs.n::int % 5) * 4,
    CASE (gs.n::int % 5)
        WHEN 0 THEN 'steady'
        WHEN 1 THEN 'rested'
        WHEN 2 THEN 'tired'
        WHEN 3 THEN 'comfortable'
        ELSE 'calm'
    END,
    CASE
        WHEN gs.n::int % 5 = 0 THEN 'joint stiffness'
        WHEN gs.n::int % 8 = 0 THEN 'morning aches'
        ELSE NULL
    END,
    CASE WHEN gs.n::int % 5 = 0 THEN 'Keep up the walking routine.' ELSE 'Blood pressure plan is consistent.' END,
    ROUND((71 + ((gs.n::int % 2) * 0.4))::numeric, 1),
    68 + (gs.n::int % 9),
    132 + (gs.n::int % 6),
    76 + (gs.n::int % 5),
    NULL,
    36.6 + ((gs.n::int % 3) * 0.1),
    96 + (gs.n::int % 3),
    1800 + (gs.n::int % 4) * 100,
    1650 + (gs.n::int % 4) * 120,
    0.0,
    CASE WHEN gs.n::int % 4 = 0 THEN 3 ELSE 1 END,
    CASE (gs.n::int % 3)
        WHEN 0 THEN TIME '21:45'
        WHEN 1 THEN TIME '22:00'
        ELSE TIME '22:15'
    END,
    CASE (gs.n::int % 3)
        WHEN 0 THEN TIME '06:15'
        WHEN 1 THEN TIME '06:30'
        ELSE TIME '06:45'
    END,
    3 + (gs.n::int % 2),
    CASE (gs.n::int % 4)
        WHEN 0 THEN 'mobility'
        WHEN 1 THEN 'blood pressure'
        WHEN 2 THEN 'pain management'
        ELSE 'routine'
    END,
    NOW(),
    NOW()
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '20 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'maja.kovac@example.com';

INSERT INTO health_entries (
    user_id, entry_date, wellbeing_score, energy_level, stress_level, mood, symptoms, doctor_notes,
    sleep_hours, sleep_quality, weight, heart_rate, systolic_bp, diastolic_bp, blood_glucose,
    body_temperature, spo2, water_intake_ml, calories_consumed, alcohol_units, pain_level,
    bedtime, wake_time, sleep_quality_stars, tags, created_at, updated_at
)
SELECT
    u.id,
    gs.day_ts::date,
    6 + (gs.n::int % 4),
    52 + (gs.n::int % 6) * 3,
    20 + (gs.n::int % 5) * 3,
    CASE (gs.n::int % 5)
        WHEN 0 THEN 'relaxed'
        WHEN 1 THEN 'okay'
        WHEN 2 THEN 'focused'
        WHEN 3 THEN 'headache-free'
        ELSE 'sleepy'
    END,
    CASE
        WHEN gs.n::int % 6 = 0 THEN 'migraine aura'
        WHEN gs.n::int % 9 = 0 THEN 'light sensitivity'
        ELSE NULL
    END,
    CASE WHEN gs.n::int % 5 = 0 THEN 'Watch triggers and keep hydration up.' ELSE 'Migraine diary updated.' END,
    ROUND((6.0 + ((gs.n::int % 4) * 0.3))::numeric, 1),
    CASE (gs.n::int % 3)
        WHEN 0 THEN 'GOOD'
        WHEN 1 THEN 'FAIR'
        ELSE 'POOR'
    END,
    58 + (gs.n::int % 2),
    74 + (gs.n::int % 10),
    108 + (gs.n::int % 5),
    70 + (gs.n::int % 4),
    NULL,
    36.5 + ((gs.n::int % 3) * 0.1),
    97 + (gs.n::int % 3),
    1700 + (gs.n::int % 4) * 100,
    1750 + (gs.n::int % 4) * 120,
    0.0,
    CASE WHEN gs.n::int % 6 = 0 THEN 2 ELSE 1 END,
    CASE (gs.n::int % 3)
        WHEN 0 THEN TIME '22:30'
        WHEN 1 THEN TIME '22:45'
        ELSE TIME '23:00'
    END,
    CASE (gs.n::int % 3)
        WHEN 0 THEN TIME '06:45'
        WHEN 1 THEN TIME '07:00'
        ELSE TIME '07:15'
    END,
    3 + (gs.n::int % 3),
    CASE (gs.n::int % 4)
        WHEN 0 THEN 'migraine diary'
        WHEN 1 THEN 'sleep tracking'
        WHEN 2 THEN 'work stress'
        ELSE 'wellbeing log'
    END,
    NOW(),
    NOW()
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '20 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'nina.zupan@example.com';

INSERT INTO health_entries (
    user_id, entry_date, wellbeing_score, energy_level, stress_level, mood, symptoms, doctor_notes,
    sleep_hours, sleep_quality, weight, heart_rate, systolic_bp, diastolic_bp, blood_glucose,
    body_temperature, spo2, water_intake_ml, calories_consumed, alcohol_units, pain_level,
    bedtime, wake_time, sleep_quality_stars, tags, created_at, updated_at
)
SELECT
    u.id,
    gs.day_ts::date,
    6 + (gs.n::int % 4),
    56 + (gs.n::int % 5) * 4,
    16 + (gs.n::int % 5) * 3,
    CASE (gs.n::int % 5)
        WHEN 0 THEN 'productive'
        WHEN 1 THEN 'balanced'
        WHEN 2 THEN 'calm'
        WHEN 3 THEN 'busy'
        ELSE 'sleepy'
    END,
    CASE
        WHEN gs.n::int % 5 = 0 THEN 'low energy'
        WHEN gs.n::int % 8 = 0 THEN 'blood sugar check'
        ELSE NULL
    END,
    CASE WHEN gs.n::int % 4 = 0 THEN 'Consistency is improving.' ELSE 'Keep logging meals and meds.' END,
    ROUND((6.6 + ((gs.n::int % 3) * 0.3))::numeric, 1),
    CASE (gs.n::int % 3)
        WHEN 0 THEN 'GOOD'
        WHEN 1 THEN 'FAIR'
        ELSE 'EXCELLENT'
    END,
    66 + (gs.n::int % 2),
    76 + (gs.n::int % 10),
    118 + (gs.n::int % 5),
    74 + (gs.n::int % 4),
    5.4 + ((gs.n::int % 4) * 0.2),
    36.5 + ((gs.n::int % 3) * 0.1),
    97 + (gs.n::int % 3),
    1900 + (gs.n::int % 4) * 130,
    1800 + (gs.n::int % 4) * 120,
    0.0,
    CASE WHEN gs.n::int % 6 = 0 THEN 2 ELSE 1 END,
    CASE (gs.n::int % 3)
        WHEN 0 THEN TIME '22:00'
        WHEN 1 THEN TIME '22:30'
        ELSE TIME '22:45'
    END,
    CASE (gs.n::int % 3)
        WHEN 0 THEN TIME '06:00'
        WHEN 1 THEN TIME '06:15'
        ELSE TIME '06:30'
    END,
    3 + (gs.n::int % 3),
    CASE (gs.n::int % 4)
        WHEN 0 THEN 'glucose log'
        WHEN 1 THEN 'meal tracking'
        WHEN 2 THEN 'routine'
        ELSE 'health shield'
    END,
    NOW(),
    NOW()
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '20 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'sara@demo.com';

-- 4) Sleep history (14 days)
INSERT INTO sleep_records (user_id, sleep_date, duration_minutes, quality_score, source)
SELECT u.id, gs.day_ts::date, 405 + (gs.n::int % 4) * 15, 7 + (gs.n::int % 3), 'manual'
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '13 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'ana.novak@example.com';

INSERT INTO sleep_records (user_id, sleep_date, duration_minutes, quality_score, source)
SELECT u.id, gs.day_ts::date, 455 + (gs.n::int % 4) * 10, 8 + (gs.n::int % 2), 'watch'
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '13 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'luka.horvat@example.com';

INSERT INTO sleep_records (user_id, sleep_date, duration_minutes, quality_score, source)
SELECT u.id, gs.day_ts::date, 360 + (gs.n::int % 4) * 12, 5 + (gs.n::int % 3), 'manual'
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '13 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'maja.kovac@example.com';

INSERT INTO sleep_records (user_id, sleep_date, duration_minutes, quality_score, source)
SELECT u.id, gs.day_ts::date, 340 + (gs.n::int % 4) * 10, 4 + (gs.n::int % 3), 'phone'
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '13 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'nina.zupan@example.com';

INSERT INTO sleep_records (user_id, sleep_date, duration_minutes, quality_score, source)
SELECT u.id, gs.day_ts::date, 390 + (gs.n::int % 4) * 12, 6 + (gs.n::int % 3), 'manual'
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '13 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'sara@demo.com';

-- 5) Activity history (10 records per user)
INSERT INTO activity_logs (user_id, activity_date, steps, calories, heart_rate_avg, source)
SELECT u.id, gs.day_ts::date, 6500 + (gs.n::int % 5) * 450, 260 + (gs.n::int % 4) * 40, 84 + (gs.n::int % 5) * 2, 'fitbit'
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '18 days', CURRENT_DATE, INTERVAL '2 days') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'ana.novak@example.com';

INSERT INTO activity_logs (user_id, activity_date, steps, calories, heart_rate_avg, source)
SELECT u.id, gs.day_ts::date, 10800 + (gs.n::int % 5) * 650, 620 + (gs.n::int % 4) * 55, 112 + (gs.n::int % 6) * 3, 'watch'
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '18 days', CURRENT_DATE, INTERVAL '2 days') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'luka.horvat@example.com';

INSERT INTO activity_logs (user_id, activity_date, steps, calories, heart_rate_avg, source)
SELECT u.id, gs.day_ts::date, 2800 + (gs.n::int % 5) * 380, 160 + (gs.n::int % 4) * 25, 78 + (gs.n::int % 5) * 2, 'manual'
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '18 days', CURRENT_DATE, INTERVAL '2 days') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'maja.kovac@example.com';

INSERT INTO activity_logs (user_id, activity_date, steps, calories, heart_rate_avg, source)
SELECT u.id, gs.day_ts::date, 3900 + (gs.n::int % 5) * 420, 210 + (gs.n::int % 4) * 30, 82 + (gs.n::int % 5) * 2, 'phone'
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '18 days', CURRENT_DATE, INTERVAL '2 days') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'nina.zupan@example.com';

INSERT INTO activity_logs (user_id, activity_date, steps, calories, heart_rate_avg, source)
SELECT u.id, gs.day_ts::date, 5200 + (gs.n::int % 5) * 430, 240 + (gs.n::int % 4) * 35, 86 + (gs.n::int % 5) * 2, 'phone'
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '18 days', CURRENT_DATE, INTERVAL '2 days') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'sara@demo.com';

-- 6) Dose logs
INSERT INTO dose_logs (medicine_id, scheduled_time, taken_time, status, note)
SELECT m.id, gs.day_ts::timestamp + TIME '08:00',
       CASE WHEN gs.n::int % 5 = 0 THEN NULL ELSE gs.day_ts::timestamp + TIME '08:00' + make_interval(mins => (gs.n::int % 40)) END,
       CASE WHEN gs.n::int % 5 = 0 THEN 'MISSED' ELSE 'TAKEN' END,
       'Morning routine'
FROM medicines m
JOIN users u ON u.id = m.user_id
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '14 days', CURRENT_DATE, INTERVAL '2 days') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'ana.novak@example.com' AND m.name = 'Ventolin Inhaler';

INSERT INTO dose_logs (medicine_id, scheduled_time, taken_time, status, note)
SELECT m.id, gs.day_ts::timestamp + TIME '20:00',
       CASE WHEN gs.n::int % 6 = 0 THEN NULL ELSE gs.day_ts::timestamp + TIME '20:00' + make_interval(mins => (gs.n::int % 25)) END,
       CASE WHEN gs.n::int % 6 = 0 THEN 'MISSED' ELSE 'TAKEN' END,
       'Allergy support'
FROM medicines m
JOIN users u ON u.id = m.user_id
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '14 days', CURRENT_DATE, INTERVAL '2 days') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'ana.novak@example.com' AND m.name = 'Cetirizine';

INSERT INTO dose_logs (medicine_id, scheduled_time, taken_time, status, note)
SELECT m.id, gs.day_ts::timestamp + TIME '07:30',
       gs.day_ts::timestamp + TIME '07:30' + make_interval(mins => (gs.n::int % 20)),
       'TAKEN',
       'Post-training recovery'
FROM medicines m
JOIN users u ON u.id = m.user_id
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '14 days', CURRENT_DATE, INTERVAL '2 days') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'luka.horvat@example.com' AND m.name = 'Omega-3';

INSERT INTO dose_logs (medicine_id, scheduled_time, taken_time, status, note)
SELECT m.id, gs.day_ts::timestamp + TIME '21:00',
       CASE WHEN gs.n::int % 5 = 0 THEN NULL ELSE gs.day_ts::timestamp + TIME '21:00' + make_interval(mins => (gs.n::int % 15)) END,
       CASE WHEN gs.n::int % 5 = 0 THEN 'MISSED' ELSE 'TAKEN' END,
       'Recovery supplement'
FROM medicines m
JOIN users u ON u.id = m.user_id
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '14 days', CURRENT_DATE, INTERVAL '2 days') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'luka.horvat@example.com' AND m.name = 'Magnesium';

INSERT INTO dose_logs (medicine_id, scheduled_time, taken_time, status, note)
SELECT m.id, gs.day_ts::timestamp + TIME '08:00',
       gs.day_ts::timestamp + TIME '08:00' + make_interval(mins => (gs.n::int % 30)),
       'TAKEN',
       'Blood pressure control'
FROM medicines m
JOIN users u ON u.id = m.user_id
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '14 days', CURRENT_DATE, INTERVAL '2 days') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'maja.kovac@example.com' AND m.name = 'Amlodipine';

INSERT INTO dose_logs (medicine_id, scheduled_time, taken_time, status, note)
SELECT m.id, gs.day_ts::timestamp + TIME '13:00',
       CASE WHEN gs.n::int % 4 = 0 THEN NULL ELSE gs.day_ts::timestamp + TIME '13:00' + make_interval(mins => (gs.n::int % 20)) END,
       CASE WHEN gs.n::int % 4 = 0 THEN 'SKIPPED' ELSE 'TAKEN' END,
       'As needed for pain'
FROM medicines m
JOIN users u ON u.id = m.user_id
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '14 days', CURRENT_DATE, INTERVAL '3 days') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'maja.kovac@example.com' AND m.name = 'Paracetamol';

INSERT INTO dose_logs (medicine_id, scheduled_time, taken_time, status, note)
SELECT m.id, gs.day_ts::timestamp + TIME '10:00',
       CASE WHEN gs.n::int % 5 = 0 THEN NULL ELSE gs.day_ts::timestamp + TIME '10:00' + make_interval(mins => (gs.n::int % 45)) END,
       CASE WHEN gs.n::int % 5 = 0 THEN 'MISSED' ELSE 'TAKEN' END,
       'Migraine rescue plan'
FROM medicines m
JOIN users u ON u.id = m.user_id
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '14 days', CURRENT_DATE, INTERVAL '3 days') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'nina.zupan@example.com' AND m.name = 'Sumatriptan';

INSERT INTO dose_logs (medicine_id, scheduled_time, taken_time, status, note)
SELECT m.id, gs.day_ts::timestamp + TIME '22:00',
       gs.day_ts::timestamp + TIME '22:00' + make_interval(mins => (gs.n::int % 20)),
       'TAKEN',
       'Sleep routine'
FROM medicines m
JOIN users u ON u.id = m.user_id
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '14 days', CURRENT_DATE, INTERVAL '2 days') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'nina.zupan@example.com' AND m.name = 'Melatonin';

INSERT INTO dose_logs (medicine_id, scheduled_time, taken_time, status, note)
SELECT m.id, gs.day_ts::timestamp + TIME '08:00',
       gs.day_ts::timestamp + TIME '08:00' + make_interval(mins => (gs.n::int % 30)),
       'TAKEN',
       'Morning dose'
FROM medicines m
JOIN users u ON u.id = m.user_id
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '14 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'sara@demo.com' AND m.name = 'Metformin';

INSERT INTO dose_logs (medicine_id, scheduled_time, taken_time, status, note)
SELECT m.id, gs.day_ts::timestamp + TIME '08:30',
       gs.day_ts::timestamp + TIME '08:30' + make_interval(mins => (gs.n::int % 20)),
       'TAKEN',
       'Vitamin support'
FROM medicines m
JOIN users u ON u.id = m.user_id
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '14 days', CURRENT_DATE, INTERVAL '2 days') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'sara@demo.com' AND m.name = 'Vitamin D';

-- 7) Health Shield summary and daily points
INSERT INTO health_shield_status (user_id, total_consistency_points, current_level, consecutive_failed_days, last_calculated_date, created_at, updated_at)
SELECT u.id, 420, 5, 0, CURRENT_DATE, NOW(), NOW()
FROM users u WHERE u.email = 'ana.novak@example.com';

INSERT INTO health_shield_status (user_id, total_consistency_points, current_level, consecutive_failed_days, last_calculated_date, created_at, updated_at)
SELECT u.id, 610, 6, 0, CURRENT_DATE, NOW(), NOW()
FROM users u WHERE u.email = 'luka.horvat@example.com';

INSERT INTO health_shield_status (user_id, total_consistency_points, current_level, consecutive_failed_days, last_calculated_date, created_at, updated_at)
SELECT u.id, 330, 4, 1, CURRENT_DATE, NOW(), NOW()
FROM users u WHERE u.email = 'maja.kovac@example.com';

INSERT INTO health_shield_status (user_id, total_consistency_points, current_level, consecutive_failed_days, last_calculated_date, created_at, updated_at)
SELECT u.id, 295, 4, 2, CURRENT_DATE, NOW(), NOW()
FROM users u WHERE u.email = 'nina.zupan@example.com';

INSERT INTO health_shield_status (user_id, total_consistency_points, current_level, consecutive_failed_days, last_calculated_date, created_at, updated_at)
SELECT u.id, 515, 5, 0, CURRENT_DATE, NOW(), NOW()
FROM users u WHERE u.email = 'sara@demo.com';

INSERT INTO health_shield_daily_points (
    user_id, calculation_date, supplements_points, sleep_points, activity_points, wellbeing_points,
    symptoms_points, routine_stability_points, penalty_points, total_daily_points, completed_habits_count,
    created_at, updated_at
)
SELECT
    u.id,
    gs.day_ts::date,
    12 + (gs.n::int % 3),
    10 + (gs.n::int % 4),
    8 + (gs.n::int % 4),
    10 + (gs.n::int % 3),
    6 + (gs.n::int % 2),
    8 + (gs.n::int % 3),
    CASE WHEN gs.n::int % 6 = 0 THEN 3 ELSE 0 END,
    (12 + (gs.n::int % 3)) + (10 + (gs.n::int % 4)) + (8 + (gs.n::int % 4)) + (10 + (gs.n::int % 3)) + (6 + (gs.n::int % 2)) + (8 + (gs.n::int % 3)) - CASE WHEN gs.n::int % 6 = 0 THEN 3 ELSE 0 END,
    4 + (gs.n::int % 3),
    NOW(),
    NOW()
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'ana.novak@example.com';

INSERT INTO health_shield_daily_points (
    user_id, calculation_date, supplements_points, sleep_points, activity_points, wellbeing_points,
    symptoms_points, routine_stability_points, penalty_points, total_daily_points, completed_habits_count,
    created_at, updated_at
)
SELECT
    u.id,
    gs.day_ts::date,
    15 + (gs.n::int % 3),
    12 + (gs.n::int % 4),
    15 + (gs.n::int % 4),
    11 + (gs.n::int % 3),
    8,
    10 + (gs.n::int % 3),
    CASE WHEN gs.n::int % 8 = 0 THEN 2 ELSE 0 END,
    (15 + (gs.n::int % 3)) + (12 + (gs.n::int % 4)) + (15 + (gs.n::int % 4)) + (11 + (gs.n::int % 3)) + 8 + (10 + (gs.n::int % 3)) - CASE WHEN gs.n::int % 8 = 0 THEN 2 ELSE 0 END,
    5 + (gs.n::int % 2),
    NOW(),
    NOW()
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'luka.horvat@example.com';

INSERT INTO health_shield_daily_points (
    user_id, calculation_date, supplements_points, sleep_points, activity_points, wellbeing_points,
    symptoms_points, routine_stability_points, penalty_points, total_daily_points, completed_habits_count,
    created_at, updated_at
)
SELECT
    u.id,
    gs.day_ts::date,
    8 + (gs.n::int % 3),
    9 + (gs.n::int % 4),
    6 + (gs.n::int % 3),
    8 + (gs.n::int % 3),
    5 + (gs.n::int % 2),
    9 + (gs.n::int % 2),
    CASE WHEN gs.n::int % 5 = 0 THEN 4 ELSE 1 END,
    (8 + (gs.n::int % 3)) + (9 + (gs.n::int % 4)) + (6 + (gs.n::int % 3)) + (8 + (gs.n::int % 3)) + (5 + (gs.n::int % 2)) + (9 + (gs.n::int % 2)) - CASE WHEN gs.n::int % 5 = 0 THEN 4 ELSE 1 END,
    3 + (gs.n::int % 3),
    NOW(),
    NOW()
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'maja.kovac@example.com';

INSERT INTO health_shield_daily_points (
    user_id, calculation_date, supplements_points, sleep_points, activity_points, wellbeing_points,
    symptoms_points, routine_stability_points, penalty_points, total_daily_points, completed_habits_count,
    created_at, updated_at
)
SELECT
    u.id,
    gs.day_ts::date,
    9 + (gs.n::int % 3),
    8 + (gs.n::int % 4),
    7 + (gs.n::int % 3),
    9 + (gs.n::int % 3),
    5 + (gs.n::int % 2),
    8 + (gs.n::int % 3),
    CASE WHEN gs.n::int % 7 = 0 THEN 3 ELSE 1 END,
    (9 + (gs.n::int % 3)) + (8 + (gs.n::int % 4)) + (7 + (gs.n::int % 3)) + (9 + (gs.n::int % 3)) + (5 + (gs.n::int % 2)) + (8 + (gs.n::int % 3)) - CASE WHEN gs.n::int % 7 = 0 THEN 3 ELSE 1 END,
    3 + (gs.n::int % 2),
    NOW(),
    NOW()
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'nina.zupan@example.com';

INSERT INTO health_shield_daily_points (
    user_id, calculation_date, supplements_points, sleep_points, activity_points, wellbeing_points,
    symptoms_points, routine_stability_points, penalty_points, total_daily_points, completed_habits_count,
    created_at, updated_at
)
SELECT
    u.id,
    gs.day_ts::date,
    14 + (gs.n::int % 3),
    11 + (gs.n::int % 4),
    9 + (gs.n::int % 4),
    10 + (gs.n::int % 3),
    7 + (gs.n::int % 2),
    9 + (gs.n::int % 3),
    CASE WHEN gs.n::int % 6 = 0 THEN 2 ELSE 0 END,
    (14 + (gs.n::int % 3)) + (11 + (gs.n::int % 4)) + (9 + (gs.n::int % 4)) + (10 + (gs.n::int % 3)) + (7 + (gs.n::int % 2)) + (9 + (gs.n::int % 3)) - CASE WHEN gs.n::int % 6 = 0 THEN 2 ELSE 0 END,
    4 + (gs.n::int % 2),
    NOW(),
    NOW()
FROM users u
CROSS JOIN generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, INTERVAL '1 day') WITH ORDINALITY AS gs(day_ts, n)
WHERE u.email = 'sara@demo.com';

