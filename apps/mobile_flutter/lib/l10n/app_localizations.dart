import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sl')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HealthTrackMe'**
  String get appTitle;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get or;

  /// No description provided for @enterCredentialsToContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials to continue.'**
  String get enterCredentialsToContinue;

  /// No description provided for @setUpHealthProfileToContinue.
  ///
  /// In en, this message translates to:
  /// **'Set up your health profile to continue.'**
  String get setUpHealthProfileToContinue;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get emailRequired;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get enterValidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get passwordRequired;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm password is required.'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get createPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @dateOfBirthRequired.
  ///
  /// In en, this message translates to:
  /// **'Date of birth is required.'**
  String get dateOfBirthRequired;

  /// No description provided for @accountCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get accountCreatedSuccessfully;

  /// No description provided for @invalidEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get invalidEmailOrPassword;

  /// No description provided for @emailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Email already exists.'**
  String get emailAlreadyExists;

  /// No description provided for @couldNotCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Could not create account.'**
  String get couldNotCreateAccount;

  /// No description provided for @googleClientIdNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Google client ID is not configured.'**
  String get googleClientIdNotConfigured;

  /// No description provided for @googleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled.'**
  String get googleSignInCancelled;

  /// No description provided for @googleNoIdToken.
  ///
  /// In en, this message translates to:
  /// **'Google did not return an ID token.'**
  String get googleNoIdToken;

  /// No description provided for @googleSignInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not available on this platform yet.'**
  String get googleSignInUnavailable;

  /// No description provided for @googleSignInFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get googleSignInFailedTryAgain;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: {message}'**
  String googleSignInFailed(Object message);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get personalDetails;

  /// No description provided for @personalDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, date of birth'**
  String get personalDetailsSubtitle;

  /// No description provided for @friendsLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Friends & leaderboard'**
  String get friendsLeaderboard;

  /// No description provided for @friendsLeaderboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compare streaks & Shield points with friends'**
  String get friendsLeaderboardSubtitle;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @exportDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy or email your health data'**
  String get exportDataSubtitle;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @unitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weight: {weight} • Height: {height} • Distance: {distance} • Temp: {temp}'**
  String unitsSubtitle(
      Object weight, Object height, Object distance, Object temp);

  /// No description provided for @unitsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Units updated'**
  String get unitsUpdated;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @heartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get heartRate;

  /// No description provided for @stress.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get stress;

  /// No description provided for @bloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure'**
  String get bloodPressure;

  /// No description provided for @spO2.
  ///
  /// In en, this message translates to:
  /// **'SpO2'**
  String get spO2;

  /// No description provided for @manualEntrySelectedDate.
  ///
  /// In en, this message translates to:
  /// **'Manual entry will be saved for the selected date.'**
  String get manualEntrySelectedDate;

  /// No description provided for @metricSavedButNotReturned.
  ///
  /// In en, this message translates to:
  /// **'{metric} saved, but not returned'**
  String metricSavedButNotReturned(Object metric);

  /// No description provided for @metricAdded.
  ///
  /// In en, this message translates to:
  /// **'{metric} added'**
  String metricAdded(Object metric);

  /// No description provided for @couldNotSaveMetric.
  ///
  /// In en, this message translates to:
  /// **'Could not save {metric}'**
  String couldNotSaveMetric(Object metric);

  /// No description provided for @startOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Start of week'**
  String get startOfWeek;

  /// No description provided for @mondayOrSunday.
  ///
  /// In en, this message translates to:
  /// **'Monday or Sunday'**
  String get mondayOrSunday;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @useIsoWeekFormat.
  ///
  /// In en, this message translates to:
  /// **'Use the ISO week format'**
  String get useIsoWeekFormat;

  /// No description provided for @useUsWeekFormat.
  ///
  /// In en, this message translates to:
  /// **'Use the US week format'**
  String get useUsWeekFormat;

  /// No description provided for @startOfWeekSetTo.
  ///
  /// In en, this message translates to:
  /// **'Start of week set to {day}'**
  String startOfWeekSetTo(Object day);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{language}'**
  String languageSubtitle(Object language);

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @slovenian.
  ///
  /// In en, this message translates to:
  /// **'Slovenščina'**
  String get slovenian;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageUpdated;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @wearables.
  ///
  /// In en, this message translates to:
  /// **'Wearables'**
  String get wearables;

  /// No description provided for @detective.
  ///
  /// In en, this message translates to:
  /// **'Detective'**
  String get detective;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @vitals.
  ///
  /// In en, this message translates to:
  /// **'Vitals'**
  String get vitals;

  /// No description provided for @medicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get medicines;

  /// No description provided for @insightsTrends.
  ///
  /// In en, this message translates to:
  /// **'Insights / Trends'**
  String get insightsTrends;

  /// No description provided for @wearableDevices.
  ///
  /// In en, this message translates to:
  /// **'Wearable Devices'**
  String get wearableDevices;

  /// No description provided for @connectDeviceSyncHealthData.
  ///
  /// In en, this message translates to:
  /// **'Connect your device and sync health data'**
  String get connectDeviceSyncHealthData;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @updatedToday.
  ///
  /// In en, this message translates to:
  /// **'Updated today'**
  String get updatedToday;

  /// No description provided for @tapToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Tap to update'**
  String get tapToUpdate;

  /// No description provided for @sleepLoggedToday.
  ///
  /// In en, this message translates to:
  /// **'Sleep logged today'**
  String get sleepLoggedToday;

  /// No description provided for @noSleepDataForToday.
  ///
  /// In en, this message translates to:
  /// **'No sleep data for today'**
  String get noSleepDataForToday;

  /// No description provided for @reviewScheduleAndDoses.
  ///
  /// In en, this message translates to:
  /// **'Review schedule and doses'**
  String get reviewScheduleAndDoses;

  /// No description provided for @noActiveMedicinesScheduled.
  ///
  /// In en, this message translates to:
  /// **'No active medicines scheduled'**
  String get noActiveMedicinesScheduled;

  /// No description provided for @historyReady.
  ///
  /// In en, this message translates to:
  /// **'History ready'**
  String get historyReady;

  /// No description provided for @reviewRecentHealthPatterns.
  ///
  /// In en, this message translates to:
  /// **'Review your recent health patterns'**
  String get reviewRecentHealthPatterns;

  /// No description provided for @addModuleDataToUnlockTrends.
  ///
  /// In en, this message translates to:
  /// **'Add module data to unlock trends'**
  String get addModuleDataToUnlockTrends;

  /// No description provided for @syncAndManage.
  ///
  /// In en, this message translates to:
  /// **'Sync & manage'**
  String get syncAndManage;

  /// No description provided for @hydration.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get hydration;

  /// No description provided for @onPace.
  ///
  /// In en, this message translates to:
  /// **'On pace'**
  String get onPace;

  /// No description provided for @sleepingAverageOnTrack.
  ///
  /// In en, this message translates to:
  /// **'Sleeping {average}h on average — on track for your {goal}h goal'**
  String sleepingAverageOnTrack(Object average, Object goal);

  /// No description provided for @sleepingAverageBelowGoal.
  ///
  /// In en, this message translates to:
  /// **'Sleeping {average}h on average — {gap}h below your {goal}h goal'**
  String sleepingAverageBelowGoal(Object average, Object gap, Object goal);

  /// No description provided for @activeDaysOnPace.
  ///
  /// In en, this message translates to:
  /// **'{count} active day(s) so far — on pace for {projected} this week'**
  String activeDaysOnPace(Object count, Object projected);

  /// No description provided for @activeDaysBelowPace.
  ///
  /// In en, this message translates to:
  /// **'{count} active day(s) — on pace for {projected} of {goal} this week'**
  String activeDaysBelowPace(Object count, Object projected, Object goal);

  /// No description provided for @noActivityDataForToday.
  ///
  /// In en, this message translates to:
  /// **'No activity data for today'**
  String get noActivityDataForToday;

  /// No description provided for @notSyncedYet.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get notSyncedYet;

  /// No description provided for @lastSyncedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Last synced just now'**
  String get lastSyncedJustNow;

  /// No description provided for @lastSyncedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'Last synced {minutes}m ago'**
  String lastSyncedMinutesAgo(Object minutes);

  /// No description provided for @lastSyncedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Last synced {hours}h ago'**
  String lastSyncedHoursAgo(Object hours);

  /// No description provided for @lastSyncedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Last synced {days}d ago'**
  String lastSyncedDaysAgo(Object days);

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @syncHealthData.
  ///
  /// In en, this message translates to:
  /// **'Sync Health Data'**
  String get syncHealthData;

  /// No description provided for @connectedDevices.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED DEVICES'**
  String get connectedDevices;

  /// No description provided for @noDevicesConnected.
  ///
  /// In en, this message translates to:
  /// **'No devices connected'**
  String get noDevicesConnected;

  /// No description provided for @addWearableDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your wearable to track which device your data comes from'**
  String get addWearableDescription;

  /// No description provided for @addDevice.
  ///
  /// In en, this message translates to:
  /// **'Add Device'**
  String get addDevice;

  /// No description provided for @howSyncingWorks.
  ///
  /// In en, this message translates to:
  /// **'How syncing works'**
  String get howSyncingWorks;

  /// No description provided for @howSyncingWorksBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Sync Health Data\" to pull the last 7 days from Samsung Health or Google Fit via Health Connect. Make sure Samsung Health is set to sync with Health Connect in its settings.'**
  String get howSyncingWorksBody;

  /// No description provided for @addWearableDevice.
  ///
  /// In en, this message translates to:
  /// **'Add Wearable Device'**
  String get addWearableDevice;

  /// No description provided for @selectDeviceType.
  ///
  /// In en, this message translates to:
  /// **'Select the type of device to register'**
  String get selectDeviceType;

  /// No description provided for @healthOverview.
  ///
  /// In en, this message translates to:
  /// **'Health Overview'**
  String get healthOverview;

  /// No description provided for @weeklyHealthTrendsReady.
  ///
  /// In en, this message translates to:
  /// **'Your weekly health trends are ready.'**
  String get weeklyHealthTrendsReady;

  /// No description provided for @sleepAverage.
  ///
  /// In en, this message translates to:
  /// **'Sleep average'**
  String get sleepAverage;

  /// No description provided for @activeDays.
  ///
  /// In en, this message translates to:
  /// **'Active days'**
  String get activeDays;

  /// No description provided for @vitalsStatus.
  ///
  /// In en, this message translates to:
  /// **'Vitals status'**
  String get vitalsStatus;

  /// No description provided for @activeMedicines.
  ///
  /// In en, this message translates to:
  /// **'Active medicines'**
  String get activeMedicines;

  /// No description provided for @sleepInsight.
  ///
  /// In en, this message translates to:
  /// **'Sleep Insight'**
  String get sleepInsight;

  /// No description provided for @activityInsight.
  ///
  /// In en, this message translates to:
  /// **'Activity Insight'**
  String get activityInsight;

  /// No description provided for @vitalsInsight.
  ///
  /// In en, this message translates to:
  /// **'Vitals Insight'**
  String get vitalsInsight;

  /// No description provided for @medicinesInsight.
  ///
  /// In en, this message translates to:
  /// **'Medicines Insight'**
  String get medicinesInsight;

  /// No description provided for @stable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get stable;

  /// No description provided for @needsData.
  ///
  /// In en, this message translates to:
  /// **'Needs data'**
  String get needsData;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'this week'**
  String get thisWeek;

  /// No description provided for @activeDaysThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{count} this week'**
  String activeDaysThisWeek(Object count);

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @bestNight.
  ///
  /// In en, this message translates to:
  /// **'Best night'**
  String get bestNight;

  /// No description provided for @lowestNight.
  ///
  /// In en, this message translates to:
  /// **'Lowest night'**
  String get lowestNight;

  /// No description provided for @higherThanUsual.
  ///
  /// In en, this message translates to:
  /// **'Higher than usual'**
  String get higherThanUsual;

  /// No description provided for @todayOverview.
  ///
  /// In en, this message translates to:
  /// **'Today\'s overview'**
  String get todayOverview;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @takenToday.
  ///
  /// In en, this message translates to:
  /// **'Taken today'**
  String get takenToday;

  /// No description provided for @noMedicinesYet.
  ///
  /// In en, this message translates to:
  /// **'No medicines yet'**
  String get noMedicinesYet;

  /// No description provided for @addMedicinesDescription.
  ///
  /// In en, this message translates to:
  /// **'Add medicines to track doses and reminders'**
  String get addMedicinesDescription;

  /// No description provided for @couldNotLoadVitals.
  ///
  /// In en, this message translates to:
  /// **'Could not load vitals'**
  String get couldNotLoadVitals;

  /// No description provided for @tryLoadLatestHealthEntries.
  ///
  /// In en, this message translates to:
  /// **'Try again to load the latest health entries.'**
  String get tryLoadLatestHealthEntries;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noDataForThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get noDataForThisPeriod;

  /// No description provided for @tapPlusAddManualValue.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a manual value.'**
  String get tapPlusAddManualValue;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @minMax.
  ///
  /// In en, this message translates to:
  /// **'Min / Max'**
  String get minMax;

  /// No description provided for @latestTrend.
  ///
  /// In en, this message translates to:
  /// **'Latest trend: {value}'**
  String latestTrend(Object value);

  /// No description provided for @latestEntry.
  ///
  /// In en, this message translates to:
  /// **'Latest entry'**
  String get latestEntry;

  /// No description provided for @readingCountInRange.
  ///
  /// In en, this message translates to:
  /// **'{count} reading in range'**
  String readingCountInRange(Object count);

  /// No description provided for @readingsCountInRange.
  ///
  /// In en, this message translates to:
  /// **'{count} readings in range'**
  String readingsCountInRange(Object count);

  /// No description provided for @systolic.
  ///
  /// In en, this message translates to:
  /// **'Systolic'**
  String get systolic;

  /// No description provided for @diastolic.
  ///
  /// In en, this message translates to:
  /// **'Diastolic'**
  String get diastolic;

  /// No description provided for @diastolicLowerThanSystolic.
  ///
  /// In en, this message translates to:
  /// **'Diastolic should be lower than systolic'**
  String get diastolicLowerThanSystolic;

  /// No description provided for @lowHigh.
  ///
  /// In en, this message translates to:
  /// **'Low {low}\nHigh {high}'**
  String lowHigh(Object low, Object high);

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @healthInformation.
  ///
  /// In en, this message translates to:
  /// **'Health Information'**
  String get healthInformation;

  /// No description provided for @enterYourFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get enterYourFirstName;

  /// No description provided for @enterYourLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get enterYourLastName;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get lastNameRequired;

  /// No description provided for @invalidDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid date format (YYYY-MM-DD)'**
  String get invalidDateFormat;

  /// No description provided for @medicalConditions.
  ///
  /// In en, this message translates to:
  /// **'Medical conditions'**
  String get medicalConditions;

  /// No description provided for @medicalConditionsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Diabetes, asthma...'**
  String get medicalConditionsHint;

  /// No description provided for @allergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergies;

  /// No description provided for @allergiesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Penicillin, peanuts...'**
  String get allergiesHint;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile was successfully updated'**
  String get profileUpdated;

  /// No description provided for @errorSelectingDate.
  ///
  /// In en, this message translates to:
  /// **'Error selecting date: {message}'**
  String errorSelectingDate(Object message);

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String genericError(Object message);

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @addFriend.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get addFriend;

  /// No description provided for @addAFriend.
  ///
  /// In en, this message translates to:
  /// **'Add a friend'**
  String get addAFriend;

  /// No description provided for @theirEmail.
  ///
  /// In en, this message translates to:
  /// **'Their email'**
  String get theirEmail;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @friendRequestSentTo.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent to {email}'**
  String friendRequestSentTo(Object email);

  /// No description provided for @youAreNowFriendsWith.
  ///
  /// In en, this message translates to:
  /// **'You are now friends with {name}'**
  String youAreNowFriendsWith(Object name);

  /// No description provided for @requestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get requestDeclined;

  /// No description provided for @removeFriendQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove friend?'**
  String get removeFriendQuestion;

  /// No description provided for @removeFriendConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from your friends?'**
  String removeFriendConfirm(Object name);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removedFriend.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}'**
  String removedFriend(Object name);

  /// No description provided for @couldNotRemoveFriend.
  ///
  /// In en, this message translates to:
  /// **'Could not remove friend'**
  String get couldNotRemoveFriend;

  /// No description provided for @couldNotLoadFriends.
  ///
  /// In en, this message translates to:
  /// **'Could not load friends'**
  String get couldNotLoadFriends;

  /// No description provided for @addFriendsToCompete.
  ///
  /// In en, this message translates to:
  /// **'Add friends to compete'**
  String get addFriendsToCompete;

  /// No description provided for @friendsHealthShieldInfo.
  ///
  /// In en, this message translates to:
  /// **'Your Health Shield points and streak go head-to-head with friends. No health data is shared.'**
  String get friendsHealthShieldInfo;

  /// No description provided for @levelShort.
  ///
  /// In en, this message translates to:
  /// **'Lvl'**
  String get levelShort;

  /// No description provided for @pointsShort.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get pointsShort;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @yourFriends.
  ///
  /// In en, this message translates to:
  /// **'Your friends'**
  String get yourFriends;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @noFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get noFriendsYet;

  /// No description provided for @addSomeoneByEmail.
  ///
  /// In en, this message translates to:
  /// **'Add someone by their email to get started.'**
  String get addSomeoneByEmail;

  /// No description provided for @exportYourData.
  ///
  /// In en, this message translates to:
  /// **'Export your data'**
  String get exportYourData;

  /// No description provided for @copyClipboardOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard or send to your email'**
  String get copyClipboardOrEmail;

  /// No description provided for @copySummary.
  ///
  /// In en, this message translates to:
  /// **'Copy summary'**
  String get copySummary;

  /// No description provided for @readableHealthSummary.
  ///
  /// In en, this message translates to:
  /// **'Readable health summary'**
  String get readableHealthSummary;

  /// No description provided for @emailSummaryToMe.
  ///
  /// In en, this message translates to:
  /// **'Email summary to me'**
  String get emailSummaryToMe;

  /// No description provided for @sentToAccountEmail.
  ///
  /// In en, this message translates to:
  /// **'Sent to your account email'**
  String get sentToAccountEmail;

  /// No description provided for @copyFullDataCsv.
  ///
  /// In en, this message translates to:
  /// **'Copy full data (CSV)'**
  String get copyFullDataCsv;

  /// No description provided for @entriesActivitiesCsv.
  ///
  /// In en, this message translates to:
  /// **'Entries + activities as CSV'**
  String get entriesActivitiesCsv;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @noSummaryAvailable.
  ///
  /// In en, this message translates to:
  /// **'No summary available yet'**
  String get noSummaryAvailable;

  /// No description provided for @summaryCopied.
  ///
  /// In en, this message translates to:
  /// **'Summary copied to clipboard'**
  String get summaryCopied;

  /// No description provided for @summaryEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Summary sent to your email'**
  String get summaryEmailSent;

  /// No description provided for @couldNotSendSummary.
  ///
  /// In en, this message translates to:
  /// **'Could not send summary'**
  String get couldNotSendSummary;

  /// No description provided for @pleaseSignInFirst.
  ///
  /// In en, this message translates to:
  /// **'Please sign in first'**
  String get pleaseSignInFirst;

  /// No description provided for @noDataToExport.
  ///
  /// In en, this message translates to:
  /// **'No data to export yet'**
  String get noDataToExport;

  /// No description provided for @noHealthEntriesToExport.
  ///
  /// In en, this message translates to:
  /// **'No health entries to export yet'**
  String get noHealthEntriesToExport;

  /// No description provided for @noSportActivitiesToExport.
  ///
  /// In en, this message translates to:
  /// **'No sport activities to export yet'**
  String get noSportActivitiesToExport;

  /// No description provided for @healthEntriesCsvCopied.
  ///
  /// In en, this message translates to:
  /// **'Health entries CSV copied to clipboard'**
  String get healthEntriesCsvCopied;

  /// No description provided for @activitiesCsvCopied.
  ///
  /// In en, this message translates to:
  /// **'Activities CSV copied to clipboard'**
  String get activitiesCsvCopied;

  /// No description provided for @exportFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailedWithError(Object error);

  /// No description provided for @failedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failedWithError(Object error);

  /// No description provided for @fullDataCsvCopied.
  ///
  /// In en, this message translates to:
  /// **'Full data (CSV) copied to clipboard'**
  String get fullDataCsvCopied;

  /// No description provided for @managePermissions.
  ///
  /// In en, this message translates to:
  /// **'Manage permissions'**
  String get managePermissions;

  /// No description provided for @trackStepsOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Track steps on this phone'**
  String get trackStepsOnPhone;

  /// No description provided for @trackStepsOnPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Count steps with the phone\'s own sensor - no Samsung Health needed'**
  String get trackStepsOnPhoneSubtitle;

  /// No description provided for @autoDetectWalksRuns.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect walks & runs'**
  String get autoDetectWalksRuns;

  /// No description provided for @autoDetectWalksRunsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Logs walking/running sessions automatically, even when the app is closed (keeps a quiet notification running)'**
  String get autoDetectWalksRunsSubtitle;

  /// No description provided for @detectSleepBackground.
  ///
  /// In en, this message translates to:
  /// **'Detect sleep in the background'**
  String get detectSleepBackground;

  /// No description provided for @detectSleepBackgroundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notices long overnight rest and logs your sleep - keeps a quiet notification running'**
  String get detectSleepBackgroundSubtitle;

  /// No description provided for @couldNotStartDetection.
  ///
  /// In en, this message translates to:
  /// **'Could not start detection - check notification permission'**
  String get couldNotStartDetection;

  /// No description provided for @couldNotStartSleepTracking.
  ///
  /// In en, this message translates to:
  /// **'Could not start sleep tracking - check notification permission'**
  String get couldNotStartSleepTracking;

  /// No description provided for @removeDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove device'**
  String get removeDevice;

  /// No description provided for @removeDeviceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeDeviceQuestion(Object name);

  /// No description provided for @deviceRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String deviceRemoved(Object name);

  /// No description provided for @deviceConnectedSynced.
  ///
  /// In en, this message translates to:
  /// **'{name} connected — synced {details}'**
  String deviceConnectedSynced(Object name, Object details);

  /// No description provided for @deviceConnectedNoNewData.
  ///
  /// In en, this message translates to:
  /// **'{name} connected — no new data yet'**
  String deviceConnectedNoNewData(Object name);

  /// No description provided for @deviceConnectedGrantPermission.
  ///
  /// In en, this message translates to:
  /// **'{name} connected (grant Health permission to sync)'**
  String deviceConnectedGrantPermission(Object name);

  /// No description provided for @failedToAddDevice.
  ///
  /// In en, this message translates to:
  /// **'Failed to add device'**
  String get failedToAddDevice;

  /// No description provided for @healthPermissionsDenied.
  ///
  /// In en, this message translates to:
  /// **'Health permissions denied'**
  String get healthPermissionsDenied;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @streakMilestone.
  ///
  /// In en, this message translates to:
  /// **'Streak milestone!'**
  String get streakMilestone;

  /// No description provided for @streakMilestoneMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve logged your health {days} days in a row. Keep the fire going! 🔥'**
  String streakMilestoneMessage(Object days);

  /// No description provided for @nice.
  ///
  /// In en, this message translates to:
  /// **'Nice!'**
  String get nice;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get dailyReminder;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String timeLabel(Object time);

  /// No description provided for @morningStreakReminder.
  ///
  /// In en, this message translates to:
  /// **'Morning streak reminder'**
  String get morningStreakReminder;

  /// No description provided for @morningStreakReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A 9 AM nudge to log today and keep your streak alive'**
  String get morningStreakReminderSubtitle;

  /// No description provided for @medicineReminders.
  ///
  /// In en, this message translates to:
  /// **'Medicine reminders'**
  String get medicineReminders;

  /// No description provided for @medicineRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn all medicine reminders on or off'**
  String get medicineRemindersSubtitle;

  /// No description provided for @weeklyHealthReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly health report'**
  String get weeklyHealthReport;

  /// No description provided for @weeklyHealthReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI summary emailed every Monday'**
  String get weeklyHealthReportSubtitle;

  /// No description provided for @couldNotUpdateWeeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Could not update weekly report setting'**
  String get couldNotUpdateWeeklyReport;

  /// No description provided for @testNotifications.
  ///
  /// In en, this message translates to:
  /// **'Test notifications'**
  String get testNotifications;

  /// No description provided for @testNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send one now + one in 30 seconds'**
  String get testNotificationsSubtitle;

  /// No description provided for @notificationTest.
  ///
  /// In en, this message translates to:
  /// **'Notification test'**
  String get notificationTest;

  /// No description provided for @build.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get build;

  /// No description provided for @notificationsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Notifications allowed'**
  String get notificationsAllowed;

  /// No description provided for @exactAlarmsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms allowed'**
  String get exactAlarmsAllowed;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// No description provided for @scheduledPending.
  ///
  /// In en, this message translates to:
  /// **'Scheduled (pending)'**
  String get scheduledPending;

  /// No description provided for @sentNotificationTestExact.
  ///
  /// In en, this message translates to:
  /// **'Sent one now + one in 30s. If the 30s one never arrives, the OS (battery/Doze) is dropping it.'**
  String get sentNotificationTestExact;

  /// No description provided for @sentNotificationTestInexact.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms are off. If scheduled reminders never fire, allow Alarms & reminders for HealthTrackMe in Android settings.'**
  String get sentNotificationTestInexact;

  /// No description provided for @noActiveUser.
  ///
  /// In en, this message translates to:
  /// **'No active user'**
  String get noActiveUser;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordUpdated;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profilePhotoUpdated;

  /// No description provided for @errorUploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Error uploading photo: {error}'**
  String errorUploadingPhoto(Object error);

  /// No description provided for @privacyAccount.
  ///
  /// In en, this message translates to:
  /// **'Privacy / Account'**
  String get privacyAccount;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review privacy information'**
  String get privacyPolicySubtitle;

  /// No description provided for @deleteAllMyData.
  ///
  /// In en, this message translates to:
  /// **'Delete all my data'**
  String get deleteAllMyData;

  /// No description provided for @deleteAllMyDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanent account data removal'**
  String get deleteAllMyDataSubtitle;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get changePasswordSubtitle;

  /// No description provided for @notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSection;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enableNotifications;

  /// No description provided for @enableNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow HealthTrackMe to send reminders and alerts'**
  String get enableNotificationsSubtitle;

  /// No description provided for @dataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get dataPrivacy;

  /// No description provided for @couldNotDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account'**
  String get couldNotDeleteAccount;

  /// No description provided for @enterTime.
  ///
  /// In en, this message translates to:
  /// **'Enter time'**
  String get enterTime;

  /// No description provided for @enterValidTime.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid time'**
  String get enterValidTime;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hour;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get minute;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @deleteAllDataQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteAllDataQuestion;

  /// No description provided for @deleteAllDataDescription.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes your account and health data from HealthTrackMe. This cannot be undone.'**
  String get deleteAllDataDescription;

  /// No description provided for @deleteLoginSessionWarning.
  ///
  /// In en, this message translates to:
  /// **'Your login session will end after deletion.'**
  String get deleteLoginSessionWarning;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @changePasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password and choose a new one.'**
  String get changePasswordDescription;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @privacyPolicyLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: June 7, 2026'**
  String get privacyPolicyLastUpdated;

  /// No description provided for @privacyPolicyIntro.
  ///
  /// In en, this message translates to:
  /// **'HealthTrackMe uses your health information only to show your dashboard, reminders, reports, and wearable sync results inside the app.'**
  String get privacyPolicyIntro;

  /// No description provided for @privacyHealthDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Health data we store'**
  String get privacyHealthDataTitle;

  /// No description provided for @privacyHealthDataBody.
  ///
  /// In en, this message translates to:
  /// **'Profile details, symptoms, medicines, sleep, activity, steps, heart rate, calories, notes, reminders, and connected wearable device records.'**
  String get privacyHealthDataBody;

  /// No description provided for @privacyWearableSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Wearable and sensor sync'**
  String get privacyWearableSyncTitle;

  /// No description provided for @privacyWearableSyncBody.
  ///
  /// In en, this message translates to:
  /// **'When you enable sync, the app reads permitted Health Connect or device data and uploads the selected health metrics to your HealthTrackMe account.'**
  String get privacyWearableSyncBody;

  /// No description provided for @privacyProtectionTitle.
  ///
  /// In en, this message translates to:
  /// **'How your data is protected'**
  String get privacyProtectionTitle;

  /// No description provided for @privacyProtectionBody.
  ///
  /// In en, this message translates to:
  /// **'Account access is controlled by authentication. Health data is sent to the backend for your account features and is not sold for advertising.'**
  String get privacyProtectionBody;

  /// No description provided for @privacyNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get privacyNotificationsTitle;

  /// No description provided for @privacyNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Reminder settings are used to schedule medicine, diary, and health notifications. You can disable them from this screen or system settings.'**
  String get privacyNotificationsBody;

  /// No description provided for @privacyDeletingDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleting your data'**
  String get privacyDeletingDataTitle;

  /// No description provided for @privacyDeletingDataBody.
  ///
  /// In en, this message translates to:
  /// **'Use \"Delete all my data\" in Privacy / Account to request permanent removal of your account data from the app backend.'**
  String get privacyDeletingDataBody;

  /// No description provided for @privacyQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get privacyQuestionsTitle;

  /// No description provided for @privacyQuestionsBody.
  ///
  /// In en, this message translates to:
  /// **'For privacy questions, contact the HealthTrackMe project owner or your course project maintainer.'**
  String get privacyQuestionsBody;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @healthShield.
  ///
  /// In en, this message translates to:
  /// **'Health Shield'**
  String get healthShield;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak'**
  String dayStreak(Object count);

  /// No description provided for @startYourStreak.
  ///
  /// In en, this message translates to:
  /// **'Start your streak'**
  String get startYourStreak;

  /// No description provided for @loggedTodayBest.
  ///
  /// In en, this message translates to:
  /// **'Logged today ✓ • best {best}'**
  String loggedTodayBest(Object best);

  /// No description provided for @logTodayKeepAlive.
  ///
  /// In en, this message translates to:
  /// **'Log today to keep it alive'**
  String get logTodayKeepAlive;

  /// No description provided for @logHealthTodayBegin.
  ///
  /// In en, this message translates to:
  /// **'Log your health today to begin'**
  String get logHealthTodayBegin;

  /// No description provided for @editFavorites.
  ///
  /// In en, this message translates to:
  /// **'Edit favorites'**
  String get editFavorites;

  /// No description provided for @chooseShortcutsShownOnHome.
  ///
  /// In en, this message translates to:
  /// **'Choose the shortcuts shown on Home.'**
  String get chooseShortcutsShownOnHome;

  /// No description provided for @selectAtLeastOneFavorite.
  ///
  /// In en, this message translates to:
  /// **'Select at least one favorite.'**
  String get selectAtLeastOneFavorite;

  /// No description provided for @activityLoggedToday.
  ///
  /// In en, this message translates to:
  /// **'Activity logged today'**
  String get activityLoggedToday;

  /// No description provided for @walking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get walking;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @cycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get cycling;

  /// No description provided for @workout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workout;

  /// No description provided for @swimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get swimming;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @stepsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} steps'**
  String stepsCount(Object count);

  /// No description provided for @todayValueGoal.
  ///
  /// In en, this message translates to:
  /// **'Today: {value} / {goal}'**
  String todayValueGoal(Object value, Object goal);

  /// No description provided for @dailyGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Daily goal reached'**
  String get dailyGoalReached;

  /// No description provided for @stepsToDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'{count} steps to daily goal'**
  String stepsToDailyGoal(Object count);

  /// No description provided for @activityDurationSelectedRange.
  ///
  /// In en, this message translates to:
  /// **'Activity duration in the selected range.'**
  String get activityDurationSelectedRange;

  /// No description provided for @noActivityDataForThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No activity data for this period'**
  String get noActivityDataForThisPeriod;

  /// No description provided for @noMetricDataForThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No {metric} data for this period'**
  String noMetricDataForThisPeriod(Object metric);

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @averageToday.
  ///
  /// In en, this message translates to:
  /// **'Average today'**
  String get averageToday;

  /// No description provided for @averageThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Average this week'**
  String get averageThisWeek;

  /// No description provided for @averageThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Average this month'**
  String get averageThisMonth;

  /// No description provided for @averageAllTime.
  ///
  /// In en, this message translates to:
  /// **'Average all time'**
  String get averageAllTime;

  /// No description provided for @todaysActivityType.
  ///
  /// In en, this message translates to:
  /// **'Today\'s {type}'**
  String todaysActivityType(Object type);

  /// No description provided for @activityTypeThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{type} this week'**
  String activityTypeThisWeek(Object type);

  /// No description provided for @activityTypeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'{type} this month'**
  String activityTypeThisMonth(Object type);

  /// No description provided for @allActivityTypeActivities.
  ///
  /// In en, this message translates to:
  /// **'All {type} activities'**
  String allActivityTypeActivities(Object type);

  /// No description provided for @noActivityTypeActivitiesForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No {type} activities for this period'**
  String noActivityTypeActivitiesForPeriod(Object type);

  /// No description provided for @maxRange.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxRange;

  /// No description provided for @addActivityType.
  ///
  /// In en, this message translates to:
  /// **'Add {type}'**
  String addActivityType(Object type);

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'Distance (km)'**
  String get distanceKm;

  /// No description provided for @caloriesOptional.
  ///
  /// In en, this message translates to:
  /// **'Calories (optional)'**
  String get caloriesOptional;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @couldNotSaveActivity.
  ///
  /// In en, this message translates to:
  /// **'Could not save activity'**
  String get couldNotSaveActivity;

  /// No description provided for @workoutDetails.
  ///
  /// In en, this message translates to:
  /// **'Workout details'**
  String get workoutDetails;

  /// No description provided for @avgSpeed.
  ///
  /// In en, this message translates to:
  /// **'Avg. speed'**
  String get avgSpeed;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @avgPace.
  ///
  /// In en, this message translates to:
  /// **'Avg. pace'**
  String get avgPace;

  /// No description provided for @healthOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Charts, trends, and the monthly report now live inside the Health tab.'**
  String get healthOverviewSubtitle;

  /// No description provided for @vitalsShortcutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wellbeing, sleep and recent markers'**
  String get vitalsShortcutSubtitle;

  /// No description provided for @activityShortcutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Consistency and daily movement'**
  String get activityShortcutSubtitle;

  /// No description provided for @sleepShortcutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep trend and recovery'**
  String get sleepShortcutSubtitle;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @historyShortcutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reports and past entries'**
  String get historyShortcutSubtitle;

  /// No description provided for @sleepHoursSelectedRange.
  ///
  /// In en, this message translates to:
  /// **'Sleep hours in the selected range.'**
  String get sleepHoursSelectedRange;

  /// No description provided for @noSleepDataForThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No sleep data for this period'**
  String get noSleepDataForThisPeriod;

  /// No description provided for @tapAddSleepEntry.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a sleep entry.'**
  String get tapAddSleepEntry;

  /// No description provided for @couldNotLoadSleep.
  ///
  /// In en, this message translates to:
  /// **'Could not load sleep'**
  String get couldNotLoadSleep;

  /// No description provided for @tryLoadLatestSleepEntries.
  ///
  /// In en, this message translates to:
  /// **'Try again to load the latest sleep entries.'**
  String get tryLoadLatestSleepEntries;

  /// No description provided for @sleepSavedButNotReturned.
  ///
  /// In en, this message translates to:
  /// **'Sleep saved, but not returned by refresh'**
  String get sleepSavedButNotReturned;

  /// No description provided for @sleepAdded.
  ///
  /// In en, this message translates to:
  /// **'Sleep added'**
  String get sleepAdded;

  /// No description provided for @sleepDurationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Sleep duration is invalid'**
  String get sleepDurationInvalid;

  /// No description provided for @sleepDurationTooLong.
  ///
  /// In en, this message translates to:
  /// **'Sleep duration looks too long. Please check bedtime and wake time.'**
  String get sleepDurationTooLong;

  /// No description provided for @addSleep.
  ///
  /// In en, this message translates to:
  /// **'Add sleep'**
  String get addSleep;

  /// No description provided for @sleepManualEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save bedtime and wake time. Sleep duration is calculated automatically.'**
  String get sleepManualEntrySubtitle;

  /// No description provided for @bedtime.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get bedtime;

  /// No description provided for @wakeTime.
  ///
  /// In en, this message translates to:
  /// **'Wake time'**
  String get wakeTime;

  /// No description provided for @sleepApiSupportNote.
  ///
  /// In en, this message translates to:
  /// **'Bedtime and wake time are stored when the API supports these fields.'**
  String get sleepApiSupportNote;

  /// No description provided for @levelProgress.
  ///
  /// In en, this message translates to:
  /// **'Level progress'**
  String get levelProgress;

  /// No description provided for @totalXp.
  ///
  /// In en, this message translates to:
  /// **'{xp} total XP'**
  String totalXp(Object xp);

  /// No description provided for @xpLeft.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP left'**
  String xpLeft(Object xp);

  /// No description provided for @maxLevel.
  ///
  /// In en, this message translates to:
  /// **'Max level'**
  String get maxLevel;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @levelNumber.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelNumber(Object level);

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next level'**
  String get nextLevel;

  /// No description provided for @todaysShield.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Shield'**
  String get todaysShield;

  /// No description provided for @completeTodaysShieldEarnXp.
  ///
  /// In en, this message translates to:
  /// **'Complete today\'s shield to earn XP.'**
  String get completeTodaysShieldEarnXp;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @notCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get notCompleted;

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get notApplicable;

  /// No description provided for @trackingActive.
  ///
  /// In en, this message translates to:
  /// **'Tracking active'**
  String get trackingActive;

  /// No description provided for @xpReward.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String xpReward(Object xp);

  /// No description provided for @xpValue.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP'**
  String xpValue(Object xp);

  /// No description provided for @logSleepBuildShield.
  ///
  /// In en, this message translates to:
  /// **'Log sleep to build your shield'**
  String get logSleepBuildShield;

  /// No description provided for @sleepLogged.
  ///
  /// In en, this message translates to:
  /// **'Sleep logged'**
  String get sleepLogged;

  /// No description provided for @sleepLoggedBonusXp.
  ///
  /// In en, this message translates to:
  /// **'Sleep logged with bonus XP'**
  String get sleepLoggedBonusXp;

  /// No description provided for @completeTodaysShield.
  ///
  /// In en, this message translates to:
  /// **'Complete today\'s shield'**
  String get completeTodaysShield;

  /// No description provided for @activityCompleted.
  ///
  /// In en, this message translates to:
  /// **'Activity completed'**
  String get activityCompleted;

  /// No description provided for @logOneVitalReading.
  ///
  /// In en, this message translates to:
  /// **'Log one vital reading'**
  String get logOneVitalReading;

  /// No description provided for @vitalsLogged.
  ///
  /// In en, this message translates to:
  /// **'Vitals logged'**
  String get vitalsLogged;

  /// No description provided for @medicineTrackedToday.
  ///
  /// In en, this message translates to:
  /// **'Medicine tracked today'**
  String get medicineTrackedToday;

  /// No description provided for @keepYourStreakAlive.
  ///
  /// In en, this message translates to:
  /// **'Keep your streak alive'**
  String get keepYourStreakAlive;

  /// No description provided for @weeklyProgress.
  ///
  /// In en, this message translates to:
  /// **'Weekly progress'**
  String get weeklyProgress;

  /// No description provided for @xpThisWeek.
  ///
  /// In en, this message translates to:
  /// **'XP this week'**
  String get xpThisWeek;

  /// No description provided for @activeShieldDays.
  ///
  /// In en, this message translates to:
  /// **'active shield days'**
  String get activeShieldDays;

  /// No description provided for @completedDailyShields.
  ///
  /// In en, this message translates to:
  /// **'completed daily shields'**
  String get completedDailyShields;

  /// No description provided for @bestCategory.
  ///
  /// In en, this message translates to:
  /// **'best category'**
  String get bestCategory;

  /// No description provided for @weakestCategory.
  ///
  /// In en, this message translates to:
  /// **'weakest category'**
  String get weakestCategory;

  /// No description provided for @bestRecentStreak.
  ///
  /// In en, this message translates to:
  /// **'best recent streak'**
  String get bestRecentStreak;

  /// No description provided for @completeShieldKeepStreakAlive.
  ///
  /// In en, this message translates to:
  /// **'Complete today\'s shield to keep your streak alive'**
  String get completeShieldKeepStreakAlive;

  /// No description provided for @recentXp.
  ///
  /// In en, this message translates to:
  /// **'Recent XP'**
  String get recentXp;

  /// No description provided for @logTodaysHabitsEarnXp.
  ///
  /// In en, this message translates to:
  /// **'Log today\'s habits to earn XP.'**
  String get logTodaysHabitsEarnXp;

  /// No description provided for @addedToTodaysShield.
  ///
  /// In en, this message translates to:
  /// **'Added to today\'s shield'**
  String get addedToTodaysShield;

  /// No description provided for @startLoggingBuildShield.
  ///
  /// In en, this message translates to:
  /// **'Start logging sleep, activity and vitals to build your shield.'**
  String get startLoggingBuildShield;

  /// No description provided for @medicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medicine;

  /// No description provided for @sleepBonus.
  ///
  /// In en, this message translates to:
  /// **'Sleep bonus'**
  String get sleepBonus;

  /// No description provided for @medicineTracked.
  ///
  /// In en, this message translates to:
  /// **'Medicine tracked'**
  String get medicineTracked;

  /// No description provided for @dailyShieldBonus.
  ///
  /// In en, this message translates to:
  /// **'Daily shield bonus'**
  String get dailyShieldBonus;

  /// No description provided for @completeShieldBonus.
  ///
  /// In en, this message translates to:
  /// **'Complete shield bonus'**
  String get completeShieldBonus;

  /// No description provided for @todaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get todaySchedule;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @dosageValue.
  ///
  /// In en, this message translates to:
  /// **'Dosage: {dosage}'**
  String dosageValue(Object dosage);

  /// No description provided for @noScheduleSet.
  ///
  /// In en, this message translates to:
  /// **'No schedule set'**
  String get noScheduleSet;

  /// No description provided for @dosesToday.
  ///
  /// In en, this message translates to:
  /// **'{taken}/{expected} today'**
  String dosesToday(Object taken, Object expected);

  /// No description provided for @taken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get taken;

  /// No description provided for @take.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get take;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting'**
  String get deleting;

  /// No description provided for @loadingMedicines.
  ///
  /// In en, this message translates to:
  /// **'Loading medicines'**
  String get loadingMedicines;

  /// No description provided for @addMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add medicine'**
  String get addMedicine;

  /// No description provided for @editMedicine.
  ///
  /// In en, this message translates to:
  /// **'Edit medicine'**
  String get editMedicine;

  /// No description provided for @medicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine name'**
  String get medicineName;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptional;

  /// No description provided for @sideEffectsNotes.
  ///
  /// In en, this message translates to:
  /// **'Side effects / notes'**
  String get sideEffectsNotes;

  /// No description provided for @trackDosesSchedulesNotes.
  ///
  /// In en, this message translates to:
  /// **'Track doses, schedules, and notes.'**
  String get trackDosesSchedulesNotes;

  /// No description provided for @noMedicinesHere.
  ///
  /// In en, this message translates to:
  /// **'No medicines here'**
  String get noMedicinesHere;

  /// No description provided for @markedAsTaken.
  ///
  /// In en, this message translates to:
  /// **'Marked as taken'**
  String get markedAsTaken;

  /// No description provided for @doseRemoved.
  ///
  /// In en, this message translates to:
  /// **'Dose removed'**
  String get doseRemoved;

  /// No description provided for @couldNotUndoDose.
  ///
  /// In en, this message translates to:
  /// **'Could not undo dose'**
  String get couldNotUndoDose;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @undoDoseQuestion.
  ///
  /// In en, this message translates to:
  /// **'Undo dose?'**
  String get undoDoseQuestion;

  /// No description provided for @removeTodaysLastDose.
  ///
  /// In en, this message translates to:
  /// **'Remove today\'s last logged dose of {name}?'**
  String removeTodaysLastDose(Object name);

  /// No description provided for @deleteMedicineQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete medicine?'**
  String get deleteMedicineQuestion;

  /// No description provided for @removeMedicineFromList.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from your medicines list.'**
  String removeMedicineFromList(Object name);

  /// No description provided for @couldNotDeleteMedicine.
  ///
  /// In en, this message translates to:
  /// **'Could not delete medicine'**
  String get couldNotDeleteMedicine;

  /// No description provided for @medicineRemovedRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'{name} removed. Could not refresh list.'**
  String medicineRemovedRefreshFailed(Object name);

  /// No description provided for @medicineRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String medicineRemoved(Object name);

  /// No description provided for @medicineUpdated.
  ///
  /// In en, this message translates to:
  /// **'Medicine updated'**
  String get medicineUpdated;

  /// No description provided for @medicineAdded.
  ///
  /// In en, this message translates to:
  /// **'Medicine added'**
  String get medicineAdded;

  /// No description provided for @couldNotSaveMedicine.
  ///
  /// In en, this message translates to:
  /// **'Could not save medicine'**
  String get couldNotSaveMedicine;

  /// No description provided for @addReminderTimeOptional.
  ///
  /// In en, this message translates to:
  /// **'Add reminder time (optional)'**
  String get addReminderTimeOptional;

  /// No description provided for @addAnotherTime.
  ///
  /// In en, this message translates to:
  /// **'Add another time'**
  String get addAnotherTime;

  /// No description provided for @onceDaily.
  ///
  /// In en, this message translates to:
  /// **'Once daily'**
  String get onceDaily;

  /// No description provided for @twiceDaily.
  ///
  /// In en, this message translates to:
  /// **'Twice daily'**
  String get twiceDaily;

  /// No description provided for @threeTimesDaily.
  ///
  /// In en, this message translates to:
  /// **'Three times daily'**
  String get threeTimesDaily;

  /// No description provided for @fourTimesDaily.
  ///
  /// In en, this message translates to:
  /// **'Four times daily'**
  String get fourTimesDaily;

  /// No description provided for @everyOtherDay.
  ///
  /// In en, this message translates to:
  /// **'Every other day'**
  String get everyOtherDay;

  /// No description provided for @onceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Once weekly'**
  String get onceWeekly;

  /// No description provided for @asNeeded.
  ///
  /// In en, this message translates to:
  /// **'As needed'**
  String get asNeeded;

  /// No description provided for @timesDaily.
  ///
  /// In en, this message translates to:
  /// **'{count}x daily'**
  String timesDaily(Object count);

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @medicineCreationNotWired.
  ///
  /// In en, this message translates to:
  /// **'Medicine creation is not wired to an API endpoint yet.'**
  String get medicineCreationNotWired;

  /// No description provided for @medicineDetails.
  ///
  /// In en, this message translates to:
  /// **'Medicine details'**
  String get medicineDetails;

  /// No description provided for @loadingMedicine.
  ///
  /// In en, this message translates to:
  /// **'Loading medicine'**
  String get loadingMedicine;

  /// No description provided for @medicineNotFound.
  ///
  /// In en, this message translates to:
  /// **'Medicine not found'**
  String get medicineNotFound;

  /// No description provided for @medicineNotFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'This medicine may have been removed or is no longer available.'**
  String get medicineNotFoundDescription;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @nextDose.
  ///
  /// In en, this message translates to:
  /// **'Next dose'**
  String get nextDose;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @logFewNightsSleepTrend.
  ///
  /// In en, this message translates to:
  /// **'Log a few nights to see your sleep trend.'**
  String get logFewNightsSleepTrend;

  /// No description provided for @noActivityTrendYet.
  ///
  /// In en, this message translates to:
  /// **'No activity trend yet'**
  String get noActivityTrendYet;

  /// No description provided for @logActivitiesWeeklyPattern.
  ///
  /// In en, this message translates to:
  /// **'Log activities to see your weekly movement pattern.'**
  String get logActivitiesWeeklyPattern;

  /// No description provided for @activeDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active days'**
  String activeDaysCount(Object count);

  /// No description provided for @totalActivityDuration.
  ///
  /// In en, this message translates to:
  /// **'{duration} total activity'**
  String totalActivityDuration(Object duration);

  /// No description provided for @mostCommon.
  ///
  /// In en, this message translates to:
  /// **'Most common'**
  String get mostCommon;

  /// No description provided for @logVitalsWeeklyBaseline.
  ///
  /// In en, this message translates to:
  /// **'Log vitals to see your weekly baseline.'**
  String get logVitalsWeeklyBaseline;

  /// No description provided for @avgHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Avg heart rate'**
  String get avgHeartRate;

  /// No description provided for @avgStress.
  ///
  /// In en, this message translates to:
  /// **'Avg stress'**
  String get avgStress;

  /// No description provided for @latestBp.
  ///
  /// In en, this message translates to:
  /// **'Latest BP'**
  String get latestBp;

  /// No description provided for @latestSpO2.
  ///
  /// In en, this message translates to:
  /// **'Latest SpO2'**
  String get latestSpO2;

  /// No description provided for @medicationDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Medication data unavailable'**
  String get medicationDataUnavailable;

  /// No description provided for @tryRefreshMedicationRoutine.
  ///
  /// In en, this message translates to:
  /// **'Try again to refresh your medication routine.'**
  String get tryRefreshMedicationRoutine;

  /// No description provided for @medicationTrackingActive.
  ///
  /// In en, this message translates to:
  /// **'Medication tracking is active.'**
  String get medicationTrackingActive;

  /// No description provided for @addMedicinesTrackRoutine.
  ///
  /// In en, this message translates to:
  /// **'Add medicines to track your routine.'**
  String get addMedicinesTrackRoutine;

  /// No description provided for @activeMedicineCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active medicine'**
  String activeMedicineCount(Object count);

  /// No description provided for @activeMedicinesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active medicines'**
  String activeMedicinesCount(Object count);

  /// No description provided for @noActiveMedicines.
  ///
  /// In en, this message translates to:
  /// **'No active medicines'**
  String get noActiveMedicines;

  /// No description provided for @markedTakenToday.
  ///
  /// In en, this message translates to:
  /// **'{taken} of {total} marked taken today'**
  String markedTakenToday(Object taken, Object total);

  /// No description provided for @smartPatterns.
  ///
  /// In en, this message translates to:
  /// **'Smart Patterns'**
  String get smartPatterns;

  /// No description provided for @daysAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'Days analyzed'**
  String get daysAnalyzed;

  /// No description provided for @needsMoreData.
  ///
  /// In en, this message translates to:
  /// **'Needs more data'**
  String get needsMoreData;

  /// No description provided for @logSleepStressUnlockPatterns.
  ///
  /// In en, this message translates to:
  /// **'Log sleep and stress for a few more days to unlock patterns.'**
  String get logSleepStressUnlockPatterns;

  /// No description provided for @patternDetected.
  ///
  /// In en, this message translates to:
  /// **'Pattern detected'**
  String get patternDetected;

  /// No description provided for @noStrongPatternYet.
  ///
  /// In en, this message translates to:
  /// **'No strong pattern yet'**
  String get noStrongPatternYet;

  /// No description provided for @shortSleepHigherStressPattern.
  ///
  /// In en, this message translates to:
  /// **'Short sleep days are linked with higher stress in your logs.'**
  String get shortSleepHigherStressPattern;

  /// No description provided for @noStrongSleepStressPattern.
  ///
  /// In en, this message translates to:
  /// **'No strong sleep-stress pattern detected yet.'**
  String get noStrongSleepStressPattern;

  /// No description provided for @previousWeekNeedsMoreData.
  ///
  /// In en, this message translates to:
  /// **'Previous week comparison needs more data.'**
  String get previousWeekNeedsMoreData;

  /// No description provided for @vsLastWeek.
  ///
  /// In en, this message translates to:
  /// **'{change} vs last week'**
  String vsLastWeek(Object change);

  /// No description provided for @couldNotLoadInsights.
  ///
  /// In en, this message translates to:
  /// **'Could not load insights'**
  String get couldNotLoadInsights;

  /// No description provided for @tryLoadLatestWeeklyTrends.
  ///
  /// In en, this message translates to:
  /// **'Try again to load your latest weekly trends.'**
  String get tryLoadLatestWeeklyTrends;

  /// No description provided for @improving.
  ///
  /// In en, this message translates to:
  /// **'Improving'**
  String get improving;

  /// No description provided for @lowerThanUsual.
  ///
  /// In en, this message translates to:
  /// **'Lower than usual'**
  String get lowerThanUsual;

  /// No description provided for @healthAi.
  ///
  /// In en, this message translates to:
  /// **'Health AI'**
  String get healthAi;

  /// No description provided for @poweredByClaude.
  ///
  /// In en, this message translates to:
  /// **'Powered by Claude'**
  String get poweredByClaude;

  /// No description provided for @aiAssistantIntro.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m your health assistant. Here\'s a quick read on your week — ask me anything about your sleep, activity, or vitals.'**
  String get aiAssistantIntro;

  /// No description provided for @aiSuggestionSleepWeek.
  ///
  /// In en, this message translates to:
  /// **'How was my sleep this week?'**
  String get aiSuggestionSleepWeek;

  /// No description provided for @aiSuggestionActivity.
  ///
  /// In en, this message translates to:
  /// **'How active have I been?'**
  String get aiSuggestionActivity;

  /// No description provided for @aiSuggestionTrends.
  ///
  /// In en, this message translates to:
  /// **'Any concerning trends?'**
  String get aiSuggestionTrends;

  /// No description provided for @aiAskHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about your health…'**
  String get aiAskHint;

  /// No description provided for @aiSignInForInsight.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your personalized insight.'**
  String get aiSignInForInsight;

  /// No description provided for @aiLogMoreDataInsight.
  ///
  /// In en, this message translates to:
  /// **'Log a bit more health data and I can spot patterns for you.'**
  String get aiLogMoreDataInsight;

  /// No description provided for @aiSignInToAsk.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to ask about your health data.'**
  String get aiSignInToAsk;

  /// No description provided for @aiCouldNotAnswer.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I couldn\'t answer that right now.'**
  String get aiCouldNotAnswer;

  /// No description provided for @aiNoResponseAvailable.
  ///
  /// In en, this message translates to:
  /// **'No response available'**
  String get aiNoResponseAvailable;

  /// No description provided for @insightCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Insight copied to clipboard'**
  String get insightCopiedToClipboard;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @exportFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Export feature coming soon'**
  String get exportFeatureComingSoon;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sl':
      return AppLocalizationsSl();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
