// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Hazri';

  @override
  String get appNameNative => 'ਹਾਜ਼ਰੀ';

  @override
  String get tagline => 'Your daily Nitnem — always with you';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionNext => 'Next';

  @override
  String get actionBack => 'Back';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDone => 'Done';

  @override
  String get actionChange => 'Change';

  @override
  String get actionClose => 'Close';

  @override
  String get actionAllow => 'Allow';

  @override
  String get actionNotNow => 'Not now';

  @override
  String get actionDownload => 'Download';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionResume => 'Resume';

  @override
  String get actionShowMore => 'Show more';

  @override
  String get actionRead => 'Read';

  @override
  String get actionListen => 'Listen';

  @override
  String get actionShareCard => 'Share card';

  @override
  String get actionStart => 'Start';

  @override
  String get actionOpenReader => 'Open reader';

  @override
  String get actionGotIt => 'Got it';

  @override
  String get actionRetry => 'Try again';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String minutesLeft(int count) {
    return '$count min left';
  }

  @override
  String nOfM(int n, int m) {
    return '$n of $m';
  }

  @override
  String get navToday => 'Today';

  @override
  String get navNitnem => 'Nitnem';

  @override
  String get navSimran => 'Simran';

  @override
  String get navDiary => 'Diary';

  @override
  String get navSettings => 'Settings';

  @override
  String get slotAmritVela => 'Amrit Vela';

  @override
  String get slotEvening => 'Evening';

  @override
  String get slotBedtime => 'Bedtime';

  @override
  String get slotMorning => 'Morning';

  @override
  String get slotMoreBanis => 'More banis';

  @override
  String get chipWorksOffline => 'Works offline';

  @override
  String get chipNoLogin => 'No login';

  @override
  String get chipNoAdsOnGurbani => 'No ads on Gurbani';

  @override
  String get setupLanguageTitle => 'Choose your language';

  @override
  String get setupLanguagePunjabi => 'ਪੰਜਾਬੀ';

  @override
  String get setupLanguagePunjabiSub => 'Punjabi';

  @override
  String get setupLanguageHindi => 'हिन्दी';

  @override
  String get setupLanguageHindiSub => 'Hindi';

  @override
  String get setupLanguageEnglish => 'English';

  @override
  String get setupLanguageEnglishSub => 'English';

  @override
  String get setupReadingTitle => 'How do you like to read Gurbani?';

  @override
  String get scriptGurmukhi => 'Gurmukhi';

  @override
  String get scriptDevanagari => 'Devanagari';

  @override
  String get scriptRoman => 'Roman';

  @override
  String get textSize => 'Text size';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get elderMode => 'Elder mode';

  @override
  String get elderModeSub => 'Extra-large text and big buttons';

  @override
  String get versionsNote => 'Bani versions follow the SGPC Rehat Maryada';

  @override
  String get setupRemindersTitle => 'When should we remind you?';

  @override
  String get setupRemindersBody =>
      'Auto follows sunrise and sunset where you are. Tap any time to pick your own, or to switch a reminder off.';

  @override
  String get reminderAuto => 'Auto';

  @override
  String get reminderMyTime => 'My time';

  @override
  String get reminderOff => 'Reminder off';

  @override
  String get reminderAutoBeforeSunrise => 'Auto · before sunrise';

  @override
  String get reminderAutoAtSunset => 'Auto · at sunset';

  @override
  String get reminderAutoFollowsSunrise => 'Auto · follows sunrise';

  @override
  String get reminderEveningBefore => 'Evening before';

  @override
  String get reminderGurpurabDays => 'Gurpurab days';

  @override
  String get reminderDailySimran => 'Daily Simran';

  @override
  String get allowOnTimeTitle => 'Allow on-time reminders';

  @override
  String get allowOnTimeBody =>
      'Android asks once, so Amrit Vela reminders arrive to the minute.';

  @override
  String get allowOnTimeGranted => 'On-time reminders allowed';

  @override
  String get allowOnTimeDenied =>
      'Not now — reminders may arrive a few minutes late';

  @override
  String get notificationRationale =>
      'Reminders need permission to show notifications. Nothing else is ever sent.';

  @override
  String usingCityForSun(String city) {
    return 'Using $city for sunrise and sunset';
  }

  @override
  String get beginMyNitnem => 'Begin my Nitnem';

  @override
  String get audioNotInBuild => 'Audio for this bani is not in this build yet';

  @override
  String get audioNotInBuildSub =>
      'Japji Sahib has its recitation. The other banis follow once their recordings are ready.';

  @override
  String reminderSheetTitle(String bani) {
    return '$bani reminder';
  }

  @override
  String get reminderSheetSameTime => 'Same time every day';

  @override
  String reminderSheetAtSunsetToday(String time) {
    return 'At sunset · $time today';
  }

  @override
  String reminderSheetBeforeSunriseToday(String time) {
    return 'Before sunrise · $time today';
  }

  @override
  String get reminderSheetRepeat => 'Repeat';

  @override
  String get reminderSheetShowInMyDay => 'Show in my day';

  @override
  String get reminderSheetTurnOff => 'Turn off this reminder';

  @override
  String get dayMon => 'M';

  @override
  String get dayTue => 'T';

  @override
  String get dayWed => 'W';

  @override
  String get dayThu => 'T';

  @override
  String get dayFri => 'F';

  @override
  String get daySat => 'S';

  @override
  String get daySun => 'S';

  @override
  String get greeting => 'Sat Sri Akal ji';

  @override
  String get ctaStartNitnem => 'Start my Nitnem';

  @override
  String ctaContinueBani(String bani) {
    return 'Continue $bani';
  }

  @override
  String ctaStartBani(String bani) {
    return 'Start $bani';
  }

  @override
  String get ctaAllDone => 'Today\'s Nitnem complete';

  @override
  String arcBaniInProgress(String bani) {
    return '$bani in progress';
  }

  @override
  String get arcMorningComplete => 'Morning Nitnem complete';

  @override
  String arcBaniAt(String bani, String time) {
    return '$bani at $time';
  }

  @override
  String get arcNothingYet => 'Nothing started yet today';

  @override
  String simranTileProgress(int done, int total) {
    return '$done of $total min';
  }

  @override
  String get simranTileDone => 'Done today ✓';

  @override
  String get gurpurabTileToday => 'Today · Gurpurab';

  @override
  String get gurpurabTileTomorrow => 'Tomorrow · Gurpurab';

  @override
  String get gurpurabTileUpcoming => 'Gurpurab';

  @override
  String get helpSheetTitle => 'How Hazri works';

  @override
  String get helpTip1 =>
      'Tap Start my Nitnem on Today and the reader opens where you left off.';

  @override
  String get helpTip2 =>
      'In the reader, ਅ / अ / A switches script and Aa opens text size, meanings and pause marks.';

  @override
  String get helpTip3 =>
      'Reminders follow sunrise and sunset for your city, or a time you pick yourself.';

  @override
  String get helpAboutLink => 'About & credits';

  @override
  String get nitnemTitle => 'Nitnem';

  @override
  String get nitnemVersionLine => 'SGPC version';

  @override
  String get nitnemAudioSavedOffline => 'Audio saved offline';

  @override
  String get nitnemAudioNotAvailable => 'Audio not in this build';

  @override
  String get nitnemPlayAll => 'Play all';

  @override
  String nitnemSectionSummary(int count, int minutes) {
    return '$count banis · about $minutes min';
  }

  @override
  String nitnemYourTime(String time) {
    return 'Your time · $time';
  }

  @override
  String nitnemAtSunset(String time) {
    return 'At sunset · $time';
  }

  @override
  String nitnemResumeAt(String position) {
    return '$position in';
  }

  @override
  String nitnemLineOf(int line, int total) {
    return 'line $line of $total';
  }

  @override
  String get goalsSummaryCard => 'My paath goals';

  @override
  String goalsSummaryLine(int done, int total) {
    return '$done of $total done today';
  }

  @override
  String get goalsSetOne => 'Set a paath goal';

  @override
  String get baniNotInBuild => 'This bani is not in this build yet';

  @override
  String get baniNotInBuildBody =>
      'Hazri ships with the full text of Japji Sahib. The remaining banis arrive once their text has been reviewed.';

  @override
  String get readerTextSettings => 'Text settings';

  @override
  String get readerShowMeanings => 'Show meanings';

  @override
  String get readerMeaningLanguage => 'Meaning language';

  @override
  String get readerRomanUnder => 'Roman under Gurmukhi';

  @override
  String get readerPauseMarks => 'Pause marks (vishraam)';

  @override
  String get readerPauseMarksSub => 'Short and long pauses in colour';

  @override
  String get readerLarivaar => 'Larivaar';

  @override
  String get readerLarivaarSub => 'Words joined, as in the Saroop';

  @override
  String get readerKeepScreenOn => 'Keep screen on while reading';

  @override
  String get readerFollowAudio => 'Follow audio';

  @override
  String get readerFollowAudioSub =>
      'Highlight the line and scroll with the paath';

  @override
  String get readerShortPause => 'Short pause';

  @override
  String get readerLongPause => 'Long pause';

  @override
  String readerMeaningLabel(String language) {
    return 'Meaning: $language';
  }

  @override
  String readerCommentaryExpand(String source) {
    return 'Commentary ($source)';
  }

  @override
  String get readerCommentaryNote =>
      'Faridkot Wala Teeka — Braj/Sadhukkari Hindi commentary, converted to Devanagari. It explains the line rather than translating it.';

  @override
  String readerCompleteTitle(String bani) {
    return '$bani complete';
  }

  @override
  String readerCompleteNext(String bani) {
    return 'Next: $bani';
  }

  @override
  String get readerCompleteBackToNitnem => 'Back to Nitnem';

  @override
  String readerBackToPaath(int line) {
    return 'Back to paath · line $line';
  }

  @override
  String get readerAutoScrollPaused => 'Auto-scroll paused';

  @override
  String get readerFollowingAudio => 'Following audio';

  @override
  String readerSourceCredit(String text, String meanings) {
    return 'Text: $text · Meanings: $meanings';
  }

  @override
  String get langPunjabi => 'Punjabi';

  @override
  String get langHindi => 'Hindi';

  @override
  String get langEnglish => 'English';

  @override
  String get playerNowPlaying => 'Now playing';

  @override
  String get playerMorningNitnem => 'Morning Nitnem';

  @override
  String get playerUpNext => 'Up next';

  @override
  String get playerSpeed => 'Speed';

  @override
  String get playerSleepTimer => 'Sleep timer';

  @override
  String get diaryTitle => 'Nitnem Diary';

  @override
  String diaryStreakDays(int count) {
    return '$count days in a row';
  }

  @override
  String get diaryStreakOne => '1 day in a row';

  @override
  String get diaryStreakNone => 'Start whenever you like';

  @override
  String get diaryGentleStreak => 'A gentle streak';

  @override
  String diaryGrace(int count) {
    return 'Missed a day? Grace days keep it going. $count left this month.';
  }

  @override
  String get diaryGraceLabel => 'GRACE';

  @override
  String get diaryFooter =>
      'Kept on this phone. Backed up to your Google account.';

  @override
  String diaryTickTitle(String date) {
    return '$date';
  }

  @override
  String get diaryTickHint => 'Tick anything you completed on this day.';

  @override
  String get diaryTickTooOld =>
      'Only today and the last 7 days can be changed.';

  @override
  String get diaryStatJapji => 'Japji';

  @override
  String get diaryStatSimran => 'Simran';

  @override
  String get simranTitle => 'Daily Simran';

  @override
  String get simranSubtitle => '5 quiet minutes of Naam Simran';

  @override
  String get simranWaheguru => 'ਵਾਹਿਗੁਰੂ';

  @override
  String simranLeftOf(String total) {
    return 'left of $total';
  }

  @override
  String get simranEnd => 'End';

  @override
  String get simranBegin => 'Begin';

  @override
  String simranRecent(int done, int total) {
    return 'Done $done of the last $total days';
  }

  @override
  String get simranLoggedInDiary => 'Logged in Diary';

  @override
  String get simranCompleteToast => 'Simran complete — logged in your Diary';

  @override
  String get gurpurabTitle => 'Gurpurab calendar';

  @override
  String get gurpurabTodayNanakshahi => 'TODAY · NANAKSHAHI';

  @override
  String get gurpurabRemindersLine =>
      'Reminders the evening before and on the morning of each day';

  @override
  String get gurpurabThisWeek => 'This week';

  @override
  String get gurpurabComingUp => 'Coming up';

  @override
  String get gurpurabFooter =>
      'Dates follow the SGPC calendar. They ship with the app and update once a year.';

  @override
  String get gurpurabNoData =>
      'Calendar data for this date is not in this build';

  @override
  String gurpurabNoDataBody(String from, String to) {
    return 'Hazri ships the part of the SGPC jantri it has been given ($from to $to). The rest arrives in an app update.';
  }

  @override
  String get gurpurabFilterAll => 'All days';

  @override
  String get gurpurabFilterGurpurabsOnly => 'Gurpurabs only';

  @override
  String get gurpurabNoneUpcoming => 'No events in the next 90 days';

  @override
  String get goalsTitle => 'Goals';

  @override
  String goalsSubtitle(int done, int total) {
    return '$done of $total done today';
  }

  @override
  String get goalsAdd => 'Add to goal';

  @override
  String get goalsFooter =>
      'Goals, counts and reminders stay on this phone and appear in your Diary.';

  @override
  String get goalsEmpty =>
      'No goals yet. A goal is a quiet way to keep an extra paath going.';

  @override
  String get goalRuleOnce => 'Once a day';

  @override
  String goalRuleTimes(int count) {
    return '$count times a day';
  }

  @override
  String goalRuleForDays(int days, int count) {
    return 'For $days days · $count extra paath a day';
  }

  @override
  String goalRuleUntil(String date) {
    return 'Until $date';
  }

  @override
  String get goalStatusDone => 'Done today';

  @override
  String goalStatusProgress(int done, int total) {
    return '$done of $total today';
  }

  @override
  String goalStatusDay(int day, int total) {
    return 'Day $day of $total · pending';
  }

  @override
  String get goalStatusComplete => 'Goal complete';

  @override
  String get goalFieldBani => 'Bani';

  @override
  String get goalFieldTimes => 'How many times a day';

  @override
  String goalFieldTimesHint(int minutes) {
    return 'about $minutes min each';
  }

  @override
  String get goalFieldDuration => 'For how long';

  @override
  String get goalDurationEveryDay => 'Every day';

  @override
  String get goalDuration40Days => '40 days';

  @override
  String get goalDurationUntilDate => 'Until a date';

  @override
  String get goalFieldReminder => 'Reminder';

  @override
  String goalReminderEveryDayAt(String time) {
    return 'Every day at $time';
  }

  @override
  String get goalSave => 'Add to goal';

  @override
  String get goalMoreBanis => 'More…';

  @override
  String get goalPause => 'Pause goal';

  @override
  String get goalDeleteConfirm =>
      'Delete this goal? Its ticks stay in your Diary.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get settingsSectionReading => 'Reading';

  @override
  String get settingsGurbaniScript => 'Gurbani script';

  @override
  String get settingsGurbaniScriptSub => 'Also switch anytime from the reader';

  @override
  String get settingsShowMeaningsSub => 'Punjabi, Hindi or English';

  @override
  String get settingsSectionAudio => 'Audio';

  @override
  String get settingsNitnemAudio => 'Nitnem audio';

  @override
  String get settingsSukhmaniAudio => 'Sukhmani Sahib audio';

  @override
  String get settingsSectionVersions => 'Bani versions';

  @override
  String get settingsSectionReminders => 'Reminders';

  @override
  String get settingsPaathGoals => 'Paath goals';

  @override
  String get settingsPaathGoalsSub => 'Set a reminder for each goal';

  @override
  String settingsGoalsCount(int count) {
    return '$count goals';
  }

  @override
  String get settingsOnTimeReminders => 'On-time reminders';

  @override
  String get settingsOnTimeAllowed =>
      'Allowed — reminders arrive to the minute';

  @override
  String get settingsOnTimeNotAllowed =>
      'Not allowed — reminders may be a few minutes late';

  @override
  String get settingsSunFor => 'Sunrise & sunset for';

  @override
  String get settingsRemindersNotArriving => 'Reminders not arriving?';

  @override
  String get settingsSectionDisplay => 'Display';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeAuto => 'Auto';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsSectionDiary => 'Diary';

  @override
  String get settingsBackup => 'Back up to Google account';

  @override
  String get settingsBackupSub => 'Restores on a new phone';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsAboutCredits => 'About & credits';

  @override
  String get settingsAboutCreditsSub => 'Paathi, text sources, translations';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivacySub =>
      'No ads on Gurbani screens · No login · Works offline';

  @override
  String get settingsAnalytics => 'Share anonymous usage & crash reports';

  @override
  String get settingsAnalyticsSub => 'Not collected in this build';

  @override
  String get settingsLicences => 'Open-source licences';

  @override
  String settingsVersion(String version) {
    return 'Hazri $version';
  }

  @override
  String get cityPickerTitle => 'Choose your city';

  @override
  String get cityPickerSearch => 'Search cities';

  @override
  String get cityPickerUseLocation => 'Use my location';

  @override
  String get cityPickerNoResults =>
      'No city matched. Try a nearby larger city.';

  @override
  String get cityPickerNote =>
      'Only used on this phone, to work out sunrise and sunset.';

  @override
  String get batteryHelpTitle => 'Reminders not arriving?';

  @override
  String get batteryHelpBody =>
      'Some phones stop background apps to save battery. If a reminder is late or missing, allow Hazri to run in the background.';

  @override
  String get batteryHelpSamsung =>
      'Samsung: Settings → Battery → Background usage limits → remove Hazri from Sleeping apps.';

  @override
  String get batteryHelpXiaomi =>
      'Xiaomi/Redmi: Settings → Apps → Hazri → Autostart on, and Battery saver → No restrictions.';

  @override
  String get batteryHelpVivo =>
      'Vivo/iQOO: Settings → Battery → Background power consumption → allow Hazri.';

  @override
  String get batteryHelpOppo =>
      'Oppo/Realme: Settings → Battery → App battery usage → Hazri → Allow background activity.';

  @override
  String get batteryHelpOnePlus =>
      'OnePlus: Settings → Battery → Battery optimisation → Hazri → Don\'t optimise.';

  @override
  String get batteryHelpButton => 'Open battery settings';

  @override
  String get aboutTitle => 'About & credits';

  @override
  String get aboutPurpose =>
      'Hazri is a free, offline Nitnem app in Punjabi, Hindi and English. No ads on Gurbani. No login. Works offline.';

  @override
  String get aboutTextSources => 'Gurbani text & transliteration';

  @override
  String get aboutMeaningSources => 'Meanings and teeka';

  @override
  String get aboutCalendarSource => 'Calendar';

  @override
  String get aboutCityData => 'City data';

  @override
  String get aboutFonts => 'Fonts';

  @override
  String get aboutFontsBody =>
      'Mukta, Baloo Paaji 2, Playfair Display, Noto Serif Gurmukhi and Noto Serif Devanagari — SIL Open Font License.';

  @override
  String get aboutContact => 'Contact';

  @override
  String get aboutNoAudioYet =>
      'The recitation shipped with the app is played from the phone and never streamed.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyBody =>
      'Hazri has no password and no sign-in screen. Reading a bani, hearing it, seeing the calendar and writing your diary all happen on this phone and work with no network.';

  @override
  String get notifChannelGoals => 'Goal reminders';

  @override
  String notifGurpurabTitle(String event) {
    return 'Today: $event';
  }

  @override
  String get notifActionStartNitnem => 'Start Nitnem';

  @override
  String get notifActionLater => 'Later';

  @override
  String get shareCardTitle => 'Today\'s Vichar';

  @override
  String get shareCardFooter => 'Read daily on Hazri';

  @override
  String get shareCardTruncated => '…read in Hazri';

  @override
  String get shareCardPreview => 'Share card preview';

  @override
  String get shareCardShare => 'Share';

  @override
  String get comingSoonShort => 'Soon';

  @override
  String get audioIncluded => 'Recitation included';

  @override
  String get audioIncludedSub =>
      'Every bani plays offline, with the text following along.';

  @override
  String get settingsAudioOnPhone => 'Saved on this phone';

  @override
  String get aboutAudioHeading => 'Recitation';

  @override
  String get readerTapLineToSeek => 'Tap any line to start the paath there';

  @override
  String get readerLockControlsOff => 'Lock-screen controls are off';

  @override
  String get readerLockControlsOffSub =>
      'Allow notifications and the paath can be paused from the lock screen.';

  @override
  String get settingsLockScreenControls => 'Lock-screen controls';

  @override
  String get settingsLockScreenAllowed =>
      'Allowed — play and pause show while the phone is locked';

  @override
  String get settingsLockScreenBlocked =>
      'Not allowed — notifications are turned off for Hazri';

  @override
  String get actionStop => 'Stop';

  @override
  String get playerStillPlaying => 'Still playing';

  @override
  String get vicharTitle => 'Today\'s Vichar';

  @override
  String get vicharNative => 'ਅੱਜ ਦਾ ਵਿਚਾਰ';

  @override
  String get vicharSource => 'Sri Guru Granth Sahib Ji';

  @override
  String get vicharExplore => 'Explore';

  @override
  String get vicharShareTitle => 'Share this Vichar';

  @override
  String get vicharShareBody => 'Choose how to send it';

  @override
  String get vicharShareAsText => 'As text';

  @override
  String get vicharShareAsImage => 'As image';

  @override
  String get vicharMeaningPa => 'In Punjabi';

  @override
  String get vicharMeaningEn => 'In English';

  @override
  String get vicharNone => 'No Vichar in this build yet';

  @override
  String vicharDayOf(int day, int total) {
    return 'Line $day of $total';
  }

  @override
  String get goalsEmptyTitle => 'Set a daily goal';

  @override
  String get goalsEmptyBody =>
      'Choose a bani and how often to recite it. Your goals appear here on the day, at the time you set.';

  @override
  String get errorGeneric => 'Something went wrong.';

  @override
  String get errorContentDb =>
      'The bundled content could not be opened. Reinstalling Hazri should fix it.';

  @override
  String get calendarKindPrakash => 'Prakash';

  @override
  String get calendarKindGurgaddi => 'Gurgaddi';

  @override
  String get calendarKindJotiJot => 'Joti Jot';

  @override
  String get calendarKindShaheedi => 'Shaheedi';

  @override
  String get calendarKindJorMela => 'Jorh Mela';

  @override
  String get calendarKindBirth => 'Birth anniversary';

  @override
  String get calendarKindHistorical => 'Historical';

  @override
  String get calendarKindFestival => 'Festival';

  @override
  String get calendarKindSpecial => 'Observance';

  @override
  String get calendarKindSangrand => 'Sangrand';

  @override
  String get calendarKindPuranmashi => 'Puranmashi';

  @override
  String get calendarKindMasya => 'Masya';

  @override
  String get gurpurabSupplementary => 'Cross-check, not in the SGPC list';

  @override
  String get sangatSheetTitle => 'Join the sangat';

  @override
  String get sangatSheetBody =>
      'Hazri works fully without this. This adds the people.';

  @override
  String get sangatPerkSee => 'See who is reciting';

  @override
  String get sangatPerkSeeSub => 'Your family, your sangat, the world';

  @override
  String get sangatPerkGoal => 'Join a shared goal';

  @override
  String get sangatPerkGoalSub => 'A group\'s paath, counted together';

  @override
  String get sangatPerkDiary => 'Keep your diary safe';

  @override
  String get sangatPerkDiarySub => 'It comes back if you change phone';

  @override
  String get sangatSetUp => 'Set up — takes a couple of seconds';

  @override
  String get sangatNotNow => 'Not now';

  @override
  String get sangatNoAds =>
      'No password · no ads · your paath stays on your phone';

  @override
  String get sangatBannerTitle => 'Join the sangat';

  @override
  String get sangatBannerBody => 'See who is reciting with you, worldwide';

  @override
  String get sangatBannerTime => 'Takes a couple of seconds';

  @override
  String get sangatBannerCta => 'Set up';

  @override
  String get sangatProfileTitle => 'Join the sangat';

  @override
  String get sangatProfileSub => 'So your paath is counted with others';

  @override
  String get sangatFieldName => 'Your name';

  @override
  String get sangatFieldEmail => 'Email';

  @override
  String get sangatFieldEmailHint =>
      'How your sangat comes back if you change phone. Nobody else in the app ever sees it.';

  @override
  String get sangatFieldPhone => 'Phone';

  @override
  String get sangatFieldPhoneHint => 'Add a number';

  @override
  String get sangatFieldCity => 'City';

  @override
  String get sangatFieldCityHint =>
      'Shown as one dot on the Simran globe, and nothing finer.';

  @override
  String get sangatOptional => 'optional';

  @override
  String get sangatNoPasswordEver =>
      'No password to make or remember, and never will be. You are in the sangat as soon as you tap Continue.';

  @override
  String get sangatContinue => 'Continue';

  @override
  String get sangatWhatWeStore => 'What we store & why';

  @override
  String get sangatNeedName => 'Please add your name';

  @override
  String get sangatNeedEmail => 'Please add an email address';

  @override
  String get sangatBadEmail => 'That does not look like an email address';

  @override
  String get sangatNeedCity => 'Please add your city';

  @override
  String get sangatUnavailable =>
      'Could not reach the sangat. Your paath is safe on this phone — try again when you have signal.';

  @override
  String get sangatEmailInUse => 'This email already has a Hazri account';

  @override
  String get sangatJoined => 'You are in the sangat';

  @override
  String get sangatRefused =>
      'Something is wrong at our end, not yours. Your paath is safe on this phone.';

  @override
  String get sangatBusy =>
      'Too many attempts. Wait a few minutes and ask for another link — your signal is fine.';

  @override
  String sangatFailed(String code) {
    return 'Something went wrong at our end ($code). Your paath is safe on this phone.';
  }

  @override
  String get accountTitle => 'Your account';

  @override
  String get accountEmail => 'Email';

  @override
  String accountOpenedWith(String route) {
    return 'Opened with: $route';
  }

  @override
  String get accountPhone => 'Phone';

  @override
  String get accountCity => 'City';

  @override
  String get accountNotAdded => 'Not added';

  @override
  String get accountVerified => 'Verified';

  @override
  String get accountNotVerified => 'Not verified';

  @override
  String get accountVerifyTitle => 'Complete your verification';

  @override
  String get accountVerifyBody =>
      'Your account works either way. Confirming your email is what brings it back if you change phone.';

  @override
  String get accountVerifyCta => 'Verify my email';

  @override
  String get accountSafeTitle => 'Your sangat is safe';

  @override
  String get accountSafeBody =>
      'Sign in with this email on any phone and your groups, goals and diary come back.';

  @override
  String get accountSignOut => 'Sign out of this phone';

  @override
  String get accountSignOutWarn =>
      'Your account is not verified yet, so signing out loses it. Verify your email first.';

  @override
  String get accountSignOutConfirm => 'Sign out anyway';

  @override
  String get accountSectionYou => 'You';

  @override
  String get accountJoinedFirst => 'Join the sangat to see your account here.';

  @override
  String get verifyTitle => 'Verify your email';

  @override
  String get verifyCheckInbox => 'Check your email';

  @override
  String verifySentTo(String email) {
    return 'We sent a link to $email. Tap it and this phone is confirmed.';
  }

  @override
  String get verifySend => 'Send the link';

  @override
  String get verifySendAgain => 'Send it again';

  @override
  String get verifySent =>
      'Sent. It can take a minute to arrive — look in your spam folder if it does not.';

  @override
  String get verifyWrongAddress => 'Wrong address?';

  @override
  String get verifyChangeIt => 'Change it and we will send a new link';

  @override
  String get verifyUntilThen =>
      'Until this is done your groups and goals live on this phone only, and cannot be brought back if you change phone.';

  @override
  String get verifyLater => 'Do this later';

  @override
  String get verifyDoneTitle => 'Your email is confirmed';

  @override
  String get verifyDoneBody =>
      'This address can bring your account back on a new phone.';

  @override
  String get sangatTitle => 'Sangat';

  @override
  String get sangatCreateOrJoin => 'Create or join';

  @override
  String get sangatWorldwide => 'The sangat worldwide';

  @override
  String get sangatYourGroups => 'Your groups';

  @override
  String get sangatCanJoin => 'Groups you can join';

  @override
  String get sangatSeeAll => 'See all';

  @override
  String get sangatJoinGroup => 'Join';

  @override
  String get sangatHaveLink => 'Have a link? Join a group';

  @override
  String get sangatNoGroupsYet =>
      'You are in the sangat and not in a group yet. Make one for your family, or join one below.';

  @override
  String get sangatNotJoinedTitle =>
      'The sangat is where paath is counted together';

  @override
  String get groupKindFamily => 'family group';

  @override
  String get groupKindSangat => 'sangat';

  @override
  String get groupKindCircle => 'simran circle';

  @override
  String groupMembers(int count) {
    return '$count members';
  }

  @override
  String get groupNoGoalYet => 'No shared goal yet';

  @override
  String groupProgress(String done, String target, String unit) {
    return '$done of $target $unit';
  }

  @override
  String get unitPaath => 'paath';

  @override
  String get unitMinutes => 'minutes';

  @override
  String get groupGone => 'That group is no longer there';

  @override
  String get groupCreateTitle => 'Create a group';

  @override
  String get groupWhatKind => 'What kind';

  @override
  String get groupKindFamilySub => 'People you live with or call';

  @override
  String get groupKindSangatSub => 'A gurdwara or a wider group';

  @override
  String get groupKindCircleSub => 'Counted in minutes, not paath';

  @override
  String get groupNameLabel => 'Group name';

  @override
  String get groupNameHint =>
      'Seen by the people in the group. Change it whenever you like.';

  @override
  String get groupNeedName => 'Please give the group a name';

  @override
  String get groupWhoCanFind => 'Who can find it';

  @override
  String get groupPrivate => 'Private — people you send the link to';

  @override
  String get groupPrivateSub => 'Live straight away';

  @override
  String get groupListed => 'Listed in Sangat — anyone can find it';

  @override
  String get groupListedSub => 'Checked before it appears';

  @override
  String get groupListedNote =>
      'The name of a listed group is seen by people who never met you, so we read it before it appears — usually the same day. Private groups go live at once.';

  @override
  String get groupCreateCta => 'Create group';

  @override
  String get groupCreated => 'Your group is ready';

  @override
  String get groupSharedGoal => 'Shared goal';

  @override
  String get groupYou => 'YOU';

  @override
  String get groupTheGroup => 'THE GROUP';

  @override
  String get groupStartPaath => 'Start the paath';

  @override
  String get groupLogPaath => 'Log a paath';

  @override
  String get groupMembersTitle => 'Members';

  @override
  String get groupInvite => 'Invite';

  @override
  String get groupReport => 'Report this group';

  @override
  String get groupAnonMember => 'a member';

  @override
  String get groupYouSuffix => 'you';

  @override
  String get groupAdmin => 'Admin';

  @override
  String get groupLogTitle => 'Log a paath';

  @override
  String get groupLogAdd => 'Add to the group';

  @override
  String get groupLogged => 'Added to the group';

  @override
  String get groupLeave => 'Leave this group';

  @override
  String get groupLeft => 'You have left the group';

  @override
  String get groupSetGoalTitle => 'Shared goal';

  @override
  String get groupGoalWhat => 'What the group recites';

  @override
  String get groupGoalHowMany => 'How many, together';

  @override
  String get groupGoalByWhen => 'By when';

  @override
  String get groupGoalNoEnd => 'Or no end date';

  @override
  String get groupGoalPickDate => 'Pick another date';

  @override
  String get groupGoalWillSee => 'THE GROUP WILL SEE';

  @override
  String get groupGoalSet => 'Set the goal';

  @override
  String get groupGoalSaved => 'The group has its goal';

  @override
  String get groupGoalNeedTarget => 'Please choose how many';

  @override
  String get groupInviteTitle => 'Invite';

  @override
  String get groupInviteShareLink => 'Share this link';

  @override
  String get groupInviteShare => 'Share the link';

  @override
  String get groupInviteCopied => 'Link copied';

  @override
  String get groupInviteRemove => 'Remove';

  @override
  String get groupInviteStarted => 'You started this group';

  @override
  String get groupJoinByLinkTitle => 'Join a group';

  @override
  String get groupJoinByLinkBody =>
      'Paste the link somebody sent you, or the code at the end of it.';

  @override
  String get groupJoinByLinkLabel => 'Link or code';

  @override
  String get groupJoinByLinkCta => 'Join';

  @override
  String get groupJoinedOne => 'You are in the group';

  @override
  String get groupSimranSlug => 'Simran minutes';

  @override
  String get navSangat => 'Sangat';

  @override
  String simranOthersHere(int count) {
    return '$count others';
  }

  @override
  String get simranOthersSub => 'are here today';

  @override
  String get simranGlobeFirst => 'You are the first here today';

  @override
  String get simranGlobeTurn => 'Turn the globe with your hand';

  @override
  String get hazriMarked => 'Today\'s hazri is marked';

  @override
  String get hazriNotYet => 'Today\'s hazri is not marked yet';

  @override
  String hazriMarkedAtWith(String time, String what) {
    return 'Marked at $time, with $what';
  }

  @override
  String hazriMarkedAt(String time) {
    return 'Marked at $time';
  }

  @override
  String get hazriHow => 'One paath, or one sitting of simran, marks it';

  @override
  String get hazriSimran => 'Naam Simran';

  @override
  String get hazriGoalsAllDone => 'All of today\'s goals are done';

  @override
  String get hazriSeeDiary => 'See my diary';

  @override
  String get diaryHazriDot => 'Hazri';

  @override
  String get diaryGoalsDot => 'Goals';

  @override
  String get diaryWhatYouDid => 'What you completed';

  @override
  String get diaryNotYet => 'not yet';

  @override
  String get diaryHazriNote =>
      'One paath or five, a single sitting of simran — any of them marks the day\'s hazri. The count is what you did, not what you owed.';

  @override
  String get restoreTitle => 'Bring my account back';

  @override
  String get restoreBeenHere => 'You have been here before';

  @override
  String get restoreThisAccount => 'Restore this account';

  @override
  String get restoreOr => 'or';

  @override
  String get restoreStartFresh => 'Start a new account';

  @override
  String get restoreStartFreshSub => 'Nothing from the old one comes with it';

  @override
  String get restoreNothingSignedOut =>
      'Restoring signs nothing out. The same account can be on more than one phone at once.';

  @override
  String get restoreSendLink => 'Send me the link';

  @override
  String get restorePasteLabel => 'Paste the link from the email';

  @override
  String get restorePasteHint =>
      'Open the email on this phone, copy the whole link and paste it here.';

  @override
  String restoreDone(int count) {
    return 'Restored $count entries';
  }

  @override
  String get restoreDiaryNote =>
      'Your diary comes back only if sync was on. With sync off, your groups and goals are kept and the diary stays on the phone that wrote it.';

  @override
  String get restoreOpenToday => 'Open Today';

  @override
  String get linkProblemTitle => 'That link did not work';

  @override
  String get linkUsedTitle => 'Link already used';

  @override
  String get linkUsedBody =>
      'This link has signed in a phone already. Every link works once and then stops, which is what keeps a forwarded email from being a way in.';

  @override
  String get linkExpiredTitle => 'Link expired';

  @override
  String get linkExpiredBody =>
      'Links last an hour. This one has lapsed on its own — nobody used it.';

  @override
  String get linkWrongTitle => 'Not a link from us';

  @override
  String get linkWrongBody =>
      'That does not look like the link we sent. Copy the whole of it, including everything after the question mark.';

  @override
  String get linkMismatchTitle => 'Made for a different address';

  @override
  String get linkMismatchBody =>
      'This link is ours and it still works, but it was sent to a different address than the one above. Correct the address, or paste the link that went to it — a new link will not help.';

  @override
  String get linkSendAnother => 'Send a new link';

  @override
  String get linkWrongAddressNote =>
      'If neither of those was you, change your email address before you verify. A link is only ever sent to the address on the account.';

  @override
  String get verifyConfirmed => 'Your email is confirmed';

  @override
  String get privacyDataTitle => 'Privacy & my data';

  @override
  String get privacyOnPhoneOnly => 'On this phone only';

  @override
  String get privacyPhoneDiary => 'Your diary and streaks';

  @override
  String get privacyPhoneProgress => 'Reading position and goals';

  @override
  String get privacyPhoneContent => 'Every bani, its audio and the calendar';

  @override
  String get privacyShowMyName => 'Show my name in groups';

  @override
  String get privacyShowMyNameSub => 'Off shows you as “a member”';

  @override
  String get privacyDownload => 'Download everything we hold';

  @override
  String get privacyDownloadSub => 'A file you can keep, read and check';

  @override
  String get privacyDelete => 'Delete my account and data';

  @override
  String get privacyDeleteSub => 'Your diary stays on this phone';

  @override
  String get privacyDeleteConfirm =>
      'Delete everything the sangat holds? Your groups, your counts and your account go. Nothing on this phone is touched.';

  @override
  String get privacyDeleteDo => 'Delete it';

  @override
  String get privacyDeleted => 'Your account and its data are gone';

  @override
  String get libraryTitle => 'Vichar';

  @override
  String get librarySubtitle => 'Read, and look things up';

  @override
  String get librarySearchHint => 'Search articles, gurdwaras, banis…';

  @override
  String get libraryKindAll => 'All';

  @override
  String get libraryKindArticle => 'Articles';

  @override
  String get libraryKindGurdwara => 'Gurdwaras';

  @override
  String get libraryKindGuru => 'Guru Sahibans';

  @override
  String get libraryKindBani => 'Banis';

  @override
  String get libraryKindDay => 'Sikh days';

  @override
  String get libraryMoreToRead => 'More to read';

  @override
  String libraryMinutes(int count) {
    return '$count min read';
  }

  @override
  String get libraryNeedsConnection =>
      'Vichar is the one part of Hazri that needs a connection. Your banis, their recitations, the calendar and your diary never do.';

  @override
  String get libraryNothingMatches => 'Nothing matches that yet';

  @override
  String get libraryEmpty =>
      'There is nothing here yet. Vichar is written on the website and every phone reads the same copy, so what appears here is whatever has been published.';

  @override
  String get libraryOffline => 'No connection';

  @override
  String get libraryClear => 'Clear';

  @override
  String libraryResults(int count, String query) {
    return '$count results for “$query”';
  }

  @override
  String get libraryCorrections =>
      'Fetched from the website. If something here is wrong, it is corrected once there and every phone sees the correction.';

  @override
  String get libraryOpen => 'Open';

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncSubtitle => 'What happens, and when';

  @override
  String get syncStateSynced => 'Synced';

  @override
  String get syncStateSyncedSub => 'Everything is up to date';

  @override
  String get syncStateWaiting => 'No connection';

  @override
  String get syncStateWaitingSub =>
      'Carry on — your paath is saved on this phone and goes up when you are back';

  @override
  String get syncStateWifi => 'Waiting for Wi‑Fi';

  @override
  String get syncStateWifiSub =>
      'Your paath is saved on this phone. Turn off “only on Wi‑Fi” to send it now.';

  @override
  String syncStateSending(int count) {
    return 'Sending $count days';
  }

  @override
  String get syncStateOff => 'Sync is off';

  @override
  String get syncStateOffSub =>
      'Your diary lives on this phone and nowhere else';

  @override
  String get syncWorksWithout =>
      'Hazri works with no signal. Sync only decides whether your diary can come back on a new phone.';

  @override
  String get syncMyDiary => 'Sync my diary';

  @override
  String get syncWifiOnly => 'Only on Wi‑Fi';

  @override
  String get syncWifiOnlySub => 'Saves mobile data';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncNeedsAccount =>
      'Join the sangat first — there is nowhere to sync to without an account.';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get menuTooltip => 'Menu';

  @override
  String simranYouAndOthers(int count) {
    return 'You and $count others';
  }

  @override
  String get simranAreHereToday => 'are here today';

  @override
  String simranCitiesToday(int count) {
    return '$count cities today';
  }

  @override
  String get simranLegendYou => 'You';

  @override
  String get simranLegendHere => 'Here today';

  @override
  String simranBeginMinutes(int count) {
    return 'Begin Simran · $count min';
  }

  @override
  String get simranTurnGlobeShort => 'Turn the globe with your hand';

  @override
  String readerLoggedInDiary(String time) {
    return 'Logged in your diary · $time';
  }

  @override
  String get readerThisMarkedHazri =>
      'This is what marked it — the first thing finished today';

  @override
  String get readerStartAgain => 'Start again';

  @override
  String get readerNextBani => 'Next bani';

  @override
  String get goalsCardTitle => 'Your goals';

  @override
  String goalsDoneOf(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get goalSimranOrBani =>
      'Simran counts in minutes; a bani counts in paath';

  @override
  String get goalHowLong => 'How long each time';

  @override
  String get goalCustomMinutes => 'Custom';

  @override
  String get goalSimranLoops =>
      'The recitation is five minutes long and loops with a soft crossfade for anything longer.';

  @override
  String get groupStartCounts =>
      'Starting it here counts towards the goal when you finish';

  @override
  String get groupSetGoalCta => 'Set a shared goal';

  @override
  String get groupChangeGoal => 'Change the goal';

  @override
  String get groupNoGoalMember =>
      'The group\'s admin sets what it recites together';

  @override
  String get groupNoGoalAdmin =>
      'Set what the group recites together, and how many';

  @override
  String get groupInviteCode => 'Or give them this code';

  @override
  String get groupInviteCodeHow =>
      'In Hazri: Sangat → Have a link? Join a group → paste the code. The link itself opens the website, which is not built yet.';

  @override
  String groupInviteShareText(String group, String code) {
    return 'Join $group on Hazri.\n\nOpen Hazri → Sangat → “Have a link? Join a group”, and paste this code:\n\n$code';
  }

  @override
  String get diarySubtitle => 'Every day you marked your hazri';

  @override
  String get diaryStatHazriDays => 'hazri days';

  @override
  String get diaryStatGoalsMet => 'goals met';

  @override
  String get diaryStatPaath => 'paath';

  @override
  String get diaryStatSimranMinutes => 'simran minutes';

  @override
  String get diaryStatDaysInRow => 'days in a row';

  @override
  String get diaryTickAnything => 'Tick anything you completed on this day';

  @override
  String diaryNotYetAt(String time) {
    return 'not yet · $time';
  }

  @override
  String get simranPaused => 'Paused';

  @override
  String get simranBrandDaily => 'Daily ';

  @override
  String get simranBrandName => 'Simran';

  @override
  String get simranKicker => 'ONE BREATH · ONE WORLD · ONE WAHEGURU';

  @override
  String get simranHeadlineOne => 'One Name.';

  @override
  String get simranHeadlineTwoLead => 'A Brighter ';

  @override
  String get simranHeadlineTwoWord => 'World.';

  @override
  String get simranVerseOne => 'Breathe in peace, breathe out worry.';

  @override
  String get simranVerseTwoLead => 'With every breath, say ';

  @override
  String get simranVerseTwoWord => 'Waheguru.';

  @override
  String get notifAv1Title => 'Amrit Vela';

  @override
  String notifAv1Body(String bani) {
    return 'The quietest hour of the day is here. $bani is ready when you are.';
  }

  @override
  String notifAv2Title(String name) {
    return 'Good morning, $name';
  }

  @override
  String notifAv2Body(String city, String sunrise) {
    return 'Sunrise in $city is at $sunrise. Your Nitnem is ready.';
  }

  @override
  String get notifAv3Title => 'The sangat is waking up';

  @override
  String get notifAv3Body => 'Mark your Hazri with Sangat. Begin now.';

  @override
  String notifAv4Title(int streak) {
    return 'Day $streak of your Hazri';
  }

  @override
  String notifAv4Body(int streak) {
    return '$streak days in a row. Today\'s is waiting.';
  }

  @override
  String get notifAv5Title => 'Before the world wakes';

  @override
  String notifAv5Body(String bani) {
    return 'A few quiet minutes now, before the day begins. $bani is one tap away.';
  }

  @override
  String notifAv6Title(String weekday) {
    return 'Your Hazri for $weekday';
  }

  @override
  String get notifAv6Body =>
      'Mark today\'s Hazri with Nitnem or five minutes of Naam Simran.';

  @override
  String get notifAv7Title => 'Start the day with Waheguru';

  @override
  String get notifAv7Body =>
      'Nitnem first, everything else after. Hazri is open.';

  @override
  String notifGoalBaniTitle(String bani) {
    return 'Time for $bani';
  }

  @override
  String notifGoalBaniBody(int done, int target, int day, int days) {
    return '$done of $target today. Your goal, day $day of $days.';
  }

  @override
  String notifGoalBaniOpenBody(int done, int target) {
    return '$done of $target today.';
  }

  @override
  String notifGoalSimranTitle(int minutes) {
    return 'Your $minutes minutes of Naam Simran';
  }

  @override
  String get notifGoalSimranBody => 'One tap and the timer begins.';

  @override
  String get notifGurpurabBody => 'Mark the day with Nitnem and your Hazri.';

  @override
  String notifRememberTitle(String event) {
    return 'Today we remember: $event';
  }

  @override
  String get notifRememberBody => 'Begin the day with Nitnem and your Hazri.';

  @override
  String notifEventTitle(String event) {
    return 'Today: $event';
  }

  @override
  String get notifEventBody => 'Begin the day with Nitnem and your Hazri.';

  @override
  String get notifHn1Title => 'Your Hazri for today is still open';

  @override
  String get notifHn1Body =>
      'Five minutes of Naam Simran marks it. Begin when you\'re ready.';

  @override
  String notifHn2Title(int count) {
    return '$count of the sangat are here today';
  }

  @override
  String get notifHn2Body => 'Join them with five minutes of Waheguru Simran.';

  @override
  String get notifHn3Title => 'Five minutes, just for you';

  @override
  String get notifHn3Body =>
      'Begin the day with Waheguru Simran, and your Hazri is marked.';

  @override
  String get notifHn4Title => 'Make it a habit';

  @override
  String get notifHn4Body =>
      'Add Naam Simran to a daily goal and Hazri will remind you at your own time.';

  @override
  String get notifHn5Title => 'Five minutes before the day gets busy';

  @override
  String get notifHn5Body =>
      'A short sitting of Naam Simran now marks today\'s Hazri.';

  @override
  String notifHn6Title(String city) {
    return 'Light up $city on the globe';
  }

  @override
  String get notifHn6Body =>
      'Open Hazri and you show as live today. Five minutes of Simran marks your Hazri.';

  @override
  String get notifHn7Title => 'One small step today';

  @override
  String get notifHn7Body =>
      'Five minutes of Naam Simran. That\'s all today\'s Hazri needs.';

  @override
  String notifActionOpenBani(String bani) {
    return 'Open $bani';
  }

  @override
  String notifActionBeginMinutes(int minutes) {
    return 'Begin $minutes min';
  }

  @override
  String get notifActionSnooze => 'In 15 min';

  @override
  String get notifActionSeeCalendar => 'See calendar';

  @override
  String get notifActionSetGoal => 'Set a goal';

  @override
  String get notifActionOpenHazri => 'Open Hazri';

  @override
  String get notifActionOpenSangat => 'Open Sangat';

  @override
  String get notifChannelAmritVela => 'Amrit Vela';

  @override
  String get notifChannelCalendar => 'Gurpurab and Sikh events';

  @override
  String get notifChannelHazri => 'Hazri reminder';

  @override
  String get notifChannelSangat => 'Sangat';

  @override
  String get notifKindsHeading => 'What Hazri sends';

  @override
  String get notifKindAmritVela => 'Amrit Vela';

  @override
  String get notifKindAmritVelaSub => 'Every day at 4:00 AM';

  @override
  String get notifKindGoals => 'Goal reminders';

  @override
  String get notifKindGoalsSub => 'At the time you set on each goal';

  @override
  String get notifKindCalendar => 'Gurpurab and Sikh events';

  @override
  String get notifKindCalendarSub =>
      'On the day: Gurpurabs at 6:00 AM, other days at 7:00 AM';

  @override
  String get notifKindHazri => 'Hazri reminder';

  @override
  String get notifKindHazriSub =>
      'At 7:00 AM, only with no goal and no Hazri yet';

  @override
  String get notifKindSangat => 'Sangat';

  @override
  String get notifKindSangatSub =>
      'Your groups at 9:00 PM, and their milestones';

  @override
  String get notifExactNote =>
      'Reminders can arrive late, sometimes by hours, until Android allows Hazri \"Alarms & reminders\".';

  @override
  String get notifNoAds =>
      'Hazri never sends anything you did not ask for, and never an advertisement.';

  @override
  String get notifDiagnostics => 'Diagnostics';

  @override
  String get notifDiagnosticsSub => 'What this phone says about reminders';

  @override
  String get notifDiagAllowed => 'Notifications allowed';

  @override
  String get notifDiagExact => 'Exact alarms allowed';

  @override
  String get notifDiagBattery => 'Battery optimisation off for Hazri';

  @override
  String get notifDiagPending => 'Pending';

  @override
  String get notifDiagNext => 'Next';

  @override
  String get notifDiagNone => 'Nothing scheduled';

  @override
  String get notifDiagLast => 'Last delivered';

  @override
  String get notifDiagSendNow => 'Send one now';

  @override
  String get notifDiagSendSoon => 'Send one in two minutes';

  @override
  String get notifDiagTestTitle => 'Hazri test';

  @override
  String get notifDiagTestBody =>
      'If you can read this, reminders reach this phone.';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get goalSetCardTitle => 'Set a daily goal';

  @override
  String get goalSetCardSubtitleFirst =>
      'Choose the banis you want to recite each day.';

  @override
  String get goalSetCardSubtitleAgain =>
      'Your last goal is complete. Set a new one.';

  @override
  String get goalWidgetTitle => 'Today\'s goal';

  @override
  String goalWidgetProgress(int met, int total) {
    return '$met of $total done';
  }

  @override
  String goalTimesOfTarget(int done, int target) {
    return '$done of $target';
  }

  @override
  String goalSimranMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get goalInGoalBadge => 'In your goal';

  @override
  String get goalTimesPerDay => 'Times a day';

  @override
  String get goalDuration => 'How long';

  @override
  String goalDurationDays(int n) {
    return 'For $n days';
  }

  @override
  String goalDurationUntil(String date) {
    return 'Until $date';
  }

  @override
  String goalDayOfTotal(int n, int total) {
    return 'Day $n of $total';
  }

  @override
  String get goalReminder => 'Reminder';

  @override
  String get goalEditSave => 'Save';

  @override
  String get goalRemove => 'Remove';

  @override
  String goalRemoveConfirmTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get goalRemoveConfirmBody =>
      'It leaves your goal from today. Days already recorded stay as they are.';

  @override
  String get goalEndDateInPast => 'Choose today or a later date.';

  @override
  String get goalValidationMinutes => 'Enter 5 to 120 minutes.';

  @override
  String get goalReminderBody => 'Time for your daily goal';

  @override
  String goalTimesRule(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: '$times times a day',
      one: 'once a day',
    );
    return '$_temp0';
  }

  @override
  String get goalAddTitle => 'Add to your goal';

  @override
  String goalEditTitle(String name) {
    return 'Edit $name';
  }

  @override
  String get goalChoose => 'Choose';

  @override
  String get goalNaamSimran => 'Naam Simran';

  @override
  String get goalMinutesLabel => 'Minutes';

  @override
  String get goalCustom => 'Custom';

  @override
  String get goalEdit => 'Edit';

  @override
  String get goalCompleteTitle => 'Today\'s goal is done';

  @override
  String get diaryHazriMarked => 'Hazri marked';

  @override
  String get diaryNoHazri => 'No hazri';

  @override
  String diaryGoalSummary(int met, int total) {
    return 'Goal: $met of $total met';
  }

  @override
  String get diaryLegendHazri => 'Hazri';

  @override
  String get diaryLegendGoal => 'Goal met';

  @override
  String get diarySourceRead => 'Read';

  @override
  String get diarySourceListened => 'Listened';

  @override
  String get diarySourceDiary => 'Marked in Diary';

  @override
  String get diarySourceRestored => 'Restored';

  @override
  String get diarySourceMigrated => 'Carried over';

  @override
  String get diarySimranStoppedEarly => 'stopped early';

  @override
  String get diaryReadOnly => 'Days more than 7 days ago can\'t be changed.';

  @override
  String get diaryRecited => 'Recited';

  @override
  String diaryCountTimes(int count) {
    return '× $count';
  }

  @override
  String get diaryAddRemove => 'Add or take away';

  @override
  String get diaryStreakNow => 'days in a row now';

  @override
  String get diaryStreakLongest => 'your longest';

  @override
  String get todayStreakCaption => 'days of Hazri in a row';

  @override
  String get actionAdd => 'Add';

  @override
  String get profileWelcome => 'Welcome';

  @override
  String profileWelcomeName(String name) {
    return 'Welcome, $name';
  }

  @override
  String get profileBannerTitle => 'Set up your profile';

  @override
  String get profileBannerSubtitle =>
      'Add your name and email to personalise the app.';

  @override
  String get profileSetupTitle => 'Set up profile';

  @override
  String get profileFieldName => 'Name *';

  @override
  String get profileFieldEmail => 'Email *';

  @override
  String get profileFieldPhone => 'Phone (optional)';

  @override
  String get profileFieldCity => 'City *';

  @override
  String get profileSave => 'Save Profile';

  @override
  String get profileErrNameEmpty => 'Please enter your name';

  @override
  String get profileErrNameInvalid =>
      'Name must be 2–50 letters (spaces, . \' - allowed)';

  @override
  String get profileErrEmailEmpty => 'Please enter your email';

  @override
  String get profileErrEmailInvalid => 'Please enter a valid email address';

  @override
  String get profileErrCityEmpty => 'Please choose your city';

  @override
  String get profileCityChoose => 'Choose your city';

  @override
  String get profileCitySearch => 'Search cities';

  @override
  String get profileCityNearest => 'Not on the list? Choose the nearest city.';

  @override
  String get profileSavedTitle => 'Profile saved';

  @override
  String profileSavedBody(String email) {
    return 'Would you like to confirm your email $email? This is optional.';
  }

  @override
  String get profileSkipForNow => 'Skip for now';

  @override
  String get profileConfirmEmail => 'Confirm my email';

  @override
  String get profileSendFailed =>
      'Couldn\'t send the email. You can try again from your profile.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileRowName => 'Name';

  @override
  String get profileRowEmail => 'Email';

  @override
  String get profileRowPhone => 'Phone';

  @override
  String get profileRowCity => 'City';

  @override
  String get profileRowEmailStatus => 'Email status';

  @override
  String get profileNotProvided => 'Not provided';

  @override
  String get profileVerified => 'Verified';

  @override
  String get profileNotVerified => 'Not verified';

  @override
  String get profileStale =>
      'Showing saved details. Couldn\'t refresh your email status.';

  @override
  String get profileRetry => 'Retry';

  @override
  String get profileNone => 'No profile found';

  @override
  String get profileUnavailable => 'Couldn\'t load your profile.';

  @override
  String get profileChangeEmail => 'Change email';

  @override
  String get profileEditButton => 'Edit profile';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileEditSave => 'Save changes';

  @override
  String profileEmailPending(String email) {
    return 'Waiting for you to confirm $email';
  }

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profileEmailExistsTitle => 'Email already registered';

  @override
  String profileEmailExistsBody(String email) {
    return 'An account with $email already exists. To restore it on this phone, we will send a confirmation link to this email.';
  }

  @override
  String get profileSendLink => 'Send link';

  @override
  String get profileEmailNotFound =>
      'No account found for this email. Please tap Save Profile again.';

  @override
  String get emailSentTitle => 'Check your email';

  @override
  String emailSentVerify(String email) {
    return 'We sent a link to $email. Open it on this phone to confirm your email.';
  }

  @override
  String emailSentRestore(String email) {
    return 'We sent a link to $email. Open it on this phone within 1 hour to restore your profile.';
  }

  @override
  String get emailSentResend => 'Resend link';

  @override
  String emailSentResendIn(int n) {
    return 'Resend in ${n}s';
  }

  @override
  String get emailSentBackHome => 'Back to Home';

  @override
  String get emailSentWrongEmail => 'Wrong email? Change it';

  @override
  String get linkResultTitle => 'Email link';

  @override
  String get linkChecking => 'Checking your link…';

  @override
  String get linkEmailVerifiedTitle => 'Email verified';

  @override
  String get linkEmailVerified => 'Your email is verified.';

  @override
  String get linkEmailAlreadyVerified => 'Your email is already verified.';

  @override
  String get linkEmailChanged => 'Your new email is confirmed.';

  @override
  String get linkRestoredTitle => 'Profile restored';

  @override
  String linkRestored(String name) {
    return 'Welcome back, $name. Your profile has been restored.';
  }

  @override
  String get linkExpired => 'This link has expired.';

  @override
  String get linkInvalidTitle => 'Link not valid';

  @override
  String get linkInvalid =>
      'This link is invalid or has been replaced by a newer link.';

  @override
  String get linkUsed => 'This link has already been used.';

  @override
  String get linkWrongPhoneTitle => 'Wrong phone';

  @override
  String get linkWrongPhone =>
      'Open this link on the phone where you requested the restore.';

  @override
  String get linkDeviceHasProfileTitle => 'Profile already set up';

  @override
  String get linkDeviceHasProfile => 'This phone already has a profile.';

  @override
  String get linkBadRequest => 'Invalid link.';

  @override
  String get linkCouldNotCheckTitle => 'Couldn\'t check link';

  @override
  String get linkSendNew => 'Send a new link';

  @override
  String get linkTryAgain => 'Try again';

  @override
  String get linkGoHome => 'Go to Home';

  @override
  String get msgNetwork => 'No internet connection. Please try again.';

  @override
  String get msgGeneric => 'Something went wrong. Please try again.';

  @override
  String msgRateLimitSeconds(int n) {
    return 'Please wait $n seconds before requesting another email.';
  }

  @override
  String msgRateLimitHours(int h) {
    return 'Too many emails requested. Please try again in $h hours.';
  }

  @override
  String get msgEmailNotConfigured =>
      'Email can\'t be sent yet. Your profile is saved; try confirming later.';

  @override
  String get changeEmailTitle => 'Change email';

  @override
  String get changeEmailField => 'New email *';

  @override
  String get changeEmailHelper =>
      'We will send a new confirmation link to this email.';

  @override
  String get changeEmailSave => 'Save and send link';

  @override
  String get changeEmailSame => 'This is already your email';

  @override
  String get changeEmailExists => 'An account with this email already exists';

  @override
  String get changeEmailAlreadyVerified =>
      'Your email is already verified and can\'t be changed.';

  @override
  String get privacyNothingUnless =>
      'Nothing leaves this phone unless you make a profile or join a group. Analytics are not collected, and there is no advertising ID and no ads.';

  @override
  String get privacyPhoneSignIn =>
      'An anonymous sign-in when the app starts: an install number, never a name';

  @override
  String get privacyWithProfile => 'If you make a profile';

  @override
  String get privacyProfileDetails =>
      'Your name, email and city, and your phone number if you give it';

  @override
  String get privacyProfileMail =>
      'Emails only to that address: to confirm it, and to bring your profile back on a new phone';

  @override
  String get privacyProfileAttendance =>
      'Once a day, that you opened the app — which is how your city shows on the globe';

  @override
  String get privacyProfileBackup =>
      'A weekly backup of your goals, what you recited, your simran and your badges, so a restore can bring them back';

  @override
  String get privacyWithGroup => 'If you join a group';

  @override
  String get privacyGroupCounts =>
      'Each paath or sitting that counts toward your groups';

  @override
  String get privacyGroupName =>
      'Your name, shown only to the members of your groups';

  @override
  String get privacyGroupToken =>
      'This phone\'s notification token, language and time zone, for the group\'s notifications';

  @override
  String get privacyGlobe =>
      'The globe shows a city and a count, never a name. Nothing is sold or shared with anyone.';

  @override
  String backupLastLine(String date) {
    return 'Last backed up $date';
  }

  @override
  String get backupNever => 'Not backed up yet';

  @override
  String get backupStale => 'Not backed up for over two weeks';

  @override
  String get backupNowButton => 'Back up now';

  @override
  String get backupDone => 'Backed up';

  @override
  String get restoreDataButton => 'Restore my goals and diary';

  @override
  String get restoreConfirmTitle => 'Restore from backup?';

  @override
  String get restoreConfirmBody =>
      'This adds your goals and diary from the backup to this phone. Nothing already on this phone is removed.';

  @override
  String restoreAsOf(String date) {
    return 'Backup from $date. Anything after that is not included.';
  }

  @override
  String get restoreNothing => 'There is no backup to restore yet';

  @override
  String get restoreButton => 'Restore';

  @override
  String get backupSectionTitle => 'Backup';

  @override
  String get sangatMyGroups => 'My groups';

  @override
  String get sangatBuiltInGroups => 'Join the sangat';

  @override
  String get sangatEndedHeading => 'Ended';

  @override
  String get sangatCreate => 'Create group';

  @override
  String get sangatJoinWithCode => 'Join with a code';

  @override
  String get sangatJoin => 'Join';

  @override
  String get sangatLeave => 'Leave';

  @override
  String get sangatCreateNeedsProfile =>
      'Create your profile to start a group of your own.';

  @override
  String sangatLimitReached(int limit) {
    return 'You have $limit active groups. To start more, write to support@hazri.me.';
  }

  @override
  String get sangatGroupName => 'Group name';

  @override
  String get sangatGoalBani => 'Paath of one bani';

  @override
  String get sangatGoalSimran => 'Naam Simran';

  @override
  String get sangatGoalTarget => 'Target';

  @override
  String get sangatGoalEnds => 'Ends on';

  @override
  String sangatGoalSummaryBani(int target, String bani, String date) {
    return '$target $bani by $date';
  }

  @override
  String sangatGoalSummarySimran(int target, String date) {
    return '$target minutes of Naam Simran by $date';
  }

  @override
  String sangatProgress(int total, int target, int pct) {
    return '$total of $target · $pct%';
  }

  @override
  String sangatToday(int count) {
    return '$count today';
  }

  @override
  String sangatDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String sangatEndedOn(String date) {
    return 'Ended on $date';
  }

  @override
  String sangatMembers(int count) {
    return '$count members';
  }

  @override
  String sangatMoreMembers(int count) {
    return '$count more members';
  }

  @override
  String get sangatAnonymousName => 'Sangat member';

  @override
  String get sangatCreatorLabel => 'Started this group';

  @override
  String get sangatShareInvite => 'Share invite';

  @override
  String sangatInviteMessage(
    String group,
    int target,
    String goal,
    String date,
    String link,
    String code,
  ) {
    return 'Join \"$group\" on Hazri: $target $goal together by $date. Tap $link or enter code $code in the app.';
  }

  @override
  String get sangatResetCode => 'Reset invite code';

  @override
  String get sangatPasteCode => 'Paste code';

  @override
  String get sangatCodeInvalid =>
      'This code isn\'t valid. Ask for a new invite.';

  @override
  String get sangatGroupFull => 'This group is full.';

  @override
  String get sangatGroupEnded => 'This group has ended.';

  @override
  String get sangatChangeEndDate => 'Change end date';

  @override
  String get sangatRemoveMember => 'Remove from group';

  @override
  String get sangatDeleteGroup => 'Delete group';

  @override
  String get sangatReport => 'Report group';

  @override
  String get sangatReportReasonOffensive => 'Offensive name';

  @override
  String get sangatReportReasonSpam => 'Spam';

  @override
  String get sangatReportReasonOffTopic => 'Not about Sikhi';

  @override
  String get sangatReportReasonOther => 'Other';

  @override
  String get sangatReportSent => 'Thank you. We\'ll look into it.';

  @override
  String sangatUpdatedAt(String time) {
    return 'Updated $time';
  }

  @override
  String get sangatOffline => 'Can\'t reach the sangat right now';

  @override
  String get sangatGoalTitle => 'Set the goal';

  @override
  String get sangatCreateAction => 'Create';

  @override
  String get sangatGoalOnce =>
      'The goal can\'t be changed later; only its end date can.';

  @override
  String get sangatNameRequired => 'Please enter a group name';

  @override
  String get sangatTargetInvalid => 'Enter a number from 1 to 1,000,000';

  @override
  String get sangatChooseBani => 'Choose a bani';

  @override
  String get sangatNoGoalYet => 'No goal yet';

  @override
  String get sangatJoinTitle => 'Join a group';

  @override
  String get sangatCodeLabel => 'Invite code';

  @override
  String sangatLeaveConfirm(String group) {
    return 'Leave $group? What you contributed stays in its total.';
  }

  @override
  String sangatDeleteConfirm(String group) {
    return 'Delete $group? This removes it and everything in it.';
  }

  @override
  String sangatRemoveConfirm(String name) {
    return 'Remove $name from the group? What they contributed stays.';
  }

  @override
  String get sangatReportNote => 'A note (optional)';

  @override
  String get sangatReportSend => 'Send';

  @override
  String get sangatLeft => 'Left';

  @override
  String get sangatYou => 'You';

  @override
  String get sangatNoGroups => 'You are not in any group yet.';

  @override
  String get sangatJoinFromInvite => 'You have an invite to a group.';

  @override
  String get simranLegendLive => 'Live';

  @override
  String globeLiveCount(int count) {
    return '$count live today';
  }

  @override
  String globeStale(String time) {
    return 'Last updated $time';
  }

  @override
  String get globeOffline => 'Can\'t reach the sangat right now';

  @override
  String get globeProfileBanner =>
      'Create your profile to see yourself on the globe';

  @override
  String get appBarTitle => 'Hazri';

  @override
  String todayStreakDays(int count) {
    return '$count';
  }

  @override
  String get badgesTitle => 'Badges';

  @override
  String badgesSummary(int earned, int count) {
    return '$earned of 10 earned · Hazri on $count days';
  }

  @override
  String get badgesSeeAll => 'See all 10';

  @override
  String badgesMenuCount(int earned) {
    return '$earned of 10';
  }

  @override
  String badgeEarnedOn(String date) {
    return 'Earned $date';
  }

  @override
  String get badgeNotYet => 'Not yet';

  @override
  String badgeNumber(int n) {
    return 'Badge $n of 10';
  }

  @override
  String get badgeWhatItMarks => 'What it marks';

  @override
  String get badgeHowEarned => 'How it is earned';

  @override
  String get badgeEarnedNew => 'New badge';

  @override
  String get badgeEarnedYours => 'Your badges';

  @override
  String get badgeEarnedDone => 'Done';

  @override
  String get badgeEarnedSee => 'See all badges';

  @override
  String get badgeMarksJigyasu => 'The seeker: the first hazri';

  @override
  String get badgeMarksShardhalu => 'Coming back with shardha';

  @override
  String get badgeMarksAbhyasi => 'One who practises: the habit is forming';

  @override
  String get badgeMarksNitnemi => 'Keeps the Nitnem';

  @override
  String get badgeMarksSimrani => 'Settled in Simran';

  @override
  String get badgeMarksPaathi =>
      'Has read every bani through, Sukhmani Sahib included';

  @override
  String get badgeMarksSevadar =>
      'Sewa in the sangat: group goals carried to their end';

  @override
  String get badgeMarksGursikh => 'The whole of it held together over months';

  @override
  String get badgeMarksSatsangi => 'Brought others into the sangat';

  @override
  String get badgeMarksVichari => 'The long road: a year of days';

  @override
  String get badgeRuleJigyasu => 'Your first hazri';

  @override
  String get badgeRuleShardhalu => 'Hazri on 7 days';

  @override
  String get badgeRuleAbhyasi => 'Hazri on 40 days';

  @override
  String get badgeRuleNitnemi => 'The five morning banis on 40 days';

  @override
  String get badgeRuleSimrani => 'Simran of 5 minutes or more on 108 days';

  @override
  String get badgeRulePaathi => 'Every bani read through once';

  @override
  String get badgeRuleSevadar => '3 sangat goals reached with you';

  @override
  String get badgeRuleGursikh =>
      'Nitnemi, Simrani, Paathi and hazri on 180 days';

  @override
  String get badgeRuleSatsangi => '5 people joined groups you created';

  @override
  String get badgeRuleVichari => 'Hazri on 365 days';

  @override
  String get badgeHowJigyasu =>
      'Mark your hazri once: finish any bani, or sit in Simran for 5 minutes.';

  @override
  String get badgeHowShardhalu =>
      'Hazri on 7 days. The days need not be in a row.';

  @override
  String get badgeHowAbhyasi =>
      'Hazri on 40 days. The days need not be in a row.';

  @override
  String badgeHowNitnemi(String banis) {
    return '$banis, all five on the same day, on 40 days. The days need not be in a row.';
  }

  @override
  String get badgeHowSimrani =>
      'A sitting of Simran of 5 minutes or more on 108 days. The days need not be in a row.';

  @override
  String get badgeHowPaathi =>
      'Read or listen to every bani in the app through to the end at least once, Ardas and Sukhmani Sahib included.';

  @override
  String get badgeHowSevadar =>
      'Be part of 3 sangat goals that are reached, with at least one paath of your own in each. Needs a profile.';

  @override
  String get badgeHowGursikh =>
      'Earn Nitnemi, Simrani and Paathi, and hazri on 180 days. The days need not be in a row.';

  @override
  String get badgeHowSatsangi =>
      '5 people join groups you created, each counted once. Needs a profile.';

  @override
  String get badgeHowVichari =>
      'Hazri on 365 days. The days need not be in a row.';

  @override
  String get welcomeTitleLead =>
      'From Amrit Vela to bedtime, mark your hazri to';

  @override
  String get welcomeTitleWord => 'Waheguru.';

  @override
  String get welcomeAmritVelaTime => '4:00 AM';

  @override
  String get welcomeAmritVela => 'Amrit Vela';

  @override
  String welcomeAmritVelaSub(String bani) {
    return 'A gentle reminder, $bani is ready';
  }

  @override
  String get welcomeHazriTime => '5:10 AM';

  @override
  String welcomeHazriSub(String bani) {
    return 'With $bani';
  }

  @override
  String get welcomeGoalTime => '6:30 PM';

  @override
  String get welcomeGoal => 'Daily goal · 1 of 2 done';

  @override
  String welcomeGoalSub(String bani) {
    return '$bani, and 11 minutes of Simran';
  }

  @override
  String get welcomeSangatTime => '9:00 PM';

  @override
  String get welcomeSangat => 'Your sangat group';

  @override
  String welcomeSangatSub(String bani) {
    return '68 of 101 $bani, together';
  }

  @override
  String get welcomeStreakTime => 'Night';

  @override
  String get welcomeStreak => '12 days in a row';

  @override
  String get welcomeStreakSub => 'Kept in your diary';

  @override
  String get welcomeBegin => 'Begin';

  @override
  String get setupLanguageNote => 'You can change it any time in Settings.';

  @override
  String get elderModeSetup => 'Larger text and simpler screens';

  @override
  String get sangatSimranMinutesUnit => 'minutes of Naam Simran';

  @override
  String sangatProgressMinutes(int total, int target, int pct) {
    return '$total of $target min · $pct%';
  }

  @override
  String sangatTodayMinutes(int count) {
    return '$count min today';
  }

  @override
  String get sangatGoalTargetMinutes => 'Target, in minutes of Naam Simran';

  @override
  String get readerStartAgainNote =>
      'Start again takes you to the first line and clears where you left off.';

  @override
  String get goalPlayNow => 'Play now';

  @override
  String get notifExactAllow => 'Allow on-time reminders';

  @override
  String playerQueuePosition(String slot, int index, int count) {
    return '$slot · $index of $count';
  }

  @override
  String get profileYourTitle => 'Your profile';

  @override
  String profileStatHazriDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days of Hazri',
      one: 'day of Hazri',
    );
    return '$_temp0';
  }

  @override
  String get profileStatInARow => 'in a row';

  @override
  String profileStatBadges(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'badges earned',
      one: 'badge earned',
    );
    return '$_temp0';
  }

  @override
  String get profilePhoneNotProvided => 'Phone not provided';

  @override
  String get profilePrivacyLine =>
      'Your email is never shown to anyone in the app. Your city is one dot on the Simran globe, and nothing finer.';

  @override
  String profileEditTodayIn(String city) {
    return 'Today in $city';
  }

  @override
  String profileEditChangedFrom(String city) {
    return 'Changed from $city';
  }

  @override
  String get profileEditSunrise => 'Sunrise';

  @override
  String get profileEditSunset => 'Sunset';

  @override
  String get profileEditCityHelp =>
      'Your sunrise times on Today and your dot on the Simran globe follow it.';

  @override
  String get profileEditNameHelp =>
      '2 to 50 letters. Spaces, full stops, apostrophes and hyphens are fine.';

  @override
  String get profileEditEmailHelp =>
      'A new email takes over only once you confirm it from the link we send.';
}
