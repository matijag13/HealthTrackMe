# HealthTrackMe Flutter App

Flutter frontend for HealthTrackMe. The app provides the user-facing mobile experience for logging health data, syncing wearable data, viewing dashboards and reports, managing medicines, editing profile/preferences, switching language, and using social/Health Shield features.

## Current App Surface

The current route tree is defined in `lib/config/app_router.dart` and includes:

- `/auth` - login/register flow
- `/onboarding` - onboarding screen
- `/home` - dashboard
- `/log` - diary and manual health logging
- `/health` - tabbed health area
- `/health/vitals` - vitals detail page
- `/health/activity` - activity detail page
- `/health/sleep` - sleep detail page
- `/health/history` - reports/history
- `/meds` - medicines
- `/meds/add` - add medicine
- `/meds/detail/:id` - medicine detail
- `/profile` - profile and preferences
- `/profile/edit` - edit profile
- `/profile/medical-history` - medical history
- `/profile/export` - export data
- `/wearables` - wearable/device sync
- `/health-shield` - Health Shield progress
- `/friends` - friends and leaderboard
- `/diary/:date` - date-specific diary entry view

There are no old hidden dashboard routes in the current app.

## Main Features

- Email/password and Google Sign-In authentication.
- Dashboard with current health summary, Health Shield, medicines, reminders, friends access, and quick navigation.
- Diary/logging screen for wellbeing, symptoms, vitals, sleep, water, notes, and activity-related inputs.
- Health tabs for vitals, activity, sleep, and historical reports.
- Medicine management with reminder times, adherence, dose tracking, and local notifications.
- Wearables/device screen for permissions, Health Connect sync, connected devices, and sync events.
- Health Shield and gamified progress surfaces.
- Friends and leaderboard screens.
- Profile editing, profile photo upload, preferences, medical history, export, and account actions.
- Localization for English and Slovenian through ARB files.
- Foreground sync while the app is open plus background sync through Workmanager where supported.
- Sleep/activity detection support through foreground task and sensor services.

## Stack

| Area | Package/Tool |
| --- | --- |
| Routing | `go_router` |
| State | `provider`, local `ChangeNotifier`s, stateful screens |
| API | `http`, `ApiService` singleton |
| Charts | `fl_chart`, `percent_indicator` |
| Device health | `health`, `pedometer`, `flutter_activity_recognition`, `flutter_foreground_task` |
| Notifications | `flutter_local_notifications`, `timezone`, `flutter_timezone` |
| Local state | `shared_preferences` |
| Auth | `google_sign_in`, `google_sign_in_web` |
| UI polish | `google_fonts`, `flex_color_scheme`, `lottie`, `shimmer`, `flutter_slidable` |
| Media | `image_picker` |

## Directory Structure

```text
apps/mobile_flutter/
├── lib/
│   ├── config/        router, theme, locale, auth config
│   ├── l10n/          ARB files and generated localizations
│   ├── models/        data models
│   ├── screens/       app screens and route pages
│   ├── services/      API, auth, sync, notifications, sensors
│   ├── utils/         helpers
│   └── widgets/       shared UI widgets
├── assets/
│   └── images/logo_1024.png
├── test/              widget, model, and service tests
├── android/ ios/ web/ macos/ linux/ windows/
└── pubspec.yaml
```

## Local Setup

### Prerequisites

- Flutter stable SDK
- Android Studio or Android SDK tools for Android builds
- A device/emulator for Android testing
- Chrome/Edge for web testing
- Backend API running locally or deployed

Check environment:

```powershell
flutter doctor
```

Install dependencies:

```powershell
cd apps/mobile_flutter
flutter pub get
```

## API Configuration

The API base URL is controlled by `ApiService`.

Current defaults:

- Web: `http://localhost:8080/api/v1`
- Android: `https://healthtrackme-production.up.railway.app/api/v1`
- Other platforms: `http://localhost:8080/api/v1`

The app stores the active user id and JWT token in `SharedPreferences`.

## Google Sign-In

For web/local runs, pass the Google web client id:

```powershell
flutter run -d edge --web-port=52145 --dart-define="GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com"
```

`GOOGLE_WEB_CLIENT_ID` must be the Web OAuth Client ID. Flutter uses it as the Google Sign-In `serverClientId`.

The helper script reads this from the root `.env` file:

```powershell
./scripts/run-flutter-local.ps1
```

The backend variable `GOOGLE_OAUTH_ALLOWED_CLIENT_IDS` must contain the same Web OAuth Client ID so the API can verify Google Sign-In tokens.

## Run the App

Web:

```powershell
cd apps/mobile_flutter
flutter run -d edge --web-port=52145 --dart-define="GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com"
```

Android debug:

```powershell
flutter run
```

Release APK:

```powershell
flutter build apk --release --dart-define="GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com"
```

## Localization

Source files:

- `lib/l10n/app_en.arb`
- `lib/l10n/app_sl.arb`

Generated files are in `lib/l10n/`. If localization files change, run:

```powershell
flutter gen-l10n
```

The app exposes language switching through the profile/preferences flow using `LocaleProvider`.

## Assets and Icons

The app currently keeps `assets/images/logo_1024.png` as the launcher icon source. App icons are configured through `flutter_launcher_icons` in `pubspec.yaml`.

Regenerate launcher icons after replacing the logo:

```powershell
dart run flutter_launcher_icons
```

## Testing and Quality Checks

```powershell
cd apps/mobile_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Expected checks:

- `flutter analyze` passes
- `flutter test` passes

## Android/Firebase Distribution

Release distribution is automated through `.github/workflows/android-distribute.yml`.

The workflow builds a signed APK and uploads it to Firebase App Distribution. Required secrets:

- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`
- `GOOGLE_WEB_CLIENT_ID`
- `FIREBASE_SERVICE_ACCOUNT`

The workflow runs on `develop` changes under `apps/mobile_flutter/**` or manual dispatch.

## Frontend CI

GitHub Actions workflow: `.github/workflows/frontend-ci.yml`

The pipeline runs:

- `flutter pub get`
- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
