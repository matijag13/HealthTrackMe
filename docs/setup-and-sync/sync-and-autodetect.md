# Syncing & Autoâ€‘detection â€” how it works and what to do

This explains, in plain terms, how HealthTrackMe gets your steps / heartâ€‘rate /
sleep / walks onto the dashboard, **what you (and testers) must do for it to
work**, and how the automatic walk/run + sleep detection behaves.

---

## 1. The data pipeline (how sync works)

```
 Phone sensor / wearable â”€â”€â–º Health Connect (Android) â”€â”€â–º HealthTrackMe app â”€â”€â–º Backend (Railway) â”€â”€â–º Dashboard
        steps, HR,            the shared onâ€‘device          reads permitted        stores one entry        Activity / Sleep /
        sleep, workouts       health database               data, uploads it       per day (idempotent)     Vitals cards
```

Key points:
- The app **does not invent data** â€” it reads whatever is in **Health Connect**.
  If Health Connect is empty, sync has nothing to upload and the dashboard stays
  empty. **This is the #1 reason "sync does nothing."**
- **Vitals** (HR / sleep / calories) are uploaded **per calendar day** and
  *upserted* â€” reâ€‘syncing the same day updates one row, never piles up duplicates.
- **Steps** are uploaded as a dailyâ€‘total "WALKING" activity; **workouts** are
  uploaded as individual sessions.
- Sync runs: on app open, every ~2 min while open, on resume, and every ~15 min
  in the background (WorkManager). The **Sync** button on the Wearables screen
  forces a backfill of at least the last 7 days.

---

## 2. What you MUST do for sync to work (checklist)

1. **Install the latest build.** Testers get it from **Firebase App
   Distribution** (a new build is published on every push to `develop`). Testing
   an old APK is the same as testing none of the fixes â€” always update first.
2. **Sign in.** If login fails, every API call (including sync) is rejected and
   sync silently does nothing. See Â§6 for the Googleâ€‘signâ€‘in server config.
3. **Grant Health Connect permission** when prompted (Wearables â†’ Connect / Sync,
   or the Settings toggles).
4. **Have a data source.** Either:
   - a wearable / Samsung Health / Google Fit that writes into Health Connect, **or**
   - turn on **Settings â†’ "Track steps on this phone"** so the phone's own step
     sensor writes steps into Health Connect. *Without one of these, Health
     Connect is empty and there is nothing to sync.*
5. Pull to refresh / tap **Sync** and check the **Activity** card.

If it still shows nothing, work through Â§5.

---

## 3. The Settings toggles

| Toggle | What it does | Notes |
|--------|--------------|-------|
| **Track steps on this phone** | Uses the phone's hardware step counter and writes steps into Health Connect, so you don't need a wearable. | Off by default. Turn this on for a phoneâ€‘only user. |
| **Autoâ€‘detect walks & runs** | Automatically logs walking/running sessions â€” now **even when the app is closed** (see Â§4). | Off by default. Keeps a quiet ongoing notification while active. |
| **Detect sleep in the background** | Notices long overnight stillness and logs it as sleep. | Off by default. Shares the same background service as autoâ€‘detect. |

The autoâ€‘detect and sleep detectors run inside **one alwaysâ€‘on foreground
service**. It starts when *either* toggle is on and stops only when *both* are
off. The ongoing notification is what lets Android keep it alive in the
background â€” that's expected, not a bug.

---

## 4. How autoâ€‘detection works (and its limits)

**Walks/runs.** The background service samples the step counter every ~5 minutes.
A sustained stretch of active stepping (â‰ˆ50+ steps/min) is tracked; when it ends,
if it lasted **â‰¥ 4 minutes** and was **â‰¥ 300 steps**, it's logged as a session
(RUNNING if the cadence is high, otherwise WALKING) with an estimated distance
and calories. Sessions are uploaded immediately if the app is open, or on the
next open if it was closed. The backend deâ€‘duplicates by type + date + duration +
steps, so the same walk is never logged twice.

**Sleep.** A long, still overnight stretch (â‰¥ 3.5 h, spanning the small hours) is
logged once per night as your sleep.

**What it will and won't catch:**
- Walks with the app open **or closed** (as long as the toggle is on and the
  notification is running).
- Multiple separate walks in a day (they're no longer collapsed into one).
- Granularity is ~5 minutes, so a very short stroll (< 4 min) is ignored on
  purpose to avoid logging noise.
- Calories use a default 70 kg weight in the background (no profile access there).
- Some phones aggressively kill background services; granting the
  battery-optimisation exemption (the app asks once) keeps it reliable.

---

## 5. Troubleshooting "sync / autoâ€‘detect isn't working"

Go down this list in order:

1. **Are you on the latest build?** Update from Firebase first.
2. **Are you signed in?** Sign out and back in. (Google signâ€‘in needs Â§6 config.)
3. **Is there data in Health Connect?** Open the Health Connect app and check it
   has steps/sleep. If empty â†’ enable "Track steps on this phone" or connect a
   wearable.
4. **Did you grant Health permission?** Reâ€‘run Wearables â†’ Connect.
5. **For autoâ€‘detect/sleep:** is the toggle on, and is the ongoing notification
   showing? If not, check the app's notification permission and
   batteryâ€‘optimisation settings.
6. **Network:** the device must reach `healthtrackme-production.up.railway.app`.

---

## 6. Server / deploy config the dev must verify (Railway)

These are environment variables â€” if wrong, auth fails and **all** sync fails:

- **`GOOGLE_OAUTH_ALLOWED_CLIENT_IDS`** - must contain the Web OAuth Client ID
  used by the Flutter app as `GOOGLE_WEB_CLIENT_ID` / `serverClientId`. If empty
  or mismatched, Google sign-in returns 401 -> no token -> sync does nothing.
  Android OAuth Client ID is still required in Google Cloud/Firebase for Android
  package name + SHA-1 configuration, but it is not the value used in the backend
  allowed-client list.
- **`JWT_SECRET`** â€” must be set and **stable**. Changing it invalidates every
  issued token (everyone gets logged out / 401s). Tokens last 30 days.
- **`DATABASE_URL` / `DATABASE_USERNAME` / `DATABASE_PASSWORD`** â€” the Postgres
  connection.

The release APK also declares the `INTERNET` permission (required â€” Flutter only
adds it automatically for debug builds, so a release APK without it has no
network at all).
