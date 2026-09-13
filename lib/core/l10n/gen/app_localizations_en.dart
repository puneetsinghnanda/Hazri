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
  String get introTitle1 => 'Your Nitnem, always with you';

  @override
  String get introBody1 =>
      'All seven Nitnem banis, a 5-minute daily Simran, and Gurpurab reminders. Nitnem reminders follow sunrise and sunset where you are.';

  @override
  String get introTitle2 => 'Read along as the paath is recited';

  @override
  String get introBody2 =>
      'The line being recited lights up and the page scrolls with the paathi\'s voice. Minimise the app or lock your phone — the paath carries on.';

  @override
  String get introTitle3 => 'In your language, at your pace';

  @override
  String get introBody3 =>
      'Read Gurbani in Gurmukhi, Hindi or Roman, with simple meanings in Punjabi, Hindi or English. Elder mode makes everything larger.';

  @override
  String get introGetStarted => 'Get started';

  @override
  String get introPhoneLocked => 'Phone locked';

  @override
  String get introPaathKeepsPlaying => 'Paath keeps playing';

  @override
  String get introMeaningsIn => 'Meanings: ਪੰਜਾਬੀ · हिन्दी · English';

  @override
  String introBanisCount(int count) {
    return '$count banis';
  }

  @override
  String get introAtSunset => 'at sunset';

  @override
  String get introBeforeSleep => 'before sleep';

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
  String get todayHukamnama => 'Today\'s Hukamnama';

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
  String get hukamnamaOfflineEmpty =>
      'Hukamnama will appear when you\'re online';

  @override
  String get hukamnamaNotConfigured =>
      'No Hukamnama source is set up in this build';

  @override
  String get hukamnamaNotConfiguredBody =>
      'Hazri does not fetch the daily Hukamnama yet. When a permitted source is configured, today\'s Hukamnama appears here and can be shared as a card.';

  @override
  String hukamnamaSavedOn(String date) {
    return 'Saved $date';
  }

  @override
  String get hukamnamaTitle => 'Hukamnama';

  @override
  String get hukamnamaMeaningIn => 'Meaning in';

  @override
  String get hukamnamaSource => 'Sri Darbar Sahib, Amritsar';

  @override
  String get hukamnamaRahao => 'Rahao';

  @override
  String get hukamnamaSavedOffline => 'Saved for offline reading';

  @override
  String get hukamnamaReadDailyOn => 'Read daily on';

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
  String get diaryStatRehras => 'Rehras';

  @override
  String get diaryStatSohila => 'Sohila';

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
  String get simranCount => 'Count';

  @override
  String get simranCountHint =>
      'Tap anywhere on the screen to count each Waheguru — optional';

  @override
  String get simranSound => 'Sound';

  @override
  String get simranSoundSilence => 'Silence';

  @override
  String get simranSoundDrone => 'Soft drone';

  @override
  String get simranSoundBell => 'Bell at the end';

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
  String get goalsTitle => 'My paath goals';

  @override
  String goalsSubtitle(int done, int total) {
    return '$done of $total done today';
  }

  @override
  String get goalsAdd => 'Add a paath goal';

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
  String get goalSave => 'Save goal';

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
      'Mukta, Baloo Paaji 2, Noto Serif Gurmukhi and Noto Serif Devanagari — SIL Open Font License.';

  @override
  String get aboutContact => 'Contact';

  @override
  String get aboutNoAudioYet =>
      'The recitation shipped with the app is played from the phone and never streamed.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyBody =>
      'Hazri has no account and collects no personal data. Your diary, goals and settings stay on this phone and in your own Google backup. If you pick a city or use your location, it stays on the phone and is used only to work out sunrise and sunset.';

  @override
  String get privacyNoAnalytics =>
      'This build sends nothing anywhere: no analytics, no crash reporting, no network requests at all.';

  @override
  String get notifChannelNitnem => 'Nitnem reminders';

  @override
  String get notifChannelSimran => 'Daily Simran';

  @override
  String get notifChannelGurpurab => 'Gurpurab';

  @override
  String get notifChannelGoals => 'Paath goals';

  @override
  String get notifAmritVelaTitle => 'Amrit Vela';

  @override
  String notifAmritVelaBody(String bani, String time) {
    return '$bani is ready — sunrise today is at $time.';
  }

  @override
  String get notifSimranTitle => 'Daily Simran';

  @override
  String get notifSimranBody => 'Five quiet minutes of Waheguru Simran.';

  @override
  String get notifGurpurabTitle => 'Tomorrow is a Gurpurab';

  @override
  String get notifGurpurabToday => 'Today is a Gurpurab';

  @override
  String notifRehrasBody(int minutes) {
    return 'Your evening bani, at the time you chose — $minutes minutes.';
  }

  @override
  String notifBaniBody(String bani, int minutes) {
    return '$bani — $minutes minutes.';
  }

  @override
  String notifGoalBody(int done, int total) {
    return 'Your paath goal for today — $done of $total done.';
  }

  @override
  String get notifActionStartNitnem => 'Start Nitnem';

  @override
  String get notifActionStart => 'Start';

  @override
  String get notifActionLater => 'Later';

  @override
  String get notifActionBegin => 'Begin';

  @override
  String get notifActionSkipToday => 'Skip today';

  @override
  String get notifActionOpenCalendar => 'Open calendar';

  @override
  String get shareCardTitle => 'Today\'s Hukamnama';

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
      'Japji Sahib plays offline, with the text following along.';

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
  String get errorGeneric => 'Something went wrong.';

  @override
  String get errorContentDb =>
      'The bundled content could not be opened. Reinstalling Hazri should fix it.';
}
