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
      'Hazri has no password and no sign-in screen. Reading a bani, hearing it, seeing the calendar and writing your diary all happen on this phone and work with the radio off. Your diary, goals and settings stay on this phone and in your own Google backup. If you pick a city or use your location, it stays on the phone and is used only to work out sunrise and sunset.';

  @override
  String get privacyNoAnalytics =>
      'Nothing leaves this phone unless you join the sangat. Analytics are switched off in this build and no crash reports are sent.';

  @override
  String get privacySangat =>
      'If you join the sangat, what goes to the server is your name, city, email and the counts behind the groups and goals you joined. The words in your diary never go, and your email is never shown to anybody else.';

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
  String get accountTitle => 'Your account';

  @override
  String get accountEmail => 'Email';

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
  String get verifySent => 'Sent. It can take a minute to arrive.';

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
  String get restoreDone => 'Your account is back';

  @override
  String get restoreDiaryNote =>
      'Your diary comes back only if sync was on. With sync off, your groups and goals are kept and the diary stays on the phone that wrote it.';

  @override
  String get restoreOpenToday => 'Open Today';

  @override
  String get linkProblemTitle => 'That link did not work';

  @override
  String get linkUsedTitle => 'Already used';

  @override
  String get linkUsedBody =>
      'This link has signed in a phone already. Every link works once and then stops, which is what keeps a forwarded email from being a way in.';

  @override
  String get linkExpiredTitle => 'Too old';

  @override
  String get linkExpiredBody =>
      'Links last an hour. This one has lapsed on its own — nobody used it.';

  @override
  String get linkWrongTitle => 'Not a link from us';

  @override
  String get linkWrongBody =>
      'That does not look like the link we sent. Copy the whole of it, including everything after the question mark.';

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
  String get privacySharedWithSangat => 'Shared with the sangat';

  @override
  String get privacyShareName => 'Your name';

  @override
  String get privacyShareCity =>
      'The city you chose — shown as one dot on the globe';

  @override
  String get privacyShareGroups => 'Which groups you are in';

  @override
  String get privacyShareCounts =>
      'How much you have completed towards a shared goal';

  @override
  String get privacyAccountOnly => 'Held for your account alone';

  @override
  String get privacyAccountEmail =>
      'Your email — the only thing it does is bring your account back';

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
  String get privacyNotJoined =>
      'You have not joined the sangat, so nothing here has left this phone.';

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
  String get notifOwnPractice => 'Your own practice';

  @override
  String get notifYourGroups => 'Your groups';

  @override
  String get notifGlobal => 'Global Simran';

  @override
  String get notifGoalClose => 'A goal is close';

  @override
  String get notifGoalCloseSub => 'When the group passes 90%';

  @override
  String get notifSomeoneJoined => 'Someone joined';

  @override
  String get notifSomeoneJoinedSub => 'New members in your groups';

  @override
  String get notifGroupSummary => 'Daily group summary';

  @override
  String get notifGroupSummarySub => 'One message, at 9 PM';

  @override
  String get notifLargeGatherings => 'Large gatherings';

  @override
  String get notifLargeGatheringsSub => 'When thousands are sitting together';

  @override
  String get notifGroupsNotYet =>
      'These need a message sent from a server, and Hazri has none yet. Your own reminders above are set by this phone and work with the radio off.';

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
}
