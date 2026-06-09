// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class AppLocalizationsSl extends AppLocalizations {
  AppLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get appTitle => 'HealthTrackMe';

  @override
  String get logIn => 'Prijava';

  @override
  String get register => 'Registracija';

  @override
  String get createAccount => 'Ustvari račun';

  @override
  String get email => 'E-pošta';

  @override
  String get password => 'Geslo';

  @override
  String get confirmPassword => 'Potrdi geslo';

  @override
  String get firstName => 'Ime';

  @override
  String get lastName => 'Priimek';

  @override
  String get dateOfBirth => 'Datum rojstva';

  @override
  String get continueWithGoogle => 'Nadaljuj z Googlom';

  @override
  String get connecting => 'Povezovanje...';

  @override
  String get or => 'Ali';

  @override
  String get enterCredentialsToContinue =>
      'Za nadaljevanje vnesi prijavne podatke.';

  @override
  String get setUpHealthProfileToContinue =>
      'Za nadaljevanje nastavi zdravstveni profil.';

  @override
  String get dontHaveAccount => 'Nimaš računa?';

  @override
  String get alreadyHaveAccount => 'Že imaš račun?';

  @override
  String get emailRequired => 'E-pošta je obvezna.';

  @override
  String get enterValidEmail => 'Vnesi veljaven e-poštni naslov.';

  @override
  String get passwordRequired => 'Geslo je obvezno.';

  @override
  String get confirmPasswordRequired => 'Potrditev gesla je obvezna.';

  @override
  String get passwordsDoNotMatch => 'Gesli se ne ujemata.';

  @override
  String get required => 'Obvezno';

  @override
  String get enterYourPassword => 'Vnesi geslo';

  @override
  String get createPassword => 'Ustvari geslo';

  @override
  String get confirmYourPassword => 'Potrdi geslo';

  @override
  String get selectDate => 'Izberi datum';

  @override
  String get dateOfBirthRequired => 'Datum rojstva je obvezen.';

  @override
  String get accountCreatedSuccessfully => 'Račun je bil uspešno ustvarjen';

  @override
  String get invalidEmailOrPassword => 'Napačna e-pošta ali geslo.';

  @override
  String get emailAlreadyExists => 'E-pošta že obstaja.';

  @override
  String get couldNotCreateAccount => 'Računa ni bilo mogoče ustvariti.';

  @override
  String get googleClientIdNotConfigured => 'Google client ID ni nastavljen.';

  @override
  String get googleSignInCancelled => 'Prijava z Googlom je bila preklicana.';

  @override
  String get googleNoIdToken => 'Google ni vrnil ID žetona.';

  @override
  String get googleSignInUnavailable =>
      'Prijava z Googlom na tej platformi še ni na voljo.';

  @override
  String get googleSignInFailedTryAgain =>
      'Prijava z Googlom ni uspela. Poskusi znova.';

  @override
  String googleSignInFailed(Object message) {
    return 'Prijava z Googlom ni uspela: $message';
  }

  @override
  String get profile => 'Profil';

  @override
  String get preferences => 'Nastavitve';

  @override
  String get account => 'Račun';

  @override
  String get personalDetails => 'Osebni podatki';

  @override
  String get personalDetailsSubtitle => 'Ime, datum rojstva, spol, višina';

  @override
  String get friendsLeaderboard => 'Prijatelji in lestvica';

  @override
  String get friendsLeaderboardSubtitle =>
      'Primerjaj nize in Shield točke s prijatelji';

  @override
  String get exportData => 'Izvoz podatkov';

  @override
  String get exportDataSubtitle => 'Kopiraj ali pošlji zdravstvene podatke';

  @override
  String get units => 'Enote';

  @override
  String unitsSubtitle(
      Object weight, Object height, Object distance, Object temp) {
    return 'Teža: $weight • Višina: $height • Razdalja: $distance • Temp.: $temp';
  }

  @override
  String get unitsUpdated => 'Enote so posodobljene';

  @override
  String get weight => 'Teža';

  @override
  String get height => 'Višina';

  @override
  String get distance => 'Razdalja';

  @override
  String get temperature => 'Temperatura';

  @override
  String get heartRate => 'Srčni utrip';

  @override
  String get stress => 'Stres';

  @override
  String get bloodPressure => 'Krvni tlak';

  @override
  String get spO2 => 'SpO2';

  @override
  String get manualEntrySelectedDate =>
      'Ročni vnos bo shranjen za izbrani datum.';

  @override
  String metricSavedButNotReturned(Object metric) {
    return '$metric je shranjen, vendar ga osvežitev ni vrnila';
  }

  @override
  String metricAdded(Object metric) {
    return '$metric dodano';
  }

  @override
  String couldNotSaveMetric(Object metric) {
    return '$metric ni bilo mogoče shraniti';
  }

  @override
  String get startOfWeek => 'Začetek tedna';

  @override
  String get mondayOrSunday => 'Ponedeljek ali nedelja';

  @override
  String get monday => 'Ponedeljek';

  @override
  String get sunday => 'Nedelja';

  @override
  String get useIsoWeekFormat => 'Uporabi ISO obliko tedna';

  @override
  String get useUsWeekFormat => 'Uporabi ameriško obliko tedna';

  @override
  String startOfWeekSetTo(Object day) {
    return 'Začetek tedna nastavljen na $day';
  }

  @override
  String get language => 'Jezik';

  @override
  String languageSubtitle(Object language) {
    return '$language';
  }

  @override
  String get english => 'English';

  @override
  String get slovenian => 'Slovenščina';

  @override
  String get languageUpdated => 'Jezik je posodobljen';

  @override
  String get save => 'Shrani';

  @override
  String get cancel => 'Prekliči';

  @override
  String get close => 'Zapri';

  @override
  String get settings => 'Nastavitve';

  @override
  String get dashboard => 'Nadzorna plošča';

  @override
  String get wearables => 'Nosljive naprave';

  @override
  String get detective => 'Detektiv';

  @override
  String get signOut => 'Odjava';

  @override
  String get activity => 'Aktivnost';

  @override
  String get sleep => 'Spanje';

  @override
  String get vitals => 'Vitalni znaki';

  @override
  String get medicines => 'Zdravila';

  @override
  String get insightsTrends => 'Vpogledi / trendi';

  @override
  String get wearableDevices => 'Nosljive naprave';

  @override
  String get connectDeviceSyncHealthData =>
      'Povezi napravo in sinhroniziraj zdravstvene podatke';

  @override
  String get favorites => 'Priljubljeno';

  @override
  String get noData => 'Ni podatkov';

  @override
  String get updatedToday => 'Posodobljeno danes';

  @override
  String get tapToUpdate => 'Tapni za posodobitev';

  @override
  String get sleepLoggedToday => 'Spanje danes zabelezeno';

  @override
  String get noSleepDataForToday => 'Za danes ni podatkov o spanju';

  @override
  String get reviewScheduleAndDoses => 'Preglej urnik in odmerke';

  @override
  String get noActiveMedicinesScheduled => 'Ni aktivnih zdravil';

  @override
  String get historyReady => 'Zgodovina je pripravljena';

  @override
  String get reviewRecentHealthPatterns => 'Preglej nedavne zdravstvene vzorce';

  @override
  String get addModuleDataToUnlockTrends =>
      'Dodaj podatke modula za odklep trendov';

  @override
  String get syncAndManage => 'Sinhroniziraj in upravljaj';

  @override
  String get hydration => 'Hidracija';

  @override
  String get onPace => 'V dobrem tempu';

  @override
  String sleepingAverageOnTrack(Object average, Object goal) {
    return 'Spiš povprečno $average h - na poti si do cilja $goal h';
  }

  @override
  String sleepingAverageBelowGoal(Object average, Object gap, Object goal) {
    return 'Spiš povprečno $average h - $gap h pod ciljem $goal h';
  }

  @override
  String activeDaysOnPace(Object count, Object projected) {
    return '$count aktivnih dni do zdaj - na poti do $projected ta teden';
  }

  @override
  String activeDaysBelowPace(Object count, Object projected, Object goal) {
    return '$count aktivnih dni - na poti do $projected od $goal ta teden';
  }

  @override
  String get noActivityDataForToday => 'Za danes ni podatkov o aktivnosti';

  @override
  String get notSyncedYet => 'Še ni sinhronizirano';

  @override
  String get lastSyncedJustNow => 'Sinhronizirano pravkar';

  @override
  String lastSyncedMinutesAgo(Object minutes) {
    return 'Sinhronizirano pred $minutes min';
  }

  @override
  String lastSyncedHoursAgo(Object hours) {
    return 'Sinhronizirano pred $hours h';
  }

  @override
  String lastSyncedDaysAgo(Object days) {
    return 'Sinhronizirano pred $days d';
  }

  @override
  String get syncing => 'Sinhroniziranje...';

  @override
  String get syncHealthData => 'Sinhroniziraj zdravstvene podatke';

  @override
  String get connectedDevices => 'POVEZANE NAPRAVE';

  @override
  String get noDevicesConnected => 'Ni povezanih naprav';

  @override
  String get addWearableDescription =>
      'Dodaj nosljivo napravo za sledenje izvoru podatkov';

  @override
  String get addDevice => 'Dodaj napravo';

  @override
  String get howSyncingWorks => 'Kako deluje sinhronizacija';

  @override
  String get howSyncingWorksBody =>
      'Tapni \"Sinhroniziraj zdravstvene podatke\" za prenos zadnjih 7 dni iz Samsung Health ali Google Fit prek Health Connect. Preveri, da je Samsung Health nastavljen za sinhronizacijo s Health Connect.';

  @override
  String get addWearableDevice => 'Dodaj nosljivo napravo';

  @override
  String get selectDeviceType => 'Izberi tip naprave za registracijo';

  @override
  String get healthOverview => 'Zdravstveni pregled';

  @override
  String get weeklyHealthTrendsReady =>
      'Tedenski zdravstveni trendi so pripravljeni.';

  @override
  String get sleepAverage => 'Povprečje spanja';

  @override
  String get activeDays => 'Aktivni dnevi';

  @override
  String get vitalsStatus => 'Stanje vitalnih znakov';

  @override
  String get activeMedicines => 'Aktivna zdravila';

  @override
  String get sleepInsight => 'Vpogled v spanje';

  @override
  String get activityInsight => 'Vpogled v aktivnost';

  @override
  String get vitalsInsight => 'Vpogled v vitalne znake';

  @override
  String get medicinesInsight => 'Vpogled v zdravila';

  @override
  String get stable => 'Stabilno';

  @override
  String get needsData => 'Potrebuje podatke';

  @override
  String get thisWeek => 'ta teden';

  @override
  String activeDaysThisWeek(Object count) {
    return '$count ta teden';
  }

  @override
  String get unavailable => 'Ni na voljo';

  @override
  String get bestNight => 'Najboljša noč';

  @override
  String get lowestNight => 'Najslabša noč';

  @override
  String get higherThanUsual => 'Višje kot običajno';

  @override
  String get todayOverview => 'Današnji pregled';

  @override
  String get active => 'Aktivno';

  @override
  String get takenToday => 'Vzeto danes';

  @override
  String get noMedicinesYet => 'Zdravil še ni';

  @override
  String get addMedicinesDescription =>
      'Dodaj zdravila za sledenje odmerkom in opomnikom';

  @override
  String get couldNotLoadVitals => 'Vitalnih znakov ni bilo mogoče naložiti';

  @override
  String get tryLoadLatestHealthEntries =>
      'Poskusi znova naložiti najnovejše zdravstvene vnose.';

  @override
  String get retry => 'Poskusi znova';

  @override
  String get noDataForThisPeriod => 'Za to obdobje ni podatkov';

  @override
  String get tapPlusAddManualValue => 'Tapni + za rocni vnos vrednosti.';

  @override
  String get latest => 'Zadnje';

  @override
  String get average => 'Povprečje';

  @override
  String get minMax => 'Min / maks';

  @override
  String latestTrend(Object value) {
    return 'Zadnji trend: $value';
  }

  @override
  String get latestEntry => 'Zadnji vnos';

  @override
  String readingCountInRange(Object count) {
    return '$count meritev v obdobju';
  }

  @override
  String readingsCountInRange(Object count) {
    return '$count meritev v obdobju';
  }

  @override
  String get systolic => 'Sistolični';

  @override
  String get diastolic => 'Diastolični';

  @override
  String get diastolicLowerThanSystolic =>
      'Diastolični tlak mora biti nižji od sistoličnega';

  @override
  String lowHigh(Object low, Object high) {
    return 'Najmanj $low\nNajveč $high';
  }

  @override
  String get editProfile => 'Uredi profil';

  @override
  String get personalInformation => 'Osebni podatki';

  @override
  String get healthInformation => 'Zdravstveni podatki';

  @override
  String get enterYourFirstName => 'Vnesi ime';

  @override
  String get enterYourLastName => 'Vnesi priimek';

  @override
  String get firstNameRequired => 'Ime je obvezno';

  @override
  String get lastNameRequired => 'Priimek je obvezen';

  @override
  String get invalidDateFormat => 'Napačna oblika datuma (YYYY-MM-DD)';

  @override
  String get medicalConditions => 'Zdravstvena stanja';

  @override
  String get medicalConditionsHint => 'npr. sladkorna bolezen, astma...';

  @override
  String get allergies => 'Alergije';

  @override
  String get allergiesHint => 'npr. penicilin, arasidi...';

  @override
  String get profileUpdated => 'Profil je bil uspešno posodobljen';

  @override
  String errorSelectingDate(Object message) {
    return 'Napaka pri izbiri datuma: $message';
  }

  @override
  String genericError(Object message) {
    return 'Napaka: $message';
  }

  @override
  String get friends => 'Prijatelji';

  @override
  String get leaderboard => 'Lestvica';

  @override
  String get addFriend => 'Dodaj prijatelja';

  @override
  String get addAFriend => 'Dodaj prijatelja';

  @override
  String get theirEmail => 'Njegova e-pošta';

  @override
  String get sendRequest => 'Pošlji zahtevo';

  @override
  String friendRequestSentTo(Object email) {
    return 'Prošnja za prijateljstvo poslana na $email';
  }

  @override
  String youAreNowFriendsWith(Object name) {
    return 'Zdaj sta prijatelja z $name';
  }

  @override
  String get requestDeclined => 'Prošnja zavrnjena';

  @override
  String get removeFriendQuestion => 'Odstrani prijatelja?';

  @override
  String removeFriendConfirm(Object name) {
    return 'Odstraniš $name iz prijateljev?';
  }

  @override
  String get remove => 'Odstrani';

  @override
  String removedFriend(Object name) {
    return 'Odstranjen: $name';
  }

  @override
  String get couldNotRemoveFriend => 'Prijatelja ni bilo mogoče odstraniti';

  @override
  String get couldNotLoadFriends => 'Prijateljev ni bilo mogoče naložiti';

  @override
  String get addFriendsToCompete => 'Dodaj prijatelje za tekmovanje';

  @override
  String get friendsHealthShieldInfo =>
      'Točke zdravstvenega ščita in niz primerjaj s prijatelji. Zdravstveni podatki se ne delijo.';

  @override
  String get levelShort => 'Niv.';

  @override
  String get pointsShort => 'točk';

  @override
  String get requests => 'Prošnje';

  @override
  String get yourFriends => 'Tvoji prijatelji';

  @override
  String get pending => 'V teku';

  @override
  String get noFriendsYet => 'Prijateljev še ni';

  @override
  String get addSomeoneByEmail => 'Za začetek dodaj osebo po e-pošti.';

  @override
  String get exportYourData => 'Izvozi podatke';

  @override
  String get copyClipboardOrEmail =>
      'Kopiraj v odložišče ali pošlji na e-pošto';

  @override
  String get copySummary => 'Kopiraj povzetek';

  @override
  String get readableHealthSummary => 'Berljiv zdravstveni povzetek';

  @override
  String get emailSummaryToMe => 'Pošlji povzetek meni';

  @override
  String get sentToAccountEmail => 'Poslano na e-pošto računa';

  @override
  String get copyFullDataCsv => 'Kopiraj vse podatke (CSV)';

  @override
  String get entriesActivitiesCsv => 'Vnosi + aktivnosti kot CSV';

  @override
  String get exportFailed => 'Izvoz ni uspel';

  @override
  String get noSummaryAvailable => 'Povzetek še ni na voljo';

  @override
  String get summaryCopied => 'Povzetek kopiran v odložišče';

  @override
  String get summaryEmailSent => 'Povzetek poslan na tvojo e-pošto';

  @override
  String get couldNotSendSummary => 'Povzetka ni bilo mogoče poslati';

  @override
  String get pleaseSignInFirst => 'Najprej se prijavi';

  @override
  String get noDataToExport => 'Ni podatkov za izvoz';

  @override
  String get noHealthEntriesToExport => 'Ni zdravstvenih vnosov za izvoz';

  @override
  String get noSportActivitiesToExport => 'Ni športnih aktivnosti za izvoz';

  @override
  String get healthEntriesCsvCopied =>
      'CSV zdravstvenih vnosov kopiran v odložišče';

  @override
  String get activitiesCsvCopied => 'CSV aktivnosti kopiran v odložišče';

  @override
  String exportFailedWithError(Object error) {
    return 'Izvoz ni uspel: $error';
  }

  @override
  String failedWithError(Object error) {
    return 'Ni uspelo: $error';
  }

  @override
  String get fullDataCsvCopied => 'Vsi podatki (CSV) kopirani v odložišče';

  @override
  String get managePermissions => 'Upravljanje dovoljenj';

  @override
  String get trackStepsOnPhone => 'Sledi korakom na tem telefonu';

  @override
  String get trackStepsOnPhoneSubtitle =>
      'Štej korake s senzorjem telefona - Samsung Health ni potreben';

  @override
  String get autoDetectWalksRuns => 'Samodejno zaznaj hojo in tek';

  @override
  String get autoDetectWalksRunsSubtitle =>
      'Samodejno beleži hojo/tek, tudi ko je aplikacija zaprta (deluje tiho obvestilo)';

  @override
  String get detectSleepBackground => 'Zaznaj spanje v ozadju';

  @override
  String get detectSleepBackgroundSubtitle =>
      'Prepozna daljši nočni počitek in zabeleži spanje - deluje tiho obvestilo';

  @override
  String get couldNotStartDetection =>
      'Zaznavanja ni bilo mogoče zagnati - preveri dovoljenje za obvestila';

  @override
  String get couldNotStartSleepTracking =>
      'Sledenja spanju ni bilo mogoče zagnati - preveri dovoljenje za obvestila';

  @override
  String get removeDevice => 'Odstrani napravo';

  @override
  String removeDeviceQuestion(Object name) {
    return 'Odstrani $name?';
  }

  @override
  String deviceRemoved(Object name) {
    return '$name odstranjena';
  }

  @override
  String deviceConnectedSynced(Object name, Object details) {
    return '$name povezana — sinhronizirano: $details';
  }

  @override
  String deviceConnectedNoNewData(Object name) {
    return '$name povezana — novih podatkov še ni';
  }

  @override
  String deviceConnectedGrantPermission(Object name) {
    return '$name povezana (dovoli Health dovoljenje za sinhronizacijo)';
  }

  @override
  String get failedToAddDevice => 'Naprave ni bilo mogoče dodati';

  @override
  String get healthPermissionsDenied => 'Dovoljenja za Health so zavrnjena';

  @override
  String get syncFailed => 'Sinhronizacija ni uspela';

  @override
  String get streakMilestone => 'Mejnik niza!';

  @override
  String streakMilestoneMessage(Object days) {
    return 'Zdravje beležiš že $days dni zapored. Nadaljuj ta niz! 🔥';
  }

  @override
  String get nice => 'Super!';

  @override
  String get reminders => 'Opomniki';

  @override
  String get dailyReminder => 'Dnevni opomnik';

  @override
  String timeLabel(Object time) {
    return 'Čas: $time';
  }

  @override
  String get morningStreakReminder => 'Jutranji opomnik za niz';

  @override
  String get morningStreakReminderSubtitle =>
      'Opomnik ob 9:00 za današnji vnos in ohranitev niza';

  @override
  String get medicineReminders => 'Opomniki za zdravila';

  @override
  String get medicineRemindersSubtitle =>
      'Vklopi ali izklopi vse opomnike za zdravila';

  @override
  String get weeklyHealthReport => 'Tedensko zdravstveno poročilo';

  @override
  String get weeklyHealthReportSubtitle => 'AI povzetek poslan vsak ponedeljek';

  @override
  String get couldNotUpdateWeeklyReport =>
      'Nastavitve tedenskega poročila ni bilo mogoče posodobiti';

  @override
  String get testNotifications => 'Testna obvestila';

  @override
  String get testNotificationsSubtitle => 'Pošlji eno zdaj + eno čez 30 sekund';

  @override
  String get notificationTest => 'Test obvestil';

  @override
  String get build => 'Različica';

  @override
  String get notificationsAllowed => 'Obvestila dovoljena';

  @override
  String get exactAlarmsAllowed => 'Natančni alarmi dovoljeni';

  @override
  String get timezone => 'Časovni pas';

  @override
  String get scheduledPending => 'Načrtovana (čakajoča)';

  @override
  String get sentNotificationTestExact =>
      'Poslano je eno obvestilo zdaj in eno čez 30 s. Če obvestilo čez 30 s ne pride, ga sistem (baterija/Doze) blokira.';

  @override
  String get sentNotificationTestInexact =>
      'Natančni alarmi so izklopljeni. Če načrtovani opomniki ne delujejo, v Android nastavitvah dovoli Alarmi in opomniki za HealthTrackMe.';

  @override
  String get noActiveUser => 'Ni aktivnega uporabnika';

  @override
  String get passwordUpdated => 'Geslo posodobljeno';

  @override
  String get profilePhotoUpdated => 'Profilna slika posodobljena';

  @override
  String errorUploadingPhoto(Object error) {
    return 'Napaka pri nalaganju slike: $error';
  }

  @override
  String get privacyAccount => 'Zasebnost / račun';

  @override
  String get privacyPolicy => 'Pravilnik o zasebnosti';

  @override
  String get privacyPolicySubtitle => 'Preglej informacije o zasebnosti';

  @override
  String get deleteAllMyData => 'Izbriši vse moje podatke';

  @override
  String get deleteAllMyDataSubtitle => 'Trajna odstranitev podatkov računa';

  @override
  String get changePassword => 'Spremeni geslo';

  @override
  String get changePasswordSubtitle => 'Posodobi geslo računa';

  @override
  String get debug => 'Razhroščevanje';

  @override
  String get notificationsSection => 'Obvestila';

  @override
  String get enableNotifications => 'Omogoči obvestila';

  @override
  String get enableNotificationsSubtitle =>
      'Dovoli HealthTrackMe pošiljanje opomnikov in opozoril';

  @override
  String get dataPrivacy => 'Podatki in zasebnost';

  @override
  String get developerDebug => 'Razvijalec / razhroščevanje';

  @override
  String get couldNotDeleteAccount => 'Računa ni bilo mogoče izbrisati';

  @override
  String get apiConfiguration => 'API konfiguracija';

  @override
  String get apiConfigurationSubtitle => 'Preglej in ponastavi API nastavitve';

  @override
  String get enterTime => 'Vnesi čas';

  @override
  String get enterValidTime => 'Vnesi veljaven čas';

  @override
  String get hour => 'Ura';

  @override
  String get minute => 'Minuta';

  @override
  String get time => 'Čas';

  @override
  String get deleteAllDataQuestion => 'Izbriši vse podatke?';

  @override
  String get deleteAllDataDescription =>
      'To trajno odstrani tvoj račun in zdravstvene podatke iz HealthTrackMe. Tega ni mogoče razveljaviti.';

  @override
  String get deleteLoginSessionWarning =>
      'Tvoja prijavna seja se bo po izbrisu končala.';

  @override
  String get delete => 'Izbriši';

  @override
  String get changePasswordDescription =>
      'Vnesi trenutno geslo in izberi novo.';

  @override
  String get currentPassword => 'Trenutno geslo';

  @override
  String get newPassword => 'Novo geslo';

  @override
  String get confirmNewPassword => 'Potrdi novo geslo';

  @override
  String get updatePassword => 'Posodobi geslo';

  @override
  String get baseUrl => 'Osnovni URL';

  @override
  String get platform => 'Platforma';

  @override
  String get apiReachable => 'API dosegljiv';

  @override
  String get yes => 'Da';

  @override
  String get no => 'Ne';

  @override
  String get web => 'Splet';

  @override
  String get mobile => 'Mobilna aplikacija';

  @override
  String get resetApi => 'Ponastavi API';

  @override
  String get apiConfigurationReset => 'API konfiguracija ponastavljena';

  @override
  String get privacyPolicyLastUpdated => 'Nazadnje posodobljeno: 7. junij 2026';

  @override
  String get privacyPolicyIntro =>
      'HealthTrackMe uporablja tvoje zdravstvene podatke samo za prikaz nadzorne plošče, opomnikov, poročil in rezultatov sinhronizacije nosljivih naprav v aplikaciji.';

  @override
  String get privacyHealthDataTitle => 'Zdravstveni podatki, ki jih hranimo';

  @override
  String get privacyHealthDataBody =>
      'Podrobnosti profila, simptomi, zdravila, spanje, aktivnosti, koraki, srčni utrip, kalorije, opombe, opomniki in zapisi povezanih nosljivih naprav.';

  @override
  String get privacyWearableSyncTitle =>
      'Sinhronizacija nosljivih naprav in senzorjev';

  @override
  String get privacyWearableSyncBody =>
      'Ko omogočiš sinhronizacijo, aplikacija prebere dovoljene podatke iz Health Connect ali naprave in izbrane zdravstvene meritve naloži v tvoj račun HealthTrackMe.';

  @override
  String get privacyProtectionTitle => 'Kako so tvoji podatki zaščiteni';

  @override
  String get privacyProtectionBody =>
      'Dostop do računa je nadzorovan s prijavo. Zdravstveni podatki se pošljejo v zaledje za funkcije tvojega računa in se ne prodajajo za oglaševanje.';

  @override
  String get privacyNotificationsTitle => 'Obvestila';

  @override
  String get privacyNotificationsBody =>
      'Nastavitve opomnikov se uporabljajo za načrtovanje obvestil o zdravilih, dnevniku in zdravju. Izklopiš jih lahko na tem zaslonu ali v sistemskih nastavitvah.';

  @override
  String get privacyDeletingDataTitle => 'Brisanje tvojih podatkov';

  @override
  String get privacyDeletingDataBody =>
      'Uporabi \"Izbriši vse moje podatke\" v Zasebnost / račun, da zahtevaš trajno odstranitev podatkov računa iz zaledja aplikacije.';

  @override
  String get privacyQuestionsTitle => 'Vprašanja';

  @override
  String get privacyQuestionsBody =>
      'Za vprašanja o zasebnosti se obrni na lastnika projekta HealthTrackMe ali vzdrževalca projekta pri predmetu.';

  @override
  String get edit => 'Uredi';

  @override
  String get healthShield => 'Zdravstveni ščit';

  @override
  String dayStreak(Object count) {
    return '$count-dnevni niz';
  }

  @override
  String get startYourStreak => 'Začni svoj niz';

  @override
  String loggedTodayBest(Object best) {
    return 'Zabeleženo danes ✓ • najboljše $best';
  }

  @override
  String get logTodayKeepAlive => 'Zabeleži danes, da ohraniš niz';

  @override
  String get logHealthTodayBegin => 'Zabeleži zdravje danes za začetek';

  @override
  String get editFavorites => 'Uredi priljubljene';

  @override
  String get chooseShortcutsShownOnHome =>
      'Izberi bližnjice, prikazane na domači strani.';

  @override
  String get selectAtLeastOneFavorite => 'Izberi vsaj eno priljubljeno.';

  @override
  String get activityLoggedToday => 'Aktivnost zabeležena danes';

  @override
  String get walking => 'Hoja';

  @override
  String get running => 'Tek';

  @override
  String get cycling => 'Kolesarjenje';

  @override
  String get workout => 'Vadba';

  @override
  String get swimming => 'Plavanje';

  @override
  String get steps => 'Koraki';

  @override
  String stepsCount(Object count) {
    return '$count korakov';
  }

  @override
  String todayValueGoal(Object value, Object goal) {
    return 'Danes: $value / $goal';
  }

  @override
  String get dailyGoalReached => 'Dnevni cilj dosežen';

  @override
  String stepsToDailyGoal(Object count) {
    return 'Še $count korakov do dnevnega cilja';
  }

  @override
  String get activityDurationSelectedRange =>
      'Trajanje aktivnosti v izbranem obdobju.';

  @override
  String get noActivityDataForThisPeriod =>
      'Za to obdobje ni podatkov o aktivnosti';

  @override
  String noMetricDataForThisPeriod(Object metric) {
    return 'Za to obdobje ni podatkov za: $metric';
  }

  @override
  String get total => 'Skupaj';

  @override
  String get all => 'Vse';

  @override
  String get today => 'Danes';

  @override
  String get yesterday => 'Včeraj';

  @override
  String get averageToday => 'Povprečje danes';

  @override
  String get averageThisWeek => 'Povprečje ta teden';

  @override
  String get averageThisMonth => 'Povprečje ta mesec';

  @override
  String get averageAllTime => 'Povprečje za ves čas';

  @override
  String todaysActivityType(Object type) {
    return 'Današnja $type';
  }

  @override
  String activityTypeThisWeek(Object type) {
    return '$type ta teden';
  }

  @override
  String activityTypeThisMonth(Object type) {
    return '$type ta mesec';
  }

  @override
  String allActivityTypeActivities(Object type) {
    return 'Vse aktivnosti: $type';
  }

  @override
  String noActivityTypeActivitiesForPeriod(Object type) {
    return 'Za to obdobje ni aktivnosti: $type';
  }

  @override
  String get maxRange => 'Vse';

  @override
  String addActivityType(Object type) {
    return 'Dodaj: $type';
  }

  @override
  String get date => 'Datum';

  @override
  String get duration => 'Trajanje';

  @override
  String get distanceKm => 'Razdalja (km)';

  @override
  String get caloriesOptional => 'Kalorije (neobvezno)';

  @override
  String get notesOptional => 'Opombe (neobvezno)';

  @override
  String get couldNotSaveActivity => 'Aktivnosti ni bilo mogoče shraniti';

  @override
  String get workoutDetails => 'Podrobnosti vadbe';

  @override
  String get avgSpeed => 'Povpr. hitrost';

  @override
  String get calories => 'Kalorije';

  @override
  String get avgPace => 'Povpr. tempo';

  @override
  String get healthOverviewSubtitle =>
      'Grafi, trendi in mesečno poročilo so zdaj v zavihku Zdravje.';

  @override
  String get vitalsShortcutSubtitle => 'Počutje, spanje in nedavne meritve';

  @override
  String get activityShortcutSubtitle => 'Doslednost in dnevno gibanje';

  @override
  String get sleepShortcutSubtitle => 'Trend spanja in okrevanje';

  @override
  String get history => 'Zgodovina';

  @override
  String get historyShortcutSubtitle => 'Poročila in pretekli vnosi';

  @override
  String get sleepHoursSelectedRange => 'Ure spanja v izbranem obdobju.';

  @override
  String get noSleepDataForThisPeriod => 'Za to obdobje ni podatkov o spanju';

  @override
  String get tapAddSleepEntry => 'Tapni + za dodajanje vnosa spanja.';

  @override
  String get couldNotLoadSleep => 'Spanja ni bilo mogoče naložiti';

  @override
  String get tryLoadLatestSleepEntries =>
      'Poskusi znova naložiti najnovejše vnose spanja.';

  @override
  String get sleepSavedButNotReturned =>
      'Spanje je shranjeno, vendar ga osvežitev ni vrnila';

  @override
  String get sleepAdded => 'Spanje dodano';

  @override
  String get sleepDurationInvalid => 'Trajanje spanja ni veljavno';

  @override
  String get sleepDurationTooLong =>
      'Trajanje spanja je videti predolgo. Preveri čas spanja in prebujanja.';

  @override
  String get addSleep => 'Dodaj spanje';

  @override
  String get sleepManualEntrySubtitle =>
      'Shrani čas spanja in prebujanja. Trajanje spanja se izračuna samodejno.';

  @override
  String get bedtime => 'Čas spanja';

  @override
  String get wakeTime => 'Čas prebujanja';

  @override
  String get sleepApiSupportNote =>
      'Čas spanja in prebujanja se shranita, ko API podpira ta polja.';

  @override
  String get levelProgress => 'Napredek stopnje';

  @override
  String totalXp(Object xp) {
    return '$xp XP skupaj';
  }

  @override
  String xpLeft(Object xp) {
    return 'Še $xp XP';
  }

  @override
  String get maxLevel => 'Najvišja stopnja';

  @override
  String get level => 'Stopnja';

  @override
  String levelNumber(Object level) {
    return 'Stopnja $level';
  }

  @override
  String get nextLevel => 'Naslednja stopnja';

  @override
  String get todaysShield => 'Današnji ščit';

  @override
  String get completeTodaysShieldEarnXp =>
      'Dokončaj današnji ščit in si prisluži XP.';

  @override
  String get completed => 'Dokončano';

  @override
  String get notCompleted => 'Ni dokončano';

  @override
  String get notApplicable => 'Ni relevantno';

  @override
  String get trackingActive => 'Sledenje aktivno';

  @override
  String xpReward(Object xp) {
    return '+$xp XP';
  }

  @override
  String xpValue(Object xp) {
    return '$xp XP';
  }

  @override
  String get logSleepBuildShield => 'Zabeleži spanje in okrepi svoj ščit';

  @override
  String get sleepLogged => 'Spanje zabeleženo';

  @override
  String get sleepLoggedBonusXp => 'Spanje zabeleženo z bonus XP';

  @override
  String get completeTodaysShield => 'Dokončaj današnji ščit';

  @override
  String get activityCompleted => 'Aktivnost dokončana';

  @override
  String get logOneVitalReading => 'Zabeleži eno meritev vitalnih znakov';

  @override
  String get vitalsLogged => 'Vitalni znaki zabeleženi';

  @override
  String get medicineTrackedToday => 'Zdravilo danes zabeleženo';

  @override
  String get keepYourStreakAlive => 'Ohrani svoj niz';

  @override
  String get weeklyProgress => 'Tedenski napredek';

  @override
  String get xpThisWeek => 'XP ta teden';

  @override
  String get activeShieldDays => 'aktivni dnevi ščita';

  @override
  String get completedDailyShields => 'dokončani dnevni ščiti';

  @override
  String get bestCategory => 'najboljša kategorija';

  @override
  String get weakestCategory => 'najšibkejša kategorija';

  @override
  String get bestRecentStreak => 'najboljši nedavni niz';

  @override
  String get completeShieldKeepStreakAlive =>
      'Dokončaj današnji ščit, da ohraniš svoj niz';

  @override
  String get recentXp => 'Nedavni XP';

  @override
  String get logTodaysHabitsEarnXp =>
      'Zabeleži današnje navade in si prisluži XP.';

  @override
  String get addedToTodaysShield => 'Dodano k današnjemu ščitu';

  @override
  String get startLoggingBuildShield =>
      'Začni beležiti spanje, aktivnost in vitalne znake, da okrepiš svoj ščit.';

  @override
  String get medicine => 'Zdravilo';

  @override
  String get sleepBonus => 'Bonus za spanje';

  @override
  String get medicineTracked => 'Zdravilo zabeleženo';

  @override
  String get dailyShieldBonus => 'Bonus za dnevni ščit';

  @override
  String get completeShieldBonus => 'Bonus za dokončan ščit';

  @override
  String get todaySchedule => 'Današnji urnik';

  @override
  String get other => 'Drugo';

  @override
  String get morning => 'Jutro';

  @override
  String get afternoon => 'Popoldne';

  @override
  String get evening => 'Večer';

  @override
  String get dosage => 'Odmerek';

  @override
  String dosageValue(Object dosage) {
    return 'Odmerek: $dosage';
  }

  @override
  String get noScheduleSet => 'Urnik ni nastavljen';

  @override
  String dosesToday(Object taken, Object expected) {
    return '$taken/$expected danes';
  }

  @override
  String get taken => 'Vzeto';

  @override
  String get take => 'Vzemi';

  @override
  String get undo => 'Razveljavi';

  @override
  String get deleting => 'Brisanje';

  @override
  String get loadingMedicines => 'Nalaganje zdravil';

  @override
  String get addMedicine => 'Dodaj zdravilo';

  @override
  String get editMedicine => 'Uredi zdravilo';

  @override
  String get medicineName => 'Ime zdravila';

  @override
  String get frequency => 'Pogostost';

  @override
  String get select => 'Izberi';

  @override
  String get startDate => 'Začetni datum';

  @override
  String get endDate => 'Končni datum';

  @override
  String get reasonOptional => 'Razlog (neobvezno)';

  @override
  String get sideEffectsNotes => 'Stranski učinki / opombe';

  @override
  String get trackDosesSchedulesNotes => 'Sledi odmerkom, urnikom in opombam.';

  @override
  String get noMedicinesHere => 'Tukaj ni zdravil';

  @override
  String get markedAsTaken => 'Označeno kot vzeto';

  @override
  String get doseRemoved => 'Odmerek odstranjen';

  @override
  String get couldNotUndoDose => 'Odmerka ni bilo mogoče razveljaviti';

  @override
  String get networkError => 'Omrežna napaka';

  @override
  String get undoDoseQuestion => 'Razveljavi odmerek?';

  @override
  String removeTodaysLastDose(Object name) {
    return 'Odstrani zadnji današnji zabeležen odmerek za $name?';
  }

  @override
  String get deleteMedicineQuestion => 'Izbriši zdravilo?';

  @override
  String removeMedicineFromList(Object name) {
    return 'Odstrani \"$name\" s seznama zdravil.';
  }

  @override
  String get couldNotDeleteMedicine => 'Zdravila ni bilo mogoče izbrisati';

  @override
  String medicineRemovedRefreshFailed(Object name) {
    return '$name odstranjeno. Seznama ni bilo mogoče osvežiti.';
  }

  @override
  String medicineRemoved(Object name) {
    return '$name odstranjeno';
  }

  @override
  String get medicineUpdated => 'Zdravilo posodobljeno';

  @override
  String get medicineAdded => 'Zdravilo dodano';

  @override
  String get couldNotSaveMedicine => 'Zdravila ni bilo mogoče shraniti';

  @override
  String get addReminderTimeOptional => 'Dodaj čas opomnika (neobvezno)';

  @override
  String get addAnotherTime => 'Dodaj še en čas';

  @override
  String get onceDaily => 'Enkrat dnevno';

  @override
  String get twiceDaily => 'Dvakrat dnevno';

  @override
  String get threeTimesDaily => 'Trikrat dnevno';

  @override
  String get fourTimesDaily => 'Štirikrat dnevno';

  @override
  String get everyOtherDay => 'Vsak drugi dan';

  @override
  String get onceWeekly => 'Enkrat tedensko';

  @override
  String get asNeeded => 'Po potrebi';

  @override
  String timesDaily(Object count) {
    return '${count}x dnevno';
  }

  @override
  String get reason => 'Razlog';

  @override
  String get notSet => 'Ni nastavljeno';

  @override
  String get medicineCreationNotWired =>
      'Ustvarjanje zdravila še ni povezano z API endpointom.';

  @override
  String get medicineDetails => 'Podrobnosti zdravila';

  @override
  String get loadingMedicine => 'Nalaganje zdravila';

  @override
  String get medicineNotFound => 'Zdravila ni bilo mogoče najti';

  @override
  String get medicineNotFoundDescription =>
      'To zdravilo je bilo morda odstranjeno ali ni več na voljo.';

  @override
  String get schedule => 'Urnik';

  @override
  String get notes => 'Opombe';

  @override
  String get timeline => 'Časovnica';

  @override
  String get nextDose => 'Naslednji odmerek';

  @override
  String get inactive => 'Neaktivno';

  @override
  String get logFewNightsSleepTrend =>
      'Zabeleži nekaj noči, da vidiš trend spanja.';

  @override
  String get noActivityTrendYet => 'Trenda aktivnosti še ni';

  @override
  String get logActivitiesWeeklyPattern =>
      'Zabeleži aktivnosti, da vidiš tedenski vzorec gibanja.';

  @override
  String activeDaysCount(Object count) {
    return '$count aktivnih dni';
  }

  @override
  String totalActivityDuration(Object duration) {
    return '$duration skupne aktivnosti';
  }

  @override
  String get mostCommon => 'Najpogostejše';

  @override
  String get logVitalsWeeklyBaseline =>
      'Zabeleži vitalne znake, da vidiš tedensko izhodišče.';

  @override
  String get avgHeartRate => 'Povpr. srčni utrip';

  @override
  String get avgStress => 'Povpr. stres';

  @override
  String get latestBp => 'Zadnji krvni tlak';

  @override
  String get latestSpO2 => 'Zadnji SpO2';

  @override
  String get medicationDataUnavailable => 'Podatki o zdravilih niso na voljo';

  @override
  String get tryRefreshMedicationRoutine =>
      'Poskusi znova osvežiti rutino zdravil.';

  @override
  String get medicationTrackingActive => 'Sledenje zdravilom je aktivno.';

  @override
  String get addMedicinesTrackRoutine => 'Dodaj zdravila za sledenje rutini.';

  @override
  String activeMedicineCount(Object count) {
    return '$count aktivno zdravilo';
  }

  @override
  String activeMedicinesCount(Object count) {
    return '$count aktivnih zdravil';
  }

  @override
  String get noActiveMedicines => 'Ni aktivnih zdravil';

  @override
  String markedTakenToday(Object taken, Object total) {
    return '$taken od $total označeno kot vzeto danes';
  }

  @override
  String get smartPatterns => 'Pametni vzorci';

  @override
  String get daysAnalyzed => 'Analizirani dnevi';

  @override
  String get needsMoreData => 'Potrebnih je več podatkov';

  @override
  String get logSleepStressUnlockPatterns =>
      'Zabeleži spanje in stres še nekaj dni, da odkleneš vzorce.';

  @override
  String get patternDetected => 'Vzorec zaznan';

  @override
  String get noStrongPatternYet => 'Močnega vzorca še ni';

  @override
  String get shortSleepHigherStressPattern =>
      'Dnevi s krajšim spanjem so v tvojih zapisih povezani z višjim stresom.';

  @override
  String get noStrongSleepStressPattern =>
      'Močnega vzorca med spanjem in stresom še ni zaznati.';

  @override
  String get previousWeekNeedsMoreData =>
      'Primerjava s prejšnjim tednom potrebuje več podatkov.';

  @override
  String vsLastWeek(Object change) {
    return '$change v primerjavi s prejšnjim tednom';
  }

  @override
  String get couldNotLoadInsights => 'Vpogledov ni bilo mogoče naložiti';

  @override
  String get tryLoadLatestWeeklyTrends =>
      'Poskusi znova naložiti najnovejše tedenske trende.';

  @override
  String get improving => 'Izboljšanje';

  @override
  String get lowerThanUsual => 'Nižje kot običajno';

  @override
  String get healthAi => 'Zdravstveni AI';

  @override
  String get poweredByClaude => 'Poganja Claude';

  @override
  String get aiAssistantIntro =>
      'Živjo! Sem tvoj zdravstveni pomočnik. Tukaj je hiter pregled tvojega tedna — vprašaj me karkoli o spanju, aktivnosti ali vitalnih znakih.';

  @override
  String get aiSuggestionSleepWeek => 'Kako sem spal ta teden?';

  @override
  String get aiSuggestionActivity => 'Kako aktiven sem bil?';

  @override
  String get aiSuggestionTrends => 'Kakšni zaskrbljujoči trendi?';

  @override
  String get aiAskHint => 'Vprašaj o svojem zdravju…';

  @override
  String get aiSignInForInsight => 'Prijavi se, da vidiš osebni vpogled.';

  @override
  String get aiLogMoreDataInsight =>
      'Zabeleži še nekaj zdravstvenih podatkov in lahko bom poiskal vzorce.';

  @override
  String get aiSignInToAsk =>
      'Prijavi se, da lahko vprašaš o svojih zdravstvenih podatkih.';

  @override
  String get aiCouldNotAnswer => 'Oprosti, trenutno ne morem odgovoriti na to.';

  @override
  String get aiNoResponseAvailable => 'Odgovor ni na voljo';

  @override
  String get insightCopiedToClipboard => 'Vpogled kopiran v odložišče';

  @override
  String get dismiss => 'Zapri';

  @override
  String get exportFeatureComingSoon => 'Izvoz bo na voljo kmalu';
}
