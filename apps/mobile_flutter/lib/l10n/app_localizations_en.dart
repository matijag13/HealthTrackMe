// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HealthTrackMe';

  @override
  String get logIn => 'Log in';

  @override
  String get register => 'Register';

  @override
  String get createAccount => 'Create account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get connecting => 'Connecting...';

  @override
  String get or => 'Or';

  @override
  String get enterCredentialsToContinue =>
      'Enter your credentials to continue.';

  @override
  String get setUpHealthProfileToContinue =>
      'Set up your health profile to continue.';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get emailRequired => 'Email is required.';

  @override
  String get enterValidEmail => 'Enter a valid email.';

  @override
  String get passwordRequired => 'Password is required.';

  @override
  String get confirmPasswordRequired => 'Confirm password is required.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get required => 'Required';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get createPassword => 'Create a password';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get selectDate => 'Select date';

  @override
  String get dateOfBirthRequired => 'Date of birth is required.';

  @override
  String get accountCreatedSuccessfully => 'Account created successfully';

  @override
  String get invalidEmailOrPassword => 'Invalid email or password.';

  @override
  String get emailAlreadyExists => 'Email already exists.';

  @override
  String get couldNotCreateAccount => 'Could not create account.';

  @override
  String get googleClientIdNotConfigured =>
      'Google client ID is not configured.';

  @override
  String get googleSignInCancelled => 'Google sign-in was cancelled.';

  @override
  String get googleNoIdToken => 'Google did not return an ID token.';

  @override
  String get googleSignInUnavailable =>
      'Google sign-in is not available on this platform yet.';

  @override
  String get googleSignInFailedTryAgain =>
      'Google sign-in failed. Please try again.';

  @override
  String googleSignInFailed(Object message) {
    return 'Google sign-in failed: $message';
  }

  @override
  String get profile => 'Profile';

  @override
  String get preferences => 'Preferences';

  @override
  String get account => 'Account';

  @override
  String get personalDetails => 'Personal details';

  @override
  String get personalDetailsSubtitle => 'Name, DOB, gender, height';

  @override
  String get friendsLeaderboard => 'Friends & leaderboard';

  @override
  String get friendsLeaderboardSubtitle =>
      'Compare streaks & Shield points with friends';

  @override
  String get exportData => 'Export data';

  @override
  String get exportDataSubtitle => 'Copy or email your health data';

  @override
  String get units => 'Units';

  @override
  String unitsSubtitle(
      Object weight, Object height, Object distance, Object temp) {
    return 'Weight: $weight • Height: $height • Distance: $distance • Temp: $temp';
  }

  @override
  String get unitsUpdated => 'Units updated';

  @override
  String get weight => 'Weight';

  @override
  String get height => 'Height';

  @override
  String get distance => 'Distance';

  @override
  String get temperature => 'Temperature';

  @override
  String get heartRate => 'Heart rate';

  @override
  String get stress => 'Stress';

  @override
  String get bloodPressure => 'Blood pressure';

  @override
  String get spO2 => 'SpO2';

  @override
  String get manualEntrySelectedDate =>
      'Manual entry will be saved for the selected date.';

  @override
  String metricSavedButNotReturned(Object metric) {
    return '$metric saved, but not returned';
  }

  @override
  String metricAdded(Object metric) {
    return '$metric added';
  }

  @override
  String couldNotSaveMetric(Object metric) {
    return 'Could not save $metric';
  }

  @override
  String get startOfWeek => 'Start of week';

  @override
  String get mondayOrSunday => 'Monday or Sunday';

  @override
  String get monday => 'Monday';

  @override
  String get sunday => 'Sunday';

  @override
  String get useIsoWeekFormat => 'Use the ISO week format';

  @override
  String get useUsWeekFormat => 'Use the US week format';

  @override
  String startOfWeekSetTo(Object day) {
    return 'Start of week set to $day';
  }

  @override
  String get language => 'Language';

  @override
  String languageSubtitle(Object language) {
    return '$language';
  }

  @override
  String get english => 'English';

  @override
  String get slovenian => 'Slovenščina';

  @override
  String get languageUpdated => 'Language updated';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get settings => 'Settings';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get wearables => 'Wearables';

  @override
  String get detective => 'Detective';

  @override
  String get signOut => 'Sign out';

  @override
  String get activity => 'Activity';

  @override
  String get sleep => 'Sleep';

  @override
  String get vitals => 'Vitals';

  @override
  String get medicines => 'Medicines';

  @override
  String get insightsTrends => 'Insights / Trends';

  @override
  String get wearableDevices => 'Wearable Devices';

  @override
  String get connectDeviceSyncHealthData =>
      'Connect your device and sync health data';

  @override
  String get favorites => 'Favorites';

  @override
  String get noData => 'No data';

  @override
  String get updatedToday => 'Updated today';

  @override
  String get tapToUpdate => 'Tap to update';

  @override
  String get sleepLoggedToday => 'Sleep logged today';

  @override
  String get noSleepDataForToday => 'No sleep data for today';

  @override
  String get reviewScheduleAndDoses => 'Review schedule and doses';

  @override
  String get noActiveMedicinesScheduled => 'No active medicines scheduled';

  @override
  String get historyReady => 'History ready';

  @override
  String get reviewRecentHealthPatterns => 'Review your recent health patterns';

  @override
  String get addModuleDataToUnlockTrends => 'Add module data to unlock trends';

  @override
  String get syncAndManage => 'Sync & manage';

  @override
  String get hydration => 'Hydration';

  @override
  String get onPace => 'On pace';

  @override
  String sleepingAverageOnTrack(Object average, Object goal) {
    return 'Sleeping ${average}h on average — on track for your ${goal}h goal';
  }

  @override
  String sleepingAverageBelowGoal(Object average, Object gap, Object goal) {
    return 'Sleeping ${average}h on average — ${gap}h below your ${goal}h goal';
  }

  @override
  String activeDaysOnPace(Object count, Object projected) {
    return '$count active day(s) so far — on pace for $projected this week';
  }

  @override
  String activeDaysBelowPace(Object count, Object projected, Object goal) {
    return '$count active day(s) — on pace for $projected of $goal this week';
  }

  @override
  String get noActivityDataForToday => 'No activity data for today';

  @override
  String get notSyncedYet => 'Not synced yet';

  @override
  String get lastSyncedJustNow => 'Last synced just now';

  @override
  String lastSyncedMinutesAgo(Object minutes) {
    return 'Last synced ${minutes}m ago';
  }

  @override
  String lastSyncedHoursAgo(Object hours) {
    return 'Last synced ${hours}h ago';
  }

  @override
  String lastSyncedDaysAgo(Object days) {
    return 'Last synced ${days}d ago';
  }

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncHealthData => 'Sync Health Data';

  @override
  String get connectedDevices => 'CONNECTED DEVICES';

  @override
  String get noDevicesConnected => 'No devices connected';

  @override
  String get addWearableDescription =>
      'Add your wearable to track which device your data comes from';

  @override
  String get addDevice => 'Add Device';

  @override
  String get howSyncingWorks => 'How syncing works';

  @override
  String get howSyncingWorksBody =>
      'Tap \"Sync Health Data\" to pull the last 7 days from Samsung Health or Google Fit via Health Connect. Make sure Samsung Health is set to sync with Health Connect in its settings.';

  @override
  String get addWearableDevice => 'Add Wearable Device';

  @override
  String get selectDeviceType => 'Select the type of device to register';

  @override
  String get healthOverview => 'Health Overview';

  @override
  String get weeklyHealthTrendsReady => 'Your weekly health trends are ready.';

  @override
  String get sleepAverage => 'Sleep average';

  @override
  String get activeDays => 'Active days';

  @override
  String get vitalsStatus => 'Vitals status';

  @override
  String get activeMedicines => 'Active medicines';

  @override
  String get sleepInsight => 'Sleep Insight';

  @override
  String get activityInsight => 'Activity Insight';

  @override
  String get vitalsInsight => 'Vitals Insight';

  @override
  String get medicinesInsight => 'Medicines Insight';

  @override
  String get stable => 'Stable';

  @override
  String get needsData => 'Needs data';

  @override
  String get thisWeek => 'this week';

  @override
  String activeDaysThisWeek(Object count) {
    return '$count this week';
  }

  @override
  String get unavailable => 'Unavailable';

  @override
  String get bestNight => 'Best night';

  @override
  String get lowestNight => 'Lowest night';

  @override
  String get higherThanUsual => 'Higher than usual';

  @override
  String get todayOverview => 'Today\'s overview';

  @override
  String get active => 'Active';

  @override
  String get takenToday => 'Taken today';

  @override
  String get noMedicinesYet => 'No medicines yet';

  @override
  String get addMedicinesDescription =>
      'Add medicines to track doses and reminders';

  @override
  String get couldNotLoadVitals => 'Could not load vitals';

  @override
  String get tryLoadLatestHealthEntries =>
      'Try again to load the latest health entries.';

  @override
  String get retry => 'Retry';

  @override
  String get noDataForThisPeriod => 'No data for this period';

  @override
  String get tapPlusAddManualValue => 'Tap + to add a manual value.';

  @override
  String get latest => 'Latest';

  @override
  String get average => 'Average';

  @override
  String get minMax => 'Min / Max';

  @override
  String latestTrend(Object value) {
    return 'Latest trend: $value';
  }

  @override
  String get latestEntry => 'Latest entry';

  @override
  String readingCountInRange(Object count) {
    return '$count reading in range';
  }

  @override
  String readingsCountInRange(Object count) {
    return '$count readings in range';
  }

  @override
  String get systolic => 'Systolic';

  @override
  String get diastolic => 'Diastolic';

  @override
  String get diastolicLowerThanSystolic =>
      'Diastolic should be lower than systolic';

  @override
  String lowHigh(Object low, Object high) {
    return 'Low $low\nHigh $high';
  }

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get healthInformation => 'Health Information';

  @override
  String get enterYourFirstName => 'Enter your first name';

  @override
  String get enterYourLastName => 'Enter your last name';

  @override
  String get firstNameRequired => 'First name is required';

  @override
  String get lastNameRequired => 'Last name is required';

  @override
  String get invalidDateFormat => 'Invalid date format (YYYY-MM-DD)';

  @override
  String get medicalConditions => 'Medical conditions';

  @override
  String get medicalConditionsHint => 'e.g. Diabetes, asthma...';

  @override
  String get allergies => 'Allergies';

  @override
  String get allergiesHint => 'e.g. Penicillin, peanuts...';

  @override
  String get profileUpdated => 'Profile was successfully updated';

  @override
  String errorSelectingDate(Object message) {
    return 'Error selecting date: $message';
  }

  @override
  String genericError(Object message) {
    return 'Error: $message';
  }

  @override
  String get friends => 'Friends';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get addFriend => 'Add friend';

  @override
  String get addAFriend => 'Add a friend';

  @override
  String get theirEmail => 'Their email';

  @override
  String get sendRequest => 'Send request';

  @override
  String friendRequestSentTo(Object email) {
    return 'Friend request sent to $email';
  }

  @override
  String youAreNowFriendsWith(Object name) {
    return 'You are now friends with $name';
  }

  @override
  String get requestDeclined => 'Request declined';

  @override
  String get removeFriendQuestion => 'Remove friend?';

  @override
  String removeFriendConfirm(Object name) {
    return 'Remove $name from your friends?';
  }

  @override
  String get remove => 'Remove';

  @override
  String removedFriend(Object name) {
    return 'Removed $name';
  }

  @override
  String get couldNotRemoveFriend => 'Could not remove friend';

  @override
  String get couldNotLoadFriends => 'Could not load friends';

  @override
  String get addFriendsToCompete => 'Add friends to compete';

  @override
  String get friendsHealthShieldInfo =>
      'Your Health Shield points and streak go head-to-head with friends. No health data is shared.';

  @override
  String get levelShort => 'Lvl';

  @override
  String get pointsShort => 'pts';

  @override
  String get requests => 'Requests';

  @override
  String get yourFriends => 'Your friends';

  @override
  String get pending => 'Pending';

  @override
  String get noFriendsYet => 'No friends yet';

  @override
  String get addSomeoneByEmail => 'Add someone by their email to get started.';

  @override
  String get exportYourData => 'Export your data';

  @override
  String get copyClipboardOrEmail => 'Copy to clipboard or send to your email';

  @override
  String get copySummary => 'Copy summary';

  @override
  String get readableHealthSummary => 'Readable health summary';

  @override
  String get emailSummaryToMe => 'Email summary to me';

  @override
  String get sentToAccountEmail => 'Sent to your account email';

  @override
  String get copyFullDataCsv => 'Copy full data (CSV)';

  @override
  String get entriesActivitiesCsv => 'Entries + activities as CSV';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get noSummaryAvailable => 'No summary available yet';

  @override
  String get summaryCopied => 'Summary copied to clipboard';

  @override
  String get summaryEmailSent => 'Summary sent to your email';

  @override
  String get couldNotSendSummary => 'Could not send summary';

  @override
  String get pleaseSignInFirst => 'Please sign in first';

  @override
  String get noDataToExport => 'No data to export yet';

  @override
  String get noHealthEntriesToExport => 'No health entries to export yet';

  @override
  String get noSportActivitiesToExport => 'No sport activities to export yet';

  @override
  String get healthEntriesCsvCopied => 'Health entries CSV copied to clipboard';

  @override
  String get activitiesCsvCopied => 'Activities CSV copied to clipboard';

  @override
  String exportFailedWithError(Object error) {
    return 'Export failed: $error';
  }

  @override
  String failedWithError(Object error) {
    return 'Failed: $error';
  }

  @override
  String get fullDataCsvCopied => 'Full data (CSV) copied to clipboard';

  @override
  String get managePermissions => 'Manage permissions';

  @override
  String get trackStepsOnPhone => 'Track steps on this phone';

  @override
  String get trackStepsOnPhoneSubtitle =>
      'Count steps with the phone\'s own sensor - no Samsung Health needed';

  @override
  String get autoDetectWalksRuns => 'Auto-detect walks & runs';

  @override
  String get autoDetectWalksRunsSubtitle =>
      'Logs walking/running sessions automatically, even when the app is closed (keeps a quiet notification running)';

  @override
  String get detectSleepBackground => 'Detect sleep in the background';

  @override
  String get detectSleepBackgroundSubtitle =>
      'Notices long overnight rest and logs your sleep - keeps a quiet notification running';

  @override
  String get couldNotStartDetection =>
      'Could not start detection - check notification permission';

  @override
  String get couldNotStartSleepTracking =>
      'Could not start sleep tracking - check notification permission';

  @override
  String get removeDevice => 'Remove device';

  @override
  String removeDeviceQuestion(Object name) {
    return 'Remove $name?';
  }

  @override
  String deviceRemoved(Object name) {
    return '$name removed';
  }

  @override
  String deviceConnectedSynced(Object name, Object details) {
    return '$name connected — synced $details';
  }

  @override
  String deviceConnectedNoNewData(Object name) {
    return '$name connected — no new data yet';
  }

  @override
  String deviceConnectedGrantPermission(Object name) {
    return '$name connected (grant Health permission to sync)';
  }

  @override
  String get failedToAddDevice => 'Failed to add device';

  @override
  String get healthPermissionsDenied => 'Health permissions denied';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get streakMilestone => 'Streak milestone!';

  @override
  String streakMilestoneMessage(Object days) {
    return 'You\'ve logged your health $days days in a row. Keep the fire going! 🔥';
  }

  @override
  String get nice => 'Nice!';

  @override
  String get reminders => 'Reminders';

  @override
  String get dailyReminder => 'Daily reminder';

  @override
  String timeLabel(Object time) {
    return 'Time: $time';
  }

  @override
  String get morningStreakReminder => 'Morning streak reminder';

  @override
  String get morningStreakReminderSubtitle =>
      'A 9 AM nudge to log today and keep your streak alive';

  @override
  String get medicineReminders => 'Medicine reminders';

  @override
  String get medicineRemindersSubtitle =>
      'Turn all medicine reminders on or off';

  @override
  String get weeklyHealthReport => 'Weekly health report';

  @override
  String get weeklyHealthReportSubtitle => 'AI summary emailed every Monday';

  @override
  String get couldNotUpdateWeeklyReport =>
      'Could not update weekly report setting';

  @override
  String get testNotifications => 'Test notifications';

  @override
  String get testNotificationsSubtitle => 'Send one now + one in 30 seconds';

  @override
  String get notificationTest => 'Notification test';

  @override
  String get build => 'Build';

  @override
  String get notificationsAllowed => 'Notifications allowed';

  @override
  String get exactAlarmsAllowed => 'Exact alarms allowed';

  @override
  String get timezone => 'Timezone';

  @override
  String get scheduledPending => 'Scheduled (pending)';

  @override
  String get sentNotificationTestExact =>
      'Sent one now + one in 30s. If the 30s one never arrives, the OS (battery/Doze) is dropping it.';

  @override
  String get sentNotificationTestInexact =>
      'Exact alarms are off. If scheduled reminders never fire, allow Alarms & reminders for HealthTrackMe in Android settings.';

  @override
  String get noActiveUser => 'No active user';

  @override
  String get passwordUpdated => 'Password updated';

  @override
  String get profilePhotoUpdated => 'Profile photo updated';

  @override
  String errorUploadingPhoto(Object error) {
    return 'Error uploading photo: $error';
  }

  @override
  String get privacyAccount => 'Privacy / Account';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get privacyPolicySubtitle => 'Review privacy information';

  @override
  String get deleteAllMyData => 'Delete all my data';

  @override
  String get deleteAllMyDataSubtitle => 'Permanent account data removal';

  @override
  String get changePassword => 'Change password';

  @override
  String get changePasswordSubtitle => 'Update your account password';

  @override
  String get debug => 'Debug';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get enableNotificationsSubtitle =>
      'Allow HealthTrackMe to send reminders and alerts';

  @override
  String get dataPrivacy => 'Data & Privacy';

  @override
  String get developerDebug => 'Developer / Debug';

  @override
  String get couldNotDeleteAccount => 'Could not delete account';

  @override
  String get apiConfiguration => 'API Configuration';

  @override
  String get apiConfigurationSubtitle => 'View and reset API settings';

  @override
  String get enterTime => 'Enter time';

  @override
  String get enterValidTime => 'Enter a valid time';

  @override
  String get hour => 'Hour';

  @override
  String get minute => 'Minute';

  @override
  String get time => 'Time';

  @override
  String get deleteAllDataQuestion => 'Delete all data?';

  @override
  String get deleteAllDataDescription =>
      'This permanently removes your account and health data from HealthTrackMe. This cannot be undone.';

  @override
  String get deleteLoginSessionWarning =>
      'Your login session will end after deletion.';

  @override
  String get delete => 'Delete';

  @override
  String get changePasswordDescription =>
      'Enter your current password and choose a new one.';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get updatePassword => 'Update password';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get platform => 'Platform';

  @override
  String get apiReachable => 'API reachable';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get web => 'Web';

  @override
  String get mobile => 'Mobile';

  @override
  String get resetApi => 'Reset API';

  @override
  String get apiConfigurationReset => 'API configuration reset';

  @override
  String get privacyPolicyLastUpdated => 'Last updated: June 7, 2026';

  @override
  String get privacyPolicyIntro =>
      'HealthTrackMe uses your health information only to show your dashboard, reminders, reports, and wearable sync results inside the app.';

  @override
  String get privacyHealthDataTitle => 'Health data we store';

  @override
  String get privacyHealthDataBody =>
      'Profile details, symptoms, medicines, sleep, activity, steps, heart rate, calories, notes, reminders, and connected wearable device records.';

  @override
  String get privacyWearableSyncTitle => 'Wearable and sensor sync';

  @override
  String get privacyWearableSyncBody =>
      'When you enable sync, the app reads permitted Health Connect or device data and uploads the selected health metrics to your HealthTrackMe account.';

  @override
  String get privacyProtectionTitle => 'How your data is protected';

  @override
  String get privacyProtectionBody =>
      'Account access is controlled by authentication. Health data is sent to the backend for your account features and is not sold for advertising.';

  @override
  String get privacyNotificationsTitle => 'Notifications';

  @override
  String get privacyNotificationsBody =>
      'Reminder settings are used to schedule medicine, diary, and health notifications. You can disable them from this screen or system settings.';

  @override
  String get privacyDeletingDataTitle => 'Deleting your data';

  @override
  String get privacyDeletingDataBody =>
      'Use \"Delete all my data\" in Privacy / Account to request permanent removal of your account data from the app backend.';

  @override
  String get privacyQuestionsTitle => 'Questions';

  @override
  String get privacyQuestionsBody =>
      'For privacy questions, contact the HealthTrackMe project owner or your course project maintainer.';

  @override
  String get edit => 'Edit';

  @override
  String get healthShield => 'Health Shield';

  @override
  String dayStreak(Object count) {
    return '$count-day streak';
  }

  @override
  String get startYourStreak => 'Start your streak';

  @override
  String loggedTodayBest(Object best) {
    return 'Logged today ✓ • best $best';
  }

  @override
  String get logTodayKeepAlive => 'Log today to keep it alive';

  @override
  String get logHealthTodayBegin => 'Log your health today to begin';

  @override
  String get editFavorites => 'Edit favorites';

  @override
  String get chooseShortcutsShownOnHome =>
      'Choose the shortcuts shown on Home.';

  @override
  String get selectAtLeastOneFavorite => 'Select at least one favorite.';

  @override
  String get activityLoggedToday => 'Activity logged today';

  @override
  String get walking => 'Walking';

  @override
  String get running => 'Running';

  @override
  String get cycling => 'Cycling';

  @override
  String get workout => 'Workout';

  @override
  String get swimming => 'Swimming';

  @override
  String get steps => 'Steps';

  @override
  String stepsCount(Object count) {
    return '$count steps';
  }

  @override
  String todayValueGoal(Object value, Object goal) {
    return 'Today: $value / $goal';
  }

  @override
  String get dailyGoalReached => 'Daily goal reached';

  @override
  String stepsToDailyGoal(Object count) {
    return '$count steps to daily goal';
  }

  @override
  String get activityDurationSelectedRange =>
      'Activity duration in the selected range.';

  @override
  String get noActivityDataForThisPeriod => 'No activity data for this period';

  @override
  String noMetricDataForThisPeriod(Object metric) {
    return 'No $metric data for this period';
  }

  @override
  String get total => 'Total';

  @override
  String get all => 'All';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get averageToday => 'Average today';

  @override
  String get averageThisWeek => 'Average this week';

  @override
  String get averageThisMonth => 'Average this month';

  @override
  String get averageAllTime => 'Average all time';

  @override
  String todaysActivityType(Object type) {
    return 'Today\'s $type';
  }

  @override
  String activityTypeThisWeek(Object type) {
    return '$type this week';
  }

  @override
  String activityTypeThisMonth(Object type) {
    return '$type this month';
  }

  @override
  String allActivityTypeActivities(Object type) {
    return 'All $type activities';
  }

  @override
  String noActivityTypeActivitiesForPeriod(Object type) {
    return 'No $type activities for this period';
  }

  @override
  String get maxRange => 'Max';

  @override
  String addActivityType(Object type) {
    return 'Add $type';
  }

  @override
  String get date => 'Date';

  @override
  String get duration => 'Duration';

  @override
  String get distanceKm => 'Distance (km)';

  @override
  String get caloriesOptional => 'Calories (optional)';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get couldNotSaveActivity => 'Could not save activity';

  @override
  String get workoutDetails => 'Workout details';

  @override
  String get avgSpeed => 'Avg. speed';

  @override
  String get calories => 'Calories';

  @override
  String get avgPace => 'Avg. pace';

  @override
  String get healthOverviewSubtitle =>
      'Charts, trends, and the monthly report now live inside the Health tab.';

  @override
  String get vitalsShortcutSubtitle => 'Wellbeing, sleep and recent markers';

  @override
  String get activityShortcutSubtitle => 'Consistency and daily movement';

  @override
  String get sleepShortcutSubtitle => 'Sleep trend and recovery';

  @override
  String get history => 'History';

  @override
  String get historyShortcutSubtitle => 'Reports and past entries';

  @override
  String get sleepHoursSelectedRange => 'Sleep hours in the selected range.';

  @override
  String get noSleepDataForThisPeriod => 'No sleep data for this period';

  @override
  String get tapAddSleepEntry => 'Tap + to add a sleep entry.';

  @override
  String get couldNotLoadSleep => 'Could not load sleep';

  @override
  String get tryLoadLatestSleepEntries =>
      'Try again to load the latest sleep entries.';

  @override
  String get sleepSavedButNotReturned =>
      'Sleep saved, but not returned by refresh';

  @override
  String get sleepAdded => 'Sleep added';

  @override
  String get sleepDurationInvalid => 'Sleep duration is invalid';

  @override
  String get sleepDurationTooLong =>
      'Sleep duration looks too long. Please check bedtime and wake time.';

  @override
  String get addSleep => 'Add sleep';

  @override
  String get sleepManualEntrySubtitle =>
      'Save bedtime and wake time. Sleep duration is calculated automatically.';

  @override
  String get bedtime => 'Bedtime';

  @override
  String get wakeTime => 'Wake time';

  @override
  String get sleepApiSupportNote =>
      'Bedtime and wake time are stored when the API supports these fields.';

  @override
  String get levelProgress => 'Level progress';

  @override
  String totalXp(Object xp) {
    return '$xp total XP';
  }

  @override
  String xpLeft(Object xp) {
    return '$xp XP left';
  }

  @override
  String get maxLevel => 'Max level';

  @override
  String get level => 'Level';

  @override
  String levelNumber(Object level) {
    return 'Level $level';
  }

  @override
  String get nextLevel => 'Next level';

  @override
  String get todaysShield => 'Today\'s Shield';

  @override
  String get completeTodaysShieldEarnXp =>
      'Complete today\'s shield to earn XP.';

  @override
  String get completed => 'Completed';

  @override
  String get notCompleted => 'Not completed';

  @override
  String get notApplicable => 'Not applicable';

  @override
  String get trackingActive => 'Tracking active';

  @override
  String xpReward(Object xp) {
    return '+$xp XP';
  }

  @override
  String xpValue(Object xp) {
    return '$xp XP';
  }

  @override
  String get logSleepBuildShield => 'Log sleep to build your shield';

  @override
  String get sleepLogged => 'Sleep logged';

  @override
  String get sleepLoggedBonusXp => 'Sleep logged with bonus XP';

  @override
  String get completeTodaysShield => 'Complete today\'s shield';

  @override
  String get activityCompleted => 'Activity completed';

  @override
  String get logOneVitalReading => 'Log one vital reading';

  @override
  String get vitalsLogged => 'Vitals logged';

  @override
  String get medicineTrackedToday => 'Medicine tracked today';

  @override
  String get keepYourStreakAlive => 'Keep your streak alive';

  @override
  String get weeklyProgress => 'Weekly progress';

  @override
  String get xpThisWeek => 'XP this week';

  @override
  String get activeShieldDays => 'active shield days';

  @override
  String get completedDailyShields => 'completed daily shields';

  @override
  String get bestCategory => 'best category';

  @override
  String get weakestCategory => 'weakest category';

  @override
  String get bestRecentStreak => 'best recent streak';

  @override
  String get completeShieldKeepStreakAlive =>
      'Complete today\'s shield to keep your streak alive';

  @override
  String get recentXp => 'Recent XP';

  @override
  String get logTodaysHabitsEarnXp => 'Log today\'s habits to earn XP.';

  @override
  String get addedToTodaysShield => 'Added to today\'s shield';

  @override
  String get startLoggingBuildShield =>
      'Start logging sleep, activity and vitals to build your shield.';

  @override
  String get medicine => 'Medicine';

  @override
  String get sleepBonus => 'Sleep bonus';

  @override
  String get medicineTracked => 'Medicine tracked';

  @override
  String get dailyShieldBonus => 'Daily shield bonus';

  @override
  String get completeShieldBonus => 'Complete shield bonus';

  @override
  String get todaySchedule => 'Today\'s Schedule';

  @override
  String get other => 'Other';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get evening => 'Evening';

  @override
  String get dosage => 'Dosage';

  @override
  String dosageValue(Object dosage) {
    return 'Dosage: $dosage';
  }

  @override
  String get noScheduleSet => 'No schedule set';

  @override
  String dosesToday(Object taken, Object expected) {
    return '$taken/$expected today';
  }

  @override
  String get taken => 'Taken';

  @override
  String get take => 'Take';

  @override
  String get undo => 'Undo';

  @override
  String get deleting => 'Deleting';

  @override
  String get loadingMedicines => 'Loading medicines';

  @override
  String get addMedicine => 'Add medicine';

  @override
  String get editMedicine => 'Edit medicine';

  @override
  String get medicineName => 'Medicine name';

  @override
  String get frequency => 'Frequency';

  @override
  String get select => 'Select';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get reasonOptional => 'Reason (optional)';

  @override
  String get sideEffectsNotes => 'Side effects / notes';

  @override
  String get trackDosesSchedulesNotes => 'Track doses, schedules, and notes.';

  @override
  String get noMedicinesHere => 'No medicines here';

  @override
  String get markedAsTaken => 'Marked as taken';

  @override
  String get doseRemoved => 'Dose removed';

  @override
  String get couldNotUndoDose => 'Could not undo dose';

  @override
  String get networkError => 'Network error';

  @override
  String get undoDoseQuestion => 'Undo dose?';

  @override
  String removeTodaysLastDose(Object name) {
    return 'Remove today\'s last logged dose of $name?';
  }

  @override
  String get deleteMedicineQuestion => 'Delete medicine?';

  @override
  String removeMedicineFromList(Object name) {
    return 'Remove \"$name\" from your medicines list.';
  }

  @override
  String get couldNotDeleteMedicine => 'Could not delete medicine';

  @override
  String medicineRemovedRefreshFailed(Object name) {
    return '$name removed. Could not refresh list.';
  }

  @override
  String medicineRemoved(Object name) {
    return '$name removed';
  }

  @override
  String get medicineUpdated => 'Medicine updated';

  @override
  String get medicineAdded => 'Medicine added';

  @override
  String get couldNotSaveMedicine => 'Could not save medicine';

  @override
  String get addReminderTimeOptional => 'Add reminder time (optional)';

  @override
  String get addAnotherTime => 'Add another time';

  @override
  String get onceDaily => 'Once daily';

  @override
  String get twiceDaily => 'Twice daily';

  @override
  String get threeTimesDaily => 'Three times daily';

  @override
  String get fourTimesDaily => 'Four times daily';

  @override
  String get everyOtherDay => 'Every other day';

  @override
  String get onceWeekly => 'Once weekly';

  @override
  String get asNeeded => 'As needed';

  @override
  String timesDaily(Object count) {
    return '${count}x daily';
  }

  @override
  String get reason => 'Reason';

  @override
  String get notSet => 'Not set';

  @override
  String get medicineCreationNotWired =>
      'Medicine creation is not wired to an API endpoint yet.';

  @override
  String get medicineDetails => 'Medicine details';

  @override
  String get loadingMedicine => 'Loading medicine';

  @override
  String get medicineNotFound => 'Medicine not found';

  @override
  String get medicineNotFoundDescription =>
      'This medicine may have been removed or is no longer available.';

  @override
  String get schedule => 'Schedule';

  @override
  String get notes => 'Notes';

  @override
  String get timeline => 'Timeline';

  @override
  String get nextDose => 'Next dose';

  @override
  String get inactive => 'Inactive';

  @override
  String get logFewNightsSleepTrend =>
      'Log a few nights to see your sleep trend.';

  @override
  String get noActivityTrendYet => 'No activity trend yet';

  @override
  String get logActivitiesWeeklyPattern =>
      'Log activities to see your weekly movement pattern.';

  @override
  String activeDaysCount(Object count) {
    return '$count active days';
  }

  @override
  String totalActivityDuration(Object duration) {
    return '$duration total activity';
  }

  @override
  String get mostCommon => 'Most common';

  @override
  String get logVitalsWeeklyBaseline =>
      'Log vitals to see your weekly baseline.';

  @override
  String get avgHeartRate => 'Avg heart rate';

  @override
  String get avgStress => 'Avg stress';

  @override
  String get latestBp => 'Latest BP';

  @override
  String get latestSpO2 => 'Latest SpO2';

  @override
  String get medicationDataUnavailable => 'Medication data unavailable';

  @override
  String get tryRefreshMedicationRoutine =>
      'Try again to refresh your medication routine.';

  @override
  String get medicationTrackingActive => 'Medication tracking is active.';

  @override
  String get addMedicinesTrackRoutine => 'Add medicines to track your routine.';

  @override
  String activeMedicineCount(Object count) {
    return '$count active medicine';
  }

  @override
  String activeMedicinesCount(Object count) {
    return '$count active medicines';
  }

  @override
  String get noActiveMedicines => 'No active medicines';

  @override
  String markedTakenToday(Object taken, Object total) {
    return '$taken of $total marked taken today';
  }

  @override
  String get smartPatterns => 'Smart Patterns';

  @override
  String get daysAnalyzed => 'Days analyzed';

  @override
  String get needsMoreData => 'Needs more data';

  @override
  String get logSleepStressUnlockPatterns =>
      'Log sleep and stress for a few more days to unlock patterns.';

  @override
  String get patternDetected => 'Pattern detected';

  @override
  String get noStrongPatternYet => 'No strong pattern yet';

  @override
  String get shortSleepHigherStressPattern =>
      'Short sleep days are linked with higher stress in your logs.';

  @override
  String get noStrongSleepStressPattern =>
      'No strong sleep-stress pattern detected yet.';

  @override
  String get previousWeekNeedsMoreData =>
      'Previous week comparison needs more data.';

  @override
  String vsLastWeek(Object change) {
    return '$change vs last week';
  }

  @override
  String get couldNotLoadInsights => 'Could not load insights';

  @override
  String get tryLoadLatestWeeklyTrends =>
      'Try again to load your latest weekly trends.';

  @override
  String get improving => 'Improving';

  @override
  String get lowerThanUsual => 'Lower than usual';

  @override
  String get healthAi => 'Health AI';

  @override
  String get poweredByClaude => 'Powered by Claude';

  @override
  String get aiAssistantIntro =>
      'Hi! I\'m your health assistant. Here\'s a quick read on your week — ask me anything about your sleep, activity, or vitals.';

  @override
  String get aiSuggestionSleepWeek => 'How was my sleep this week?';

  @override
  String get aiSuggestionActivity => 'How active have I been?';

  @override
  String get aiSuggestionTrends => 'Any concerning trends?';

  @override
  String get aiAskHint => 'Ask about your health…';

  @override
  String get aiSignInForInsight => 'Sign in to see your personalized insight.';

  @override
  String get aiLogMoreDataInsight =>
      'Log a bit more health data and I can spot patterns for you.';

  @override
  String get aiSignInToAsk => 'Please sign in to ask about your health data.';

  @override
  String get aiCouldNotAnswer => 'Sorry, I couldn\'t answer that right now.';

  @override
  String get aiNoResponseAvailable => 'No response available';

  @override
  String get insightCopiedToClipboard => 'Insight copied to clipboard';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get exportFeatureComingSoon => 'Export feature coming soon';
}
