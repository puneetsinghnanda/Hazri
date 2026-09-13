import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_pa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
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
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

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
    Locale('hi'),
    Locale('pa'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Hazri'**
  String get appName;

  /// No description provided for @appNameNative.
  ///
  /// In en, this message translates to:
  /// **'ਹਾਜ਼ਰੀ'**
  String get appNameNative;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Your daily Nitnem — always with you'**
  String get tagline;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get actionChange;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get actionAllow;

  /// No description provided for @actionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get actionNotNow;

  /// No description provided for @actionDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get actionDownload;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get actionPause;

  /// No description provided for @actionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get actionResume;

  /// No description provided for @actionShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get actionShowMore;

  /// No description provided for @actionRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get actionRead;

  /// No description provided for @actionListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get actionListen;

  /// No description provided for @actionShareCard.
  ///
  /// In en, this message translates to:
  /// **'Share card'**
  String get actionShareCard;

  /// No description provided for @actionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get actionStart;

  /// No description provided for @actionOpenReader.
  ///
  /// In en, this message translates to:
  /// **'Open reader'**
  String get actionOpenReader;

  /// No description provided for @actionGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get actionGotIt;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutes(int count);

  /// No description provided for @minutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} min left'**
  String minutesLeft(int count);

  /// No description provided for @nOfM.
  ///
  /// In en, this message translates to:
  /// **'{n} of {m}'**
  String nOfM(int n, int m);

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navNitnem.
  ///
  /// In en, this message translates to:
  /// **'Nitnem'**
  String get navNitnem;

  /// No description provided for @navSimran.
  ///
  /// In en, this message translates to:
  /// **'Simran'**
  String get navSimran;

  /// No description provided for @navDiary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get navDiary;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @slotAmritVela.
  ///
  /// In en, this message translates to:
  /// **'Amrit Vela'**
  String get slotAmritVela;

  /// No description provided for @slotEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get slotEvening;

  /// No description provided for @slotBedtime.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get slotBedtime;

  /// No description provided for @slotMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get slotMorning;

  /// No description provided for @slotMoreBanis.
  ///
  /// In en, this message translates to:
  /// **'More banis'**
  String get slotMoreBanis;

  /// No description provided for @chipWorksOffline.
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get chipWorksOffline;

  /// No description provided for @chipNoLogin.
  ///
  /// In en, this message translates to:
  /// **'No login'**
  String get chipNoLogin;

  /// No description provided for @chipNoAdsOnGurbani.
  ///
  /// In en, this message translates to:
  /// **'No ads on Gurbani'**
  String get chipNoAdsOnGurbani;

  /// No description provided for @introTitle1.
  ///
  /// In en, this message translates to:
  /// **'Your Nitnem, always with you'**
  String get introTitle1;

  /// No description provided for @introBody1.
  ///
  /// In en, this message translates to:
  /// **'All seven Nitnem banis, a 5-minute daily Simran, and Gurpurab reminders. Nitnem reminders follow sunrise and sunset where you are.'**
  String get introBody1;

  /// No description provided for @introTitle2.
  ///
  /// In en, this message translates to:
  /// **'Read along as the paath is recited'**
  String get introTitle2;

  /// No description provided for @introBody2.
  ///
  /// In en, this message translates to:
  /// **'The line being recited lights up and the page scrolls with the paathi\'s voice. Minimise the app or lock your phone — the paath carries on.'**
  String get introBody2;

  /// No description provided for @introTitle3.
  ///
  /// In en, this message translates to:
  /// **'In your language, at your pace'**
  String get introTitle3;

  /// No description provided for @introBody3.
  ///
  /// In en, this message translates to:
  /// **'Read Gurbani in Gurmukhi, Hindi or Roman, with simple meanings in Punjabi, Hindi or English. Elder mode makes everything larger.'**
  String get introBody3;

  /// No description provided for @introGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get introGetStarted;

  /// No description provided for @introPhoneLocked.
  ///
  /// In en, this message translates to:
  /// **'Phone locked'**
  String get introPhoneLocked;

  /// No description provided for @introPaathKeepsPlaying.
  ///
  /// In en, this message translates to:
  /// **'Paath keeps playing'**
  String get introPaathKeepsPlaying;

  /// No description provided for @introMeaningsIn.
  ///
  /// In en, this message translates to:
  /// **'Meanings: ਪੰਜਾਬੀ · हिन्दी · English'**
  String get introMeaningsIn;

  /// No description provided for @introBanisCount.
  ///
  /// In en, this message translates to:
  /// **'{count} banis'**
  String introBanisCount(int count);

  /// No description provided for @introAtSunset.
  ///
  /// In en, this message translates to:
  /// **'at sunset'**
  String get introAtSunset;

  /// No description provided for @introBeforeSleep.
  ///
  /// In en, this message translates to:
  /// **'before sleep'**
  String get introBeforeSleep;

  /// No description provided for @setupLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get setupLanguageTitle;

  /// No description provided for @setupLanguagePunjabi.
  ///
  /// In en, this message translates to:
  /// **'ਪੰਜਾਬੀ'**
  String get setupLanguagePunjabi;

  /// No description provided for @setupLanguagePunjabiSub.
  ///
  /// In en, this message translates to:
  /// **'Punjabi'**
  String get setupLanguagePunjabiSub;

  /// No description provided for @setupLanguageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get setupLanguageHindi;

  /// No description provided for @setupLanguageHindiSub.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get setupLanguageHindiSub;

  /// No description provided for @setupLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get setupLanguageEnglish;

  /// No description provided for @setupLanguageEnglishSub.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get setupLanguageEnglishSub;

  /// No description provided for @setupReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you like to read Gurbani?'**
  String get setupReadingTitle;

  /// No description provided for @scriptGurmukhi.
  ///
  /// In en, this message translates to:
  /// **'Gurmukhi'**
  String get scriptGurmukhi;

  /// No description provided for @scriptDevanagari.
  ///
  /// In en, this message translates to:
  /// **'Devanagari'**
  String get scriptDevanagari;

  /// No description provided for @scriptRoman.
  ///
  /// In en, this message translates to:
  /// **'Roman'**
  String get scriptRoman;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @textSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// No description provided for @elderMode.
  ///
  /// In en, this message translates to:
  /// **'Elder mode'**
  String get elderMode;

  /// No description provided for @elderModeSub.
  ///
  /// In en, this message translates to:
  /// **'Extra-large text and big buttons'**
  String get elderModeSub;

  /// No description provided for @versionsNote.
  ///
  /// In en, this message translates to:
  /// **'Bani versions follow the SGPC Rehat Maryada'**
  String get versionsNote;

  /// No description provided for @setupRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'When should we remind you?'**
  String get setupRemindersTitle;

  /// No description provided for @setupRemindersBody.
  ///
  /// In en, this message translates to:
  /// **'Auto follows sunrise and sunset where you are. Tap any time to pick your own, or to switch a reminder off.'**
  String get setupRemindersBody;

  /// No description provided for @reminderAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get reminderAuto;

  /// No description provided for @reminderMyTime.
  ///
  /// In en, this message translates to:
  /// **'My time'**
  String get reminderMyTime;

  /// No description provided for @reminderOff.
  ///
  /// In en, this message translates to:
  /// **'Reminder off'**
  String get reminderOff;

  /// No description provided for @reminderAutoBeforeSunrise.
  ///
  /// In en, this message translates to:
  /// **'Auto · before sunrise'**
  String get reminderAutoBeforeSunrise;

  /// No description provided for @reminderAutoAtSunset.
  ///
  /// In en, this message translates to:
  /// **'Auto · at sunset'**
  String get reminderAutoAtSunset;

  /// No description provided for @reminderAutoFollowsSunrise.
  ///
  /// In en, this message translates to:
  /// **'Auto · follows sunrise'**
  String get reminderAutoFollowsSunrise;

  /// No description provided for @reminderEveningBefore.
  ///
  /// In en, this message translates to:
  /// **'Evening before'**
  String get reminderEveningBefore;

  /// No description provided for @reminderGurpurabDays.
  ///
  /// In en, this message translates to:
  /// **'Gurpurab days'**
  String get reminderGurpurabDays;

  /// No description provided for @reminderDailySimran.
  ///
  /// In en, this message translates to:
  /// **'Daily Simran'**
  String get reminderDailySimran;

  /// No description provided for @allowOnTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow on-time reminders'**
  String get allowOnTimeTitle;

  /// No description provided for @allowOnTimeBody.
  ///
  /// In en, this message translates to:
  /// **'Android asks once, so Amrit Vela reminders arrive to the minute.'**
  String get allowOnTimeBody;

  /// No description provided for @allowOnTimeGranted.
  ///
  /// In en, this message translates to:
  /// **'On-time reminders allowed'**
  String get allowOnTimeGranted;

  /// No description provided for @allowOnTimeDenied.
  ///
  /// In en, this message translates to:
  /// **'Not now — reminders may arrive a few minutes late'**
  String get allowOnTimeDenied;

  /// No description provided for @notificationRationale.
  ///
  /// In en, this message translates to:
  /// **'Reminders need permission to show notifications. Nothing else is ever sent.'**
  String get notificationRationale;

  /// No description provided for @usingCityForSun.
  ///
  /// In en, this message translates to:
  /// **'Using {city} for sunrise and sunset'**
  String usingCityForSun(String city);

  /// No description provided for @beginMyNitnem.
  ///
  /// In en, this message translates to:
  /// **'Begin my Nitnem'**
  String get beginMyNitnem;

  /// No description provided for @audioNotInBuild.
  ///
  /// In en, this message translates to:
  /// **'Audio is not part of this build yet'**
  String get audioNotInBuild;

  /// No description provided for @audioNotInBuildSub.
  ///
  /// In en, this message translates to:
  /// **'Text, meanings and reminders all work offline. Recorded paath arrives in a later build.'**
  String get audioNotInBuildSub;

  /// No description provided for @reminderSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'{bani} reminder'**
  String reminderSheetTitle(String bani);

  /// No description provided for @reminderSheetSameTime.
  ///
  /// In en, this message translates to:
  /// **'Same time every day'**
  String get reminderSheetSameTime;

  /// No description provided for @reminderSheetAtSunsetToday.
  ///
  /// In en, this message translates to:
  /// **'At sunset · {time} today'**
  String reminderSheetAtSunsetToday(String time);

  /// No description provided for @reminderSheetBeforeSunriseToday.
  ///
  /// In en, this message translates to:
  /// **'Before sunrise · {time} today'**
  String reminderSheetBeforeSunriseToday(String time);

  /// No description provided for @reminderSheetRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get reminderSheetRepeat;

  /// No description provided for @reminderSheetShowInMyDay.
  ///
  /// In en, this message translates to:
  /// **'Show in my day'**
  String get reminderSheetShowInMyDay;

  /// No description provided for @reminderSheetTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off this reminder'**
  String get reminderSheetTurnOff;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get daySun;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Sat Sri Akal ji'**
  String get greeting;

  /// No description provided for @todayHukamnama.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Hukamnama'**
  String get todayHukamnama;

  /// No description provided for @ctaStartNitnem.
  ///
  /// In en, this message translates to:
  /// **'Start my Nitnem'**
  String get ctaStartNitnem;

  /// No description provided for @ctaContinueBani.
  ///
  /// In en, this message translates to:
  /// **'Continue {bani}'**
  String ctaContinueBani(String bani);

  /// No description provided for @ctaStartBani.
  ///
  /// In en, this message translates to:
  /// **'Start {bani}'**
  String ctaStartBani(String bani);

  /// No description provided for @ctaAllDone.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Nitnem complete'**
  String get ctaAllDone;

  /// No description provided for @arcBaniInProgress.
  ///
  /// In en, this message translates to:
  /// **'{bani} in progress'**
  String arcBaniInProgress(String bani);

  /// No description provided for @arcMorningComplete.
  ///
  /// In en, this message translates to:
  /// **'Morning Nitnem complete'**
  String get arcMorningComplete;

  /// No description provided for @arcBaniAt.
  ///
  /// In en, this message translates to:
  /// **'{bani} at {time}'**
  String arcBaniAt(String bani, String time);

  /// No description provided for @arcNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing started yet today'**
  String get arcNothingYet;

  /// No description provided for @simranTileProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} min'**
  String simranTileProgress(int done, int total);

  /// No description provided for @simranTileDone.
  ///
  /// In en, this message translates to:
  /// **'Done today ✓'**
  String get simranTileDone;

  /// No description provided for @gurpurabTileToday.
  ///
  /// In en, this message translates to:
  /// **'Today · Gurpurab'**
  String get gurpurabTileToday;

  /// No description provided for @gurpurabTileTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow · Gurpurab'**
  String get gurpurabTileTomorrow;

  /// No description provided for @gurpurabTileUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Gurpurab'**
  String get gurpurabTileUpcoming;

  /// No description provided for @helpSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'How Hazri works'**
  String get helpSheetTitle;

  /// No description provided for @helpTip1.
  ///
  /// In en, this message translates to:
  /// **'Tap Start my Nitnem on Today and the reader opens where you left off.'**
  String get helpTip1;

  /// No description provided for @helpTip2.
  ///
  /// In en, this message translates to:
  /// **'In the reader, ਅ / अ / A switches script and Aa opens text size, meanings and pause marks.'**
  String get helpTip2;

  /// No description provided for @helpTip3.
  ///
  /// In en, this message translates to:
  /// **'Reminders follow sunrise and sunset for your city, or a time you pick yourself.'**
  String get helpTip3;

  /// No description provided for @helpAboutLink.
  ///
  /// In en, this message translates to:
  /// **'About & credits'**
  String get helpAboutLink;

  /// No description provided for @hukamnamaOfflineEmpty.
  ///
  /// In en, this message translates to:
  /// **'Hukamnama will appear when you\'re online'**
  String get hukamnamaOfflineEmpty;

  /// No description provided for @hukamnamaNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'No Hukamnama source is set up in this build'**
  String get hukamnamaNotConfigured;

  /// No description provided for @hukamnamaNotConfiguredBody.
  ///
  /// In en, this message translates to:
  /// **'Hazri does not fetch the daily Hukamnama yet. When a permitted source is configured, today\'s Hukamnama appears here and can be shared as a card.'**
  String get hukamnamaNotConfiguredBody;

  /// No description provided for @hukamnamaSavedOn.
  ///
  /// In en, this message translates to:
  /// **'Saved {date}'**
  String hukamnamaSavedOn(String date);

  /// No description provided for @hukamnamaTitle.
  ///
  /// In en, this message translates to:
  /// **'Hukamnama'**
  String get hukamnamaTitle;

  /// No description provided for @hukamnamaMeaningIn.
  ///
  /// In en, this message translates to:
  /// **'Meaning in'**
  String get hukamnamaMeaningIn;

  /// No description provided for @hukamnamaSource.
  ///
  /// In en, this message translates to:
  /// **'Sri Darbar Sahib, Amritsar'**
  String get hukamnamaSource;

  /// No description provided for @hukamnamaRahao.
  ///
  /// In en, this message translates to:
  /// **'Rahao'**
  String get hukamnamaRahao;

  /// No description provided for @hukamnamaSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved for offline reading'**
  String get hukamnamaSavedOffline;

  /// No description provided for @hukamnamaReadDailyOn.
  ///
  /// In en, this message translates to:
  /// **'Read daily on'**
  String get hukamnamaReadDailyOn;

  /// No description provided for @nitnemTitle.
  ///
  /// In en, this message translates to:
  /// **'Nitnem'**
  String get nitnemTitle;

  /// No description provided for @nitnemVersionLine.
  ///
  /// In en, this message translates to:
  /// **'SGPC version'**
  String get nitnemVersionLine;

  /// No description provided for @nitnemAudioSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Audio saved offline'**
  String get nitnemAudioSavedOffline;

  /// No description provided for @nitnemAudioNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Audio not in this build'**
  String get nitnemAudioNotAvailable;

  /// No description provided for @nitnemPlayAll.
  ///
  /// In en, this message translates to:
  /// **'Play all'**
  String get nitnemPlayAll;

  /// No description provided for @nitnemSectionSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} banis · about {minutes} min'**
  String nitnemSectionSummary(int count, int minutes);

  /// No description provided for @nitnemYourTime.
  ///
  /// In en, this message translates to:
  /// **'Your time · {time}'**
  String nitnemYourTime(String time);

  /// No description provided for @nitnemAtSunset.
  ///
  /// In en, this message translates to:
  /// **'At sunset · {time}'**
  String nitnemAtSunset(String time);

  /// No description provided for @nitnemResumeAt.
  ///
  /// In en, this message translates to:
  /// **'{position} in'**
  String nitnemResumeAt(String position);

  /// No description provided for @nitnemLineOf.
  ///
  /// In en, this message translates to:
  /// **'line {line} of {total}'**
  String nitnemLineOf(int line, int total);

  /// No description provided for @goalsSummaryCard.
  ///
  /// In en, this message translates to:
  /// **'My paath goals'**
  String get goalsSummaryCard;

  /// No description provided for @goalsSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done today'**
  String goalsSummaryLine(int done, int total);

  /// No description provided for @goalsSetOne.
  ///
  /// In en, this message translates to:
  /// **'Set a paath goal'**
  String get goalsSetOne;

  /// No description provided for @baniNotInBuild.
  ///
  /// In en, this message translates to:
  /// **'This bani is not in this build yet'**
  String get baniNotInBuild;

  /// No description provided for @baniNotInBuildBody.
  ///
  /// In en, this message translates to:
  /// **'Hazri ships with the full text of Japji Sahib. The remaining banis arrive once their text has been reviewed.'**
  String get baniNotInBuildBody;

  /// No description provided for @readerTextSettings.
  ///
  /// In en, this message translates to:
  /// **'Text settings'**
  String get readerTextSettings;

  /// No description provided for @readerShowMeanings.
  ///
  /// In en, this message translates to:
  /// **'Show meanings'**
  String get readerShowMeanings;

  /// No description provided for @readerMeaningLanguage.
  ///
  /// In en, this message translates to:
  /// **'Meaning language'**
  String get readerMeaningLanguage;

  /// No description provided for @readerRomanUnder.
  ///
  /// In en, this message translates to:
  /// **'Roman under Gurmukhi'**
  String get readerRomanUnder;

  /// No description provided for @readerPauseMarks.
  ///
  /// In en, this message translates to:
  /// **'Pause marks (vishraam)'**
  String get readerPauseMarks;

  /// No description provided for @readerPauseMarksSub.
  ///
  /// In en, this message translates to:
  /// **'Short and long pauses in colour'**
  String get readerPauseMarksSub;

  /// No description provided for @readerLarivaar.
  ///
  /// In en, this message translates to:
  /// **'Larivaar'**
  String get readerLarivaar;

  /// No description provided for @readerLarivaarSub.
  ///
  /// In en, this message translates to:
  /// **'Words joined, as in the Saroop'**
  String get readerLarivaarSub;

  /// No description provided for @readerKeepScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on while reading'**
  String get readerKeepScreenOn;

  /// No description provided for @readerFollowAudio.
  ///
  /// In en, this message translates to:
  /// **'Follow audio'**
  String get readerFollowAudio;

  /// No description provided for @readerFollowAudioSub.
  ///
  /// In en, this message translates to:
  /// **'Highlight the line and scroll with the paath'**
  String get readerFollowAudioSub;

  /// No description provided for @readerShortPause.
  ///
  /// In en, this message translates to:
  /// **'Short pause'**
  String get readerShortPause;

  /// No description provided for @readerLongPause.
  ///
  /// In en, this message translates to:
  /// **'Long pause'**
  String get readerLongPause;

  /// No description provided for @readerMeaningLabel.
  ///
  /// In en, this message translates to:
  /// **'Meaning: {language}'**
  String readerMeaningLabel(String language);

  /// No description provided for @readerCommentaryExpand.
  ///
  /// In en, this message translates to:
  /// **'Commentary ({source})'**
  String readerCommentaryExpand(String source);

  /// No description provided for @readerCommentaryNote.
  ///
  /// In en, this message translates to:
  /// **'Faridkot Wala Teeka — Braj/Sadhukkari Hindi commentary, converted to Devanagari. It explains the line rather than translating it.'**
  String get readerCommentaryNote;

  /// No description provided for @readerCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'{bani} complete'**
  String readerCompleteTitle(String bani);

  /// No description provided for @readerCompleteNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {bani}'**
  String readerCompleteNext(String bani);

  /// No description provided for @readerCompleteBackToNitnem.
  ///
  /// In en, this message translates to:
  /// **'Back to Nitnem'**
  String get readerCompleteBackToNitnem;

  /// No description provided for @readerBackToPaath.
  ///
  /// In en, this message translates to:
  /// **'Back to paath · line {line}'**
  String readerBackToPaath(int line);

  /// No description provided for @readerAutoScrollPaused.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll paused'**
  String get readerAutoScrollPaused;

  /// No description provided for @readerFollowingAudio.
  ///
  /// In en, this message translates to:
  /// **'Following audio'**
  String get readerFollowingAudio;

  /// No description provided for @readerSourceCredit.
  ///
  /// In en, this message translates to:
  /// **'Text: {text} · Meanings: {meanings}'**
  String readerSourceCredit(String text, String meanings);

  /// No description provided for @langPunjabi.
  ///
  /// In en, this message translates to:
  /// **'Punjabi'**
  String get langPunjabi;

  /// No description provided for @langHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get langHindi;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @playerNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get playerNowPlaying;

  /// No description provided for @playerMorningNitnem.
  ///
  /// In en, this message translates to:
  /// **'Morning Nitnem'**
  String get playerMorningNitnem;

  /// No description provided for @playerUpNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get playerUpNext;

  /// No description provided for @playerSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get playerSpeed;

  /// No description provided for @playerSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get playerSleepTimer;

  /// No description provided for @playerVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get playerVoice;

  /// No description provided for @playerPaathi.
  ///
  /// In en, this message translates to:
  /// **'Paathi: {name}'**
  String playerPaathi(String name);

  /// No description provided for @diaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Nitnem Diary'**
  String get diaryTitle;

  /// No description provided for @diaryStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days in a row'**
  String diaryStreakDays(int count);

  /// No description provided for @diaryStreakOne.
  ///
  /// In en, this message translates to:
  /// **'1 day in a row'**
  String get diaryStreakOne;

  /// No description provided for @diaryStreakNone.
  ///
  /// In en, this message translates to:
  /// **'Start whenever you like'**
  String get diaryStreakNone;

  /// No description provided for @diaryGentleStreak.
  ///
  /// In en, this message translates to:
  /// **'A gentle streak'**
  String get diaryGentleStreak;

  /// No description provided for @diaryGrace.
  ///
  /// In en, this message translates to:
  /// **'Missed a day? Grace days keep it going. {count} left this month.'**
  String diaryGrace(int count);

  /// No description provided for @diaryGraceLabel.
  ///
  /// In en, this message translates to:
  /// **'GRACE'**
  String get diaryGraceLabel;

  /// No description provided for @diaryFooter.
  ///
  /// In en, this message translates to:
  /// **'Kept on this phone. Backed up to your Google account.'**
  String get diaryFooter;

  /// No description provided for @diaryTickTitle.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String diaryTickTitle(String date);

  /// No description provided for @diaryTickHint.
  ///
  /// In en, this message translates to:
  /// **'Tick anything you completed on this day.'**
  String get diaryTickHint;

  /// No description provided for @diaryTickTooOld.
  ///
  /// In en, this message translates to:
  /// **'Only today and the last 7 days can be changed.'**
  String get diaryTickTooOld;

  /// No description provided for @diaryStatJapji.
  ///
  /// In en, this message translates to:
  /// **'Japji'**
  String get diaryStatJapji;

  /// No description provided for @diaryStatRehras.
  ///
  /// In en, this message translates to:
  /// **'Rehras'**
  String get diaryStatRehras;

  /// No description provided for @diaryStatSohila.
  ///
  /// In en, this message translates to:
  /// **'Sohila'**
  String get diaryStatSohila;

  /// No description provided for @diaryStatSimran.
  ///
  /// In en, this message translates to:
  /// **'Simran'**
  String get diaryStatSimran;

  /// No description provided for @simranTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Simran'**
  String get simranTitle;

  /// No description provided for @simranSubtitle.
  ///
  /// In en, this message translates to:
  /// **'5 quiet minutes of Naam Simran'**
  String get simranSubtitle;

  /// No description provided for @simranWaheguru.
  ///
  /// In en, this message translates to:
  /// **'ਵਾਹਿਗੁਰੂ'**
  String get simranWaheguru;

  /// No description provided for @simranLeftOf.
  ///
  /// In en, this message translates to:
  /// **'left of {total}'**
  String simranLeftOf(String total);

  /// No description provided for @simranEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get simranEnd;

  /// No description provided for @simranBegin.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get simranBegin;

  /// No description provided for @simranCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get simranCount;

  /// No description provided for @simranCountHint.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere on the screen to count each Waheguru — optional'**
  String get simranCountHint;

  /// No description provided for @simranSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get simranSound;

  /// No description provided for @simranSoundSilence.
  ///
  /// In en, this message translates to:
  /// **'Silence'**
  String get simranSoundSilence;

  /// No description provided for @simranSoundDrone.
  ///
  /// In en, this message translates to:
  /// **'Soft drone'**
  String get simranSoundDrone;

  /// No description provided for @simranSoundBell.
  ///
  /// In en, this message translates to:
  /// **'Bell at the end'**
  String get simranSoundBell;

  /// No description provided for @simranRecent.
  ///
  /// In en, this message translates to:
  /// **'Done {done} of the last {total} days'**
  String simranRecent(int done, int total);

  /// No description provided for @simranLoggedInDiary.
  ///
  /// In en, this message translates to:
  /// **'Logged in Diary'**
  String get simranLoggedInDiary;

  /// No description provided for @simranCompleteToast.
  ///
  /// In en, this message translates to:
  /// **'Simran complete — logged in your Diary'**
  String get simranCompleteToast;

  /// No description provided for @gurpurabTitle.
  ///
  /// In en, this message translates to:
  /// **'Gurpurab calendar'**
  String get gurpurabTitle;

  /// No description provided for @gurpurabTodayNanakshahi.
  ///
  /// In en, this message translates to:
  /// **'TODAY · NANAKSHAHI'**
  String get gurpurabTodayNanakshahi;

  /// No description provided for @gurpurabRemindersLine.
  ///
  /// In en, this message translates to:
  /// **'Reminders the evening before and on the morning of each day'**
  String get gurpurabRemindersLine;

  /// No description provided for @gurpurabThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get gurpurabThisWeek;

  /// No description provided for @gurpurabComingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get gurpurabComingUp;

  /// No description provided for @gurpurabFooter.
  ///
  /// In en, this message translates to:
  /// **'Dates follow the SGPC calendar. They ship with the app and update once a year.'**
  String get gurpurabFooter;

  /// No description provided for @gurpurabNoData.
  ///
  /// In en, this message translates to:
  /// **'Calendar data for this date is not in this build'**
  String get gurpurabNoData;

  /// No description provided for @gurpurabNoDataBody.
  ///
  /// In en, this message translates to:
  /// **'Hazri ships the part of the SGPC jantri it has been given ({from} to {to}). The rest arrives in an app update.'**
  String gurpurabNoDataBody(String from, String to);

  /// No description provided for @gurpurabFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All days'**
  String get gurpurabFilterAll;

  /// No description provided for @gurpurabFilterGurpurabsOnly.
  ///
  /// In en, this message translates to:
  /// **'Gurpurabs only'**
  String get gurpurabFilterGurpurabsOnly;

  /// No description provided for @gurpurabNoneUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No events in the next 90 days'**
  String get gurpurabNoneUpcoming;

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'My paath goals'**
  String get goalsTitle;

  /// No description provided for @goalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done today'**
  String goalsSubtitle(int done, int total);

  /// No description provided for @goalsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a paath goal'**
  String get goalsAdd;

  /// No description provided for @goalsFooter.
  ///
  /// In en, this message translates to:
  /// **'Goals, counts and reminders stay on this phone and appear in your Diary.'**
  String get goalsFooter;

  /// No description provided for @goalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No goals yet. A goal is a quiet way to keep an extra paath going.'**
  String get goalsEmpty;

  /// No description provided for @goalRuleOnce.
  ///
  /// In en, this message translates to:
  /// **'Once a day'**
  String get goalRuleOnce;

  /// No description provided for @goalRuleTimes.
  ///
  /// In en, this message translates to:
  /// **'{count} times a day'**
  String goalRuleTimes(int count);

  /// No description provided for @goalRuleForDays.
  ///
  /// In en, this message translates to:
  /// **'For {days} days · {count} extra paath a day'**
  String goalRuleForDays(int days, int count);

  /// No description provided for @goalRuleUntil.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String goalRuleUntil(String date);

  /// No description provided for @goalStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get goalStatusDone;

  /// No description provided for @goalStatusProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} today'**
  String goalStatusProgress(int done, int total);

  /// No description provided for @goalStatusDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total} · pending'**
  String goalStatusDay(int day, int total);

  /// No description provided for @goalStatusComplete.
  ///
  /// In en, this message translates to:
  /// **'Goal complete'**
  String get goalStatusComplete;

  /// No description provided for @goalFieldBani.
  ///
  /// In en, this message translates to:
  /// **'Bani'**
  String get goalFieldBani;

  /// No description provided for @goalFieldTimes.
  ///
  /// In en, this message translates to:
  /// **'How many times a day'**
  String get goalFieldTimes;

  /// No description provided for @goalFieldTimesHint.
  ///
  /// In en, this message translates to:
  /// **'about {minutes} min each'**
  String goalFieldTimesHint(int minutes);

  /// No description provided for @goalFieldDuration.
  ///
  /// In en, this message translates to:
  /// **'For how long'**
  String get goalFieldDuration;

  /// No description provided for @goalDurationEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get goalDurationEveryDay;

  /// No description provided for @goalDuration40Days.
  ///
  /// In en, this message translates to:
  /// **'40 days'**
  String get goalDuration40Days;

  /// No description provided for @goalDurationUntilDate.
  ///
  /// In en, this message translates to:
  /// **'Until a date'**
  String get goalDurationUntilDate;

  /// No description provided for @goalFieldReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get goalFieldReminder;

  /// No description provided for @goalReminderEveryDayAt.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String goalReminderEveryDayAt(String time);

  /// No description provided for @goalSave.
  ///
  /// In en, this message translates to:
  /// **'Save goal'**
  String get goalSave;

  /// No description provided for @goalMoreBanis.
  ///
  /// In en, this message translates to:
  /// **'More…'**
  String get goalMoreBanis;

  /// No description provided for @goalPause.
  ///
  /// In en, this message translates to:
  /// **'Pause goal'**
  String get goalPause;

  /// No description provided for @goalDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this goal? Its ticks stay in your Diary.'**
  String get goalDeleteConfirm;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// No description provided for @settingsSectionReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get settingsSectionReading;

  /// No description provided for @settingsGurbaniScript.
  ///
  /// In en, this message translates to:
  /// **'Gurbani script'**
  String get settingsGurbaniScript;

  /// No description provided for @settingsGurbaniScriptSub.
  ///
  /// In en, this message translates to:
  /// **'Also switch anytime from the reader'**
  String get settingsGurbaniScriptSub;

  /// No description provided for @settingsShowMeaningsSub.
  ///
  /// In en, this message translates to:
  /// **'Punjabi, Hindi or English'**
  String get settingsShowMeaningsSub;

  /// No description provided for @settingsSectionAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get settingsSectionAudio;

  /// No description provided for @settingsNitnemAudio.
  ///
  /// In en, this message translates to:
  /// **'Nitnem audio'**
  String get settingsNitnemAudio;

  /// No description provided for @settingsSukhmaniAudio.
  ///
  /// In en, this message translates to:
  /// **'Sukhmani Sahib audio'**
  String get settingsSukhmaniAudio;

  /// No description provided for @settingsSectionVersions.
  ///
  /// In en, this message translates to:
  /// **'Bani versions'**
  String get settingsSectionVersions;

  /// No description provided for @settingsSectionReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsSectionReminders;

  /// No description provided for @settingsPaathGoals.
  ///
  /// In en, this message translates to:
  /// **'Paath goals'**
  String get settingsPaathGoals;

  /// No description provided for @settingsPaathGoalsSub.
  ///
  /// In en, this message translates to:
  /// **'Set a reminder for each goal'**
  String get settingsPaathGoalsSub;

  /// No description provided for @settingsGoalsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} goals'**
  String settingsGoalsCount(int count);

  /// No description provided for @settingsOnTimeReminders.
  ///
  /// In en, this message translates to:
  /// **'On-time reminders'**
  String get settingsOnTimeReminders;

  /// No description provided for @settingsOnTimeAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed — reminders arrive to the minute'**
  String get settingsOnTimeAllowed;

  /// No description provided for @settingsOnTimeNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed — reminders may be a few minutes late'**
  String get settingsOnTimeNotAllowed;

  /// No description provided for @settingsSunFor.
  ///
  /// In en, this message translates to:
  /// **'Sunrise & sunset for'**
  String get settingsSunFor;

  /// No description provided for @settingsRemindersNotArriving.
  ///
  /// In en, this message translates to:
  /// **'Reminders not arriving?'**
  String get settingsRemindersNotArriving;

  /// No description provided for @settingsSectionDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get settingsSectionDisplay;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsThemeAuto;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsSectionDiary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get settingsSectionDiary;

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Back up to Google account'**
  String get settingsBackup;

  /// No description provided for @settingsBackupSub.
  ///
  /// In en, this message translates to:
  /// **'Restores on a new phone'**
  String get settingsBackupSub;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsAboutCredits.
  ///
  /// In en, this message translates to:
  /// **'About & credits'**
  String get settingsAboutCredits;

  /// No description provided for @settingsAboutCreditsSub.
  ///
  /// In en, this message translates to:
  /// **'Paathi, text sources, translations'**
  String get settingsAboutCreditsSub;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacySub.
  ///
  /// In en, this message translates to:
  /// **'No ads on Gurbani screens · No login · Works offline'**
  String get settingsPrivacySub;

  /// No description provided for @settingsAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous usage & crash reports'**
  String get settingsAnalytics;

  /// No description provided for @settingsAnalyticsSub.
  ///
  /// In en, this message translates to:
  /// **'Not collected in this build'**
  String get settingsAnalyticsSub;

  /// No description provided for @settingsLicences.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get settingsLicences;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Hazri {version}'**
  String settingsVersion(String version);

  /// No description provided for @cityPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your city'**
  String get cityPickerTitle;

  /// No description provided for @cityPickerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search cities'**
  String get cityPickerSearch;

  /// No description provided for @cityPickerUseLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get cityPickerUseLocation;

  /// No description provided for @cityPickerNoResults.
  ///
  /// In en, this message translates to:
  /// **'No city matched. Try a nearby larger city.'**
  String get cityPickerNoResults;

  /// No description provided for @cityPickerNote.
  ///
  /// In en, this message translates to:
  /// **'Only used on this phone, to work out sunrise and sunset.'**
  String get cityPickerNote;

  /// No description provided for @batteryHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders not arriving?'**
  String get batteryHelpTitle;

  /// No description provided for @batteryHelpBody.
  ///
  /// In en, this message translates to:
  /// **'Some phones stop background apps to save battery. If a reminder is late or missing, allow Hazri to run in the background.'**
  String get batteryHelpBody;

  /// No description provided for @batteryHelpSamsung.
  ///
  /// In en, this message translates to:
  /// **'Samsung: Settings → Battery → Background usage limits → remove Hazri from Sleeping apps.'**
  String get batteryHelpSamsung;

  /// No description provided for @batteryHelpXiaomi.
  ///
  /// In en, this message translates to:
  /// **'Xiaomi/Redmi: Settings → Apps → Hazri → Autostart on, and Battery saver → No restrictions.'**
  String get batteryHelpXiaomi;

  /// No description provided for @batteryHelpVivo.
  ///
  /// In en, this message translates to:
  /// **'Vivo/iQOO: Settings → Battery → Background power consumption → allow Hazri.'**
  String get batteryHelpVivo;

  /// No description provided for @batteryHelpOppo.
  ///
  /// In en, this message translates to:
  /// **'Oppo/Realme: Settings → Battery → App battery usage → Hazri → Allow background activity.'**
  String get batteryHelpOppo;

  /// No description provided for @batteryHelpOnePlus.
  ///
  /// In en, this message translates to:
  /// **'OnePlus: Settings → Battery → Battery optimisation → Hazri → Don\'t optimise.'**
  String get batteryHelpOnePlus;

  /// No description provided for @batteryHelpButton.
  ///
  /// In en, this message translates to:
  /// **'Open battery settings'**
  String get batteryHelpButton;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About & credits'**
  String get aboutTitle;

  /// No description provided for @aboutPurpose.
  ///
  /// In en, this message translates to:
  /// **'Hazri is a free, offline Nitnem app in Punjabi, Hindi and English. No ads on Gurbani. No login. Works offline.'**
  String get aboutPurpose;

  /// No description provided for @aboutTextSources.
  ///
  /// In en, this message translates to:
  /// **'Gurbani text & transliteration'**
  String get aboutTextSources;

  /// No description provided for @aboutMeaningSources.
  ///
  /// In en, this message translates to:
  /// **'Meanings and teeka'**
  String get aboutMeaningSources;

  /// No description provided for @aboutCalendarSource.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get aboutCalendarSource;

  /// No description provided for @aboutCityData.
  ///
  /// In en, this message translates to:
  /// **'City data'**
  String get aboutCityData;

  /// No description provided for @aboutFonts.
  ///
  /// In en, this message translates to:
  /// **'Fonts'**
  String get aboutFonts;

  /// No description provided for @aboutFontsBody.
  ///
  /// In en, this message translates to:
  /// **'Mukta, Baloo Paaji 2, Noto Serif Gurmukhi and Noto Serif Devanagari — SIL Open Font License.'**
  String get aboutFontsBody;

  /// No description provided for @aboutContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get aboutContact;

  /// No description provided for @aboutNoAudioYet.
  ///
  /// In en, this message translates to:
  /// **'Audio is not in this build. Recordings will be commissioned with written rights before release.'**
  String get aboutNoAudioYet;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Hazri has no account and collects no personal data. Your diary, goals and settings stay on this phone and in your own Google backup. If you pick a city or use your location, it stays on the phone and is used only to work out sunrise and sunset.'**
  String get privacyBody;

  /// No description provided for @privacyNoAnalytics.
  ///
  /// In en, this message translates to:
  /// **'This build sends nothing anywhere: no analytics, no crash reporting, no network requests at all.'**
  String get privacyNoAnalytics;

  /// No description provided for @notifChannelNitnem.
  ///
  /// In en, this message translates to:
  /// **'Nitnem reminders'**
  String get notifChannelNitnem;

  /// No description provided for @notifChannelSimran.
  ///
  /// In en, this message translates to:
  /// **'Daily Simran'**
  String get notifChannelSimran;

  /// No description provided for @notifChannelGurpurab.
  ///
  /// In en, this message translates to:
  /// **'Gurpurab'**
  String get notifChannelGurpurab;

  /// No description provided for @notifChannelGoals.
  ///
  /// In en, this message translates to:
  /// **'Paath goals'**
  String get notifChannelGoals;

  /// No description provided for @notifAmritVelaTitle.
  ///
  /// In en, this message translates to:
  /// **'Amrit Vela'**
  String get notifAmritVelaTitle;

  /// No description provided for @notifAmritVelaBody.
  ///
  /// In en, this message translates to:
  /// **'{bani} is ready — sunrise today is at {time}.'**
  String notifAmritVelaBody(String bani, String time);

  /// No description provided for @notifSimranTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Simran'**
  String get notifSimranTitle;

  /// No description provided for @notifSimranBody.
  ///
  /// In en, this message translates to:
  /// **'Five quiet minutes of Waheguru Simran.'**
  String get notifSimranBody;

  /// No description provided for @notifGurpurabTitle.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow is a Gurpurab'**
  String get notifGurpurabTitle;

  /// No description provided for @notifGurpurabToday.
  ///
  /// In en, this message translates to:
  /// **'Today is a Gurpurab'**
  String get notifGurpurabToday;

  /// No description provided for @notifRehrasBody.
  ///
  /// In en, this message translates to:
  /// **'Your evening bani, at the time you chose — {minutes} minutes.'**
  String notifRehrasBody(int minutes);

  /// No description provided for @notifBaniBody.
  ///
  /// In en, this message translates to:
  /// **'{bani} — {minutes} minutes.'**
  String notifBaniBody(String bani, int minutes);

  /// No description provided for @notifGoalBody.
  ///
  /// In en, this message translates to:
  /// **'Your paath goal for today — {done} of {total} done.'**
  String notifGoalBody(int done, int total);

  /// No description provided for @notifActionStartNitnem.
  ///
  /// In en, this message translates to:
  /// **'Start Nitnem'**
  String get notifActionStartNitnem;

  /// No description provided for @notifActionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get notifActionStart;

  /// No description provided for @notifActionLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get notifActionLater;

  /// No description provided for @notifActionBegin.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get notifActionBegin;

  /// No description provided for @notifActionSkipToday.
  ///
  /// In en, this message translates to:
  /// **'Skip today'**
  String get notifActionSkipToday;

  /// No description provided for @notifActionOpenCalendar.
  ///
  /// In en, this message translates to:
  /// **'Open calendar'**
  String get notifActionOpenCalendar;

  /// No description provided for @shareCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Hukamnama'**
  String get shareCardTitle;

  /// No description provided for @shareCardFooter.
  ///
  /// In en, this message translates to:
  /// **'Read daily on Hazri'**
  String get shareCardFooter;

  /// No description provided for @shareCardTruncated.
  ///
  /// In en, this message translates to:
  /// **'…read in Hazri'**
  String get shareCardTruncated;

  /// No description provided for @shareCardPreview.
  ///
  /// In en, this message translates to:
  /// **'Share card preview'**
  String get shareCardPreview;

  /// No description provided for @shareCardShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareCardShare;

  /// No description provided for @comingSoonShort.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get comingSoonShort;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorGeneric;

  /// No description provided for @errorContentDb.
  ///
  /// In en, this message translates to:
  /// **'The bundled content could not be opened. Reinstalling Hazri should fix it.'**
  String get errorContentDb;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'pa'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'hi':
      return LHi();
    case 'pa':
      return LPa();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
