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
  /// **'Audio for this bani is not in this build yet'**
  String get audioNotInBuild;

  /// No description provided for @audioNotInBuildSub.
  ///
  /// In en, this message translates to:
  /// **'Japji Sahib has its recitation. The other banis follow once their recordings are ready.'**
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
  /// **'My goals'**
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
  /// **'Mukta, Baloo Paaji 2, Playfair Display, Noto Serif Gurmukhi and Noto Serif Devanagari — SIL Open Font License.'**
  String get aboutFontsBody;

  /// No description provided for @aboutContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get aboutContact;

  /// No description provided for @aboutNoAudioYet.
  ///
  /// In en, this message translates to:
  /// **'The recitation shipped with the app is played from the phone and never streamed.'**
  String get aboutNoAudioYet;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Hazri has no password and no sign-in screen. Reading a bani, hearing it, seeing the calendar and writing your diary all happen on this phone and work with the radio off. Your diary, goals and settings stay on this phone and in your own Google backup. If you pick a city or use your location, it stays on the phone and is used only to work out sunrise and sunset.'**
  String get privacyBody;

  /// No description provided for @privacyNoAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Nothing leaves this phone unless you join the sangat. Analytics are switched off in this build and no crash reports are sent.'**
  String get privacyNoAnalytics;

  /// No description provided for @privacySangat.
  ///
  /// In en, this message translates to:
  /// **'If you join the sangat, what goes to the server is your name, city, email and the counts behind the groups and goals you joined. The words in your diary never go, and your email is never shown to anybody else.'**
  String get privacySangat;

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

  /// No description provided for @notifSimranEndTitle.
  ///
  /// In en, this message translates to:
  /// **'Simran complete'**
  String get notifSimranEndTitle;

  /// No description provided for @notifSimranEndBody.
  ///
  /// In en, this message translates to:
  /// **'Your sitting has run its length. It is logged in your Diary.'**
  String get notifSimranEndBody;

  /// No description provided for @simranSangatUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the sangat just now'**
  String get simranSangatUnreachable;

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
  /// **'Today\'s Vichar'**
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

  /// No description provided for @audioIncluded.
  ///
  /// In en, this message translates to:
  /// **'Recitation included'**
  String get audioIncluded;

  /// No description provided for @audioIncludedSub.
  ///
  /// In en, this message translates to:
  /// **'Every bani plays offline, with the text following along.'**
  String get audioIncludedSub;

  /// No description provided for @settingsAudioOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone'**
  String get settingsAudioOnPhone;

  /// No description provided for @aboutAudioHeading.
  ///
  /// In en, this message translates to:
  /// **'Recitation'**
  String get aboutAudioHeading;

  /// No description provided for @readerTapLineToSeek.
  ///
  /// In en, this message translates to:
  /// **'Tap any line to start the paath there'**
  String get readerTapLineToSeek;

  /// No description provided for @readerLockControlsOff.
  ///
  /// In en, this message translates to:
  /// **'Lock-screen controls are off'**
  String get readerLockControlsOff;

  /// No description provided for @readerLockControlsOffSub.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications and the paath can be paused from the lock screen.'**
  String get readerLockControlsOffSub;

  /// No description provided for @settingsLockScreenControls.
  ///
  /// In en, this message translates to:
  /// **'Lock-screen controls'**
  String get settingsLockScreenControls;

  /// No description provided for @settingsLockScreenAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed — play and pause show while the phone is locked'**
  String get settingsLockScreenAllowed;

  /// No description provided for @settingsLockScreenBlocked.
  ///
  /// In en, this message translates to:
  /// **'Not allowed — notifications are turned off for Hazri'**
  String get settingsLockScreenBlocked;

  /// No description provided for @actionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// No description provided for @playerStillPlaying.
  ///
  /// In en, this message translates to:
  /// **'Still playing'**
  String get playerStillPlaying;

  /// No description provided for @vicharTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Vichar'**
  String get vicharTitle;

  /// No description provided for @vicharNative.
  ///
  /// In en, this message translates to:
  /// **'ਅੱਜ ਦਾ ਵਿਚਾਰ'**
  String get vicharNative;

  /// No description provided for @vicharSource.
  ///
  /// In en, this message translates to:
  /// **'Sri Guru Granth Sahib Ji'**
  String get vicharSource;

  /// No description provided for @vicharExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get vicharExplore;

  /// No description provided for @vicharShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share this Vichar'**
  String get vicharShareTitle;

  /// No description provided for @vicharShareBody.
  ///
  /// In en, this message translates to:
  /// **'Choose how to send it'**
  String get vicharShareBody;

  /// No description provided for @vicharShareAsText.
  ///
  /// In en, this message translates to:
  /// **'As text'**
  String get vicharShareAsText;

  /// No description provided for @vicharShareAsImage.
  ///
  /// In en, this message translates to:
  /// **'As image'**
  String get vicharShareAsImage;

  /// No description provided for @vicharMeaningPa.
  ///
  /// In en, this message translates to:
  /// **'In Punjabi'**
  String get vicharMeaningPa;

  /// No description provided for @vicharMeaningEn.
  ///
  /// In en, this message translates to:
  /// **'In English'**
  String get vicharMeaningEn;

  /// No description provided for @vicharNone.
  ///
  /// In en, this message translates to:
  /// **'No Vichar in this build yet'**
  String get vicharNone;

  /// No description provided for @vicharDayOf.
  ///
  /// In en, this message translates to:
  /// **'Line {day} of {total}'**
  String vicharDayOf(int day, int total);

  /// No description provided for @goalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a daily goal'**
  String get goalsEmptyTitle;

  /// No description provided for @goalsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a bani and how often to recite it. Your goals appear here on the day, at the time you set.'**
  String get goalsEmptyBody;

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

  /// No description provided for @calendarKindPrakash.
  ///
  /// In en, this message translates to:
  /// **'Prakash'**
  String get calendarKindPrakash;

  /// No description provided for @calendarKindGurgaddi.
  ///
  /// In en, this message translates to:
  /// **'Gurgaddi'**
  String get calendarKindGurgaddi;

  /// No description provided for @calendarKindJotiJot.
  ///
  /// In en, this message translates to:
  /// **'Joti Jot'**
  String get calendarKindJotiJot;

  /// No description provided for @calendarKindShaheedi.
  ///
  /// In en, this message translates to:
  /// **'Shaheedi'**
  String get calendarKindShaheedi;

  /// No description provided for @calendarKindJorMela.
  ///
  /// In en, this message translates to:
  /// **'Jorh Mela'**
  String get calendarKindJorMela;

  /// No description provided for @calendarKindBirth.
  ///
  /// In en, this message translates to:
  /// **'Birth anniversary'**
  String get calendarKindBirth;

  /// No description provided for @calendarKindHistorical.
  ///
  /// In en, this message translates to:
  /// **'Historical'**
  String get calendarKindHistorical;

  /// No description provided for @calendarKindFestival.
  ///
  /// In en, this message translates to:
  /// **'Festival'**
  String get calendarKindFestival;

  /// No description provided for @calendarKindSpecial.
  ///
  /// In en, this message translates to:
  /// **'Observance'**
  String get calendarKindSpecial;

  /// No description provided for @calendarKindSangrand.
  ///
  /// In en, this message translates to:
  /// **'Sangrand'**
  String get calendarKindSangrand;

  /// No description provided for @calendarKindPuranmashi.
  ///
  /// In en, this message translates to:
  /// **'Puranmashi'**
  String get calendarKindPuranmashi;

  /// No description provided for @calendarKindMasya.
  ///
  /// In en, this message translates to:
  /// **'Masya'**
  String get calendarKindMasya;

  /// No description provided for @gurpurabSupplementary.
  ///
  /// In en, this message translates to:
  /// **'Cross-check, not in the SGPC list'**
  String get gurpurabSupplementary;

  /// No description provided for @sangatSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Join the sangat'**
  String get sangatSheetTitle;

  /// No description provided for @sangatSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Hazri works fully without this. This adds the people.'**
  String get sangatSheetBody;

  /// No description provided for @sangatPerkSee.
  ///
  /// In en, this message translates to:
  /// **'See who is reciting'**
  String get sangatPerkSee;

  /// No description provided for @sangatPerkSeeSub.
  ///
  /// In en, this message translates to:
  /// **'Your family, your sangat, the world'**
  String get sangatPerkSeeSub;

  /// No description provided for @sangatPerkGoal.
  ///
  /// In en, this message translates to:
  /// **'Join a shared goal'**
  String get sangatPerkGoal;

  /// No description provided for @sangatPerkGoalSub.
  ///
  /// In en, this message translates to:
  /// **'A group\'s paath, counted together'**
  String get sangatPerkGoalSub;

  /// No description provided for @sangatPerkDiary.
  ///
  /// In en, this message translates to:
  /// **'Keep your diary safe'**
  String get sangatPerkDiary;

  /// No description provided for @sangatPerkDiarySub.
  ///
  /// In en, this message translates to:
  /// **'It comes back if you change phone'**
  String get sangatPerkDiarySub;

  /// No description provided for @sangatSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up — takes a couple of seconds'**
  String get sangatSetUp;

  /// No description provided for @sangatNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get sangatNotNow;

  /// No description provided for @sangatNoAds.
  ///
  /// In en, this message translates to:
  /// **'No password · no ads · your paath stays on your phone'**
  String get sangatNoAds;

  /// No description provided for @sangatBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Join the sangat'**
  String get sangatBannerTitle;

  /// No description provided for @sangatBannerBody.
  ///
  /// In en, this message translates to:
  /// **'See who is reciting with you, worldwide'**
  String get sangatBannerBody;

  /// No description provided for @sangatBannerTime.
  ///
  /// In en, this message translates to:
  /// **'Takes a couple of seconds'**
  String get sangatBannerTime;

  /// No description provided for @sangatBannerCta.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get sangatBannerCta;

  /// No description provided for @sangatProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Join the sangat'**
  String get sangatProfileTitle;

  /// No description provided for @sangatProfileSub.
  ///
  /// In en, this message translates to:
  /// **'So your paath is counted with others'**
  String get sangatProfileSub;

  /// No description provided for @sangatFieldName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get sangatFieldName;

  /// No description provided for @sangatFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get sangatFieldEmail;

  /// No description provided for @sangatFieldEmailHint.
  ///
  /// In en, this message translates to:
  /// **'How your sangat comes back if you change phone. Nobody else in the app ever sees it.'**
  String get sangatFieldEmailHint;

  /// No description provided for @sangatFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get sangatFieldPhone;

  /// No description provided for @sangatFieldPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Add a number'**
  String get sangatFieldPhoneHint;

  /// No description provided for @sangatFieldCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get sangatFieldCity;

  /// No description provided for @sangatFieldCityHint.
  ///
  /// In en, this message translates to:
  /// **'Shown as one dot on the Simran globe, and nothing finer.'**
  String get sangatFieldCityHint;

  /// No description provided for @sangatOptional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get sangatOptional;

  /// No description provided for @sangatNoPasswordEver.
  ///
  /// In en, this message translates to:
  /// **'No password to make or remember, and never will be. You are in the sangat as soon as you tap Continue.'**
  String get sangatNoPasswordEver;

  /// No description provided for @sangatContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get sangatContinue;

  /// No description provided for @sangatWhatWeStore.
  ///
  /// In en, this message translates to:
  /// **'What we store & why'**
  String get sangatWhatWeStore;

  /// No description provided for @sangatNeedName.
  ///
  /// In en, this message translates to:
  /// **'Please add your name'**
  String get sangatNeedName;

  /// No description provided for @sangatNeedEmail.
  ///
  /// In en, this message translates to:
  /// **'Please add an email address'**
  String get sangatNeedEmail;

  /// No description provided for @sangatBadEmail.
  ///
  /// In en, this message translates to:
  /// **'That does not look like an email address'**
  String get sangatBadEmail;

  /// No description provided for @sangatNeedCity.
  ///
  /// In en, this message translates to:
  /// **'Please add your city'**
  String get sangatNeedCity;

  /// No description provided for @sangatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the sangat. Your paath is safe on this phone — try again when you have signal.'**
  String get sangatUnavailable;

  /// No description provided for @sangatEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email already has a Hazri account'**
  String get sangatEmailInUse;

  /// No description provided for @sangatJoined.
  ///
  /// In en, this message translates to:
  /// **'You are in the sangat'**
  String get sangatJoined;

  /// No description provided for @sangatRefused.
  ///
  /// In en, this message translates to:
  /// **'Something is wrong at our end, not yours. Your paath is safe on this phone.'**
  String get sangatRefused;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get accountTitle;

  /// No description provided for @accountEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmail;

  /// No description provided for @accountPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get accountPhone;

  /// No description provided for @accountCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get accountCity;

  /// No description provided for @accountNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get accountNotAdded;

  /// No description provided for @accountVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get accountVerified;

  /// No description provided for @accountNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get accountNotVerified;

  /// No description provided for @accountVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your verification'**
  String get accountVerifyTitle;

  /// No description provided for @accountVerifyBody.
  ///
  /// In en, this message translates to:
  /// **'Your account works either way. Confirming your email is what brings it back if you change phone.'**
  String get accountVerifyBody;

  /// No description provided for @accountVerifyCta.
  ///
  /// In en, this message translates to:
  /// **'Verify my email'**
  String get accountVerifyCta;

  /// No description provided for @accountSafeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your sangat is safe'**
  String get accountSafeTitle;

  /// No description provided for @accountSafeBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in with this email on any phone and your groups, goals and diary come back.'**
  String get accountSafeBody;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this phone'**
  String get accountSignOut;

  /// No description provided for @accountSignOutWarn.
  ///
  /// In en, this message translates to:
  /// **'Your account is not verified yet, so signing out loses it. Verify your email first.'**
  String get accountSignOutWarn;

  /// No description provided for @accountSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out anyway'**
  String get accountSignOutConfirm;

  /// No description provided for @accountSectionYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get accountSectionYou;

  /// No description provided for @accountJoinedFirst.
  ///
  /// In en, this message translates to:
  /// **'Join the sangat to see your account here.'**
  String get accountJoinedFirst;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyTitle;

  /// No description provided for @verifyCheckInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get verifyCheckInbox;

  /// No description provided for @verifySentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to {email}. Tap it and this phone is confirmed.'**
  String verifySentTo(String email);

  /// No description provided for @verifySend.
  ///
  /// In en, this message translates to:
  /// **'Send the link'**
  String get verifySend;

  /// No description provided for @verifySendAgain.
  ///
  /// In en, this message translates to:
  /// **'Send it again'**
  String get verifySendAgain;

  /// No description provided for @verifySent.
  ///
  /// In en, this message translates to:
  /// **'Sent. It can take a minute to arrive.'**
  String get verifySent;

  /// No description provided for @verifyWrongAddress.
  ///
  /// In en, this message translates to:
  /// **'Wrong address?'**
  String get verifyWrongAddress;

  /// No description provided for @verifyChangeIt.
  ///
  /// In en, this message translates to:
  /// **'Change it and we will send a new link'**
  String get verifyChangeIt;

  /// No description provided for @verifyUntilThen.
  ///
  /// In en, this message translates to:
  /// **'Until this is done your groups and goals live on this phone only, and cannot be brought back if you change phone.'**
  String get verifyUntilThen;

  /// No description provided for @verifyLater.
  ///
  /// In en, this message translates to:
  /// **'Do this later'**
  String get verifyLater;

  /// No description provided for @sangatTitle.
  ///
  /// In en, this message translates to:
  /// **'Sangat'**
  String get sangatTitle;

  /// No description provided for @sangatCreateOrJoin.
  ///
  /// In en, this message translates to:
  /// **'Create or join'**
  String get sangatCreateOrJoin;

  /// No description provided for @sangatWorldwide.
  ///
  /// In en, this message translates to:
  /// **'The sangat worldwide'**
  String get sangatWorldwide;

  /// No description provided for @sangatYourGroups.
  ///
  /// In en, this message translates to:
  /// **'Your groups'**
  String get sangatYourGroups;

  /// No description provided for @sangatCanJoin.
  ///
  /// In en, this message translates to:
  /// **'Groups you can join'**
  String get sangatCanJoin;

  /// No description provided for @sangatSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get sangatSeeAll;

  /// No description provided for @sangatJoinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get sangatJoinGroup;

  /// No description provided for @sangatHaveLink.
  ///
  /// In en, this message translates to:
  /// **'Have a link? Join a group'**
  String get sangatHaveLink;

  /// No description provided for @sangatNoGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'You are in the sangat and not in a group yet. Make one for your family, or join one below.'**
  String get sangatNoGroupsYet;

  /// No description provided for @sangatNotJoinedTitle.
  ///
  /// In en, this message translates to:
  /// **'The sangat is where paath is counted together'**
  String get sangatNotJoinedTitle;

  /// No description provided for @groupKindFamily.
  ///
  /// In en, this message translates to:
  /// **'family group'**
  String get groupKindFamily;

  /// No description provided for @groupKindSangat.
  ///
  /// In en, this message translates to:
  /// **'sangat'**
  String get groupKindSangat;

  /// No description provided for @groupKindCircle.
  ///
  /// In en, this message translates to:
  /// **'simran circle'**
  String get groupKindCircle;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String groupMembers(int count);

  /// No description provided for @groupNoGoalYet.
  ///
  /// In en, this message translates to:
  /// **'No shared goal yet'**
  String get groupNoGoalYet;

  /// No description provided for @groupProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {target} {unit}'**
  String groupProgress(String done, String target, String unit);

  /// No description provided for @unitPaath.
  ///
  /// In en, this message translates to:
  /// **'paath'**
  String get unitPaath;

  /// No description provided for @unitMinutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get unitMinutes;

  /// No description provided for @groupGone.
  ///
  /// In en, this message translates to:
  /// **'That group is no longer there'**
  String get groupGone;

  /// No description provided for @groupCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a group'**
  String get groupCreateTitle;

  /// No description provided for @groupWhatKind.
  ///
  /// In en, this message translates to:
  /// **'What kind'**
  String get groupWhatKind;

  /// No description provided for @groupKindFamilySub.
  ///
  /// In en, this message translates to:
  /// **'People you live with or call'**
  String get groupKindFamilySub;

  /// No description provided for @groupKindSangatSub.
  ///
  /// In en, this message translates to:
  /// **'A gurdwara or a wider group'**
  String get groupKindSangatSub;

  /// No description provided for @groupKindCircleSub.
  ///
  /// In en, this message translates to:
  /// **'Counted in minutes, not paath'**
  String get groupKindCircleSub;

  /// No description provided for @groupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupNameLabel;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Seen by the people in the group. Change it whenever you like.'**
  String get groupNameHint;

  /// No description provided for @groupNeedName.
  ///
  /// In en, this message translates to:
  /// **'Please give the group a name'**
  String get groupNeedName;

  /// No description provided for @groupWhoCanFind.
  ///
  /// In en, this message translates to:
  /// **'Who can find it'**
  String get groupWhoCanFind;

  /// No description provided for @groupPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private — people you send the link to'**
  String get groupPrivate;

  /// No description provided for @groupPrivateSub.
  ///
  /// In en, this message translates to:
  /// **'Live straight away'**
  String get groupPrivateSub;

  /// No description provided for @groupListed.
  ///
  /// In en, this message translates to:
  /// **'Listed in Sangat — anyone can find it'**
  String get groupListed;

  /// No description provided for @groupListedSub.
  ///
  /// In en, this message translates to:
  /// **'Checked before it appears'**
  String get groupListedSub;

  /// No description provided for @groupListedNote.
  ///
  /// In en, this message translates to:
  /// **'The name of a listed group is seen by people who never met you, so we read it before it appears — usually the same day. Private groups go live at once.'**
  String get groupListedNote;

  /// No description provided for @groupCreateCta.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get groupCreateCta;

  /// No description provided for @groupCreated.
  ///
  /// In en, this message translates to:
  /// **'Your group is ready'**
  String get groupCreated;

  /// No description provided for @groupSharedGoal.
  ///
  /// In en, this message translates to:
  /// **'Shared goal'**
  String get groupSharedGoal;

  /// No description provided for @groupYou.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get groupYou;

  /// No description provided for @groupTheGroup.
  ///
  /// In en, this message translates to:
  /// **'THE GROUP'**
  String get groupTheGroup;

  /// No description provided for @groupStartPaath.
  ///
  /// In en, this message translates to:
  /// **'Start the paath'**
  String get groupStartPaath;

  /// No description provided for @groupLogPaath.
  ///
  /// In en, this message translates to:
  /// **'Log a paath'**
  String get groupLogPaath;

  /// No description provided for @groupMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupMembersTitle;

  /// No description provided for @groupInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get groupInvite;

  /// No description provided for @groupReport.
  ///
  /// In en, this message translates to:
  /// **'Report this group'**
  String get groupReport;

  /// No description provided for @groupAnonMember.
  ///
  /// In en, this message translates to:
  /// **'a member'**
  String get groupAnonMember;

  /// No description provided for @groupYouSuffix.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get groupYouSuffix;

  /// No description provided for @groupAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get groupAdmin;

  /// No description provided for @groupLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Log a paath'**
  String get groupLogTitle;

  /// No description provided for @groupLogAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to the group'**
  String get groupLogAdd;

  /// No description provided for @groupLogged.
  ///
  /// In en, this message translates to:
  /// **'Added to the group'**
  String get groupLogged;

  /// No description provided for @groupLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave this group'**
  String get groupLeave;

  /// No description provided for @groupLeft.
  ///
  /// In en, this message translates to:
  /// **'You have left the group'**
  String get groupLeft;

  /// No description provided for @groupSetGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared goal'**
  String get groupSetGoalTitle;

  /// No description provided for @groupGoalWhat.
  ///
  /// In en, this message translates to:
  /// **'What the group recites'**
  String get groupGoalWhat;

  /// No description provided for @groupGoalHowMany.
  ///
  /// In en, this message translates to:
  /// **'How many, together'**
  String get groupGoalHowMany;

  /// No description provided for @groupGoalByWhen.
  ///
  /// In en, this message translates to:
  /// **'By when'**
  String get groupGoalByWhen;

  /// No description provided for @groupGoalNoEnd.
  ///
  /// In en, this message translates to:
  /// **'Or no end date'**
  String get groupGoalNoEnd;

  /// No description provided for @groupGoalPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick another date'**
  String get groupGoalPickDate;

  /// No description provided for @groupGoalWillSee.
  ///
  /// In en, this message translates to:
  /// **'THE GROUP WILL SEE'**
  String get groupGoalWillSee;

  /// No description provided for @groupGoalSet.
  ///
  /// In en, this message translates to:
  /// **'Set the goal'**
  String get groupGoalSet;

  /// No description provided for @groupGoalSaved.
  ///
  /// In en, this message translates to:
  /// **'The group has its goal'**
  String get groupGoalSaved;

  /// No description provided for @groupGoalNeedTarget.
  ///
  /// In en, this message translates to:
  /// **'Please choose how many'**
  String get groupGoalNeedTarget;

  /// No description provided for @groupInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get groupInviteTitle;

  /// No description provided for @groupInviteShareLink.
  ///
  /// In en, this message translates to:
  /// **'Share this link'**
  String get groupInviteShareLink;

  /// No description provided for @groupInviteShare.
  ///
  /// In en, this message translates to:
  /// **'Share the link'**
  String get groupInviteShare;

  /// No description provided for @groupInviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get groupInviteCopied;

  /// No description provided for @groupCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get groupCodeCopied;

  /// No description provided for @sangatAlreadyJoined.
  ///
  /// In en, this message translates to:
  /// **'Already joined? Bring my account back'**
  String get sangatAlreadyJoined;

  /// No description provided for @privacyExportNote.
  ///
  /// In en, this message translates to:
  /// **'Your diary, goals and reading position are not here because they are not held anywhere but this phone, unless you switched Diary sync on.'**
  String get privacyExportNote;

  /// No description provided for @groupInviteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get groupInviteRemove;

  /// No description provided for @groupInviteStarted.
  ///
  /// In en, this message translates to:
  /// **'You started this group'**
  String get groupInviteStarted;

  /// No description provided for @groupJoinByLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a group'**
  String get groupJoinByLinkTitle;

  /// No description provided for @groupJoinByLinkBody.
  ///
  /// In en, this message translates to:
  /// **'Paste the link somebody sent you, or the code at the end of it.'**
  String get groupJoinByLinkBody;

  /// No description provided for @groupJoinByLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Link or code'**
  String get groupJoinByLinkLabel;

  /// No description provided for @groupJoinByLinkCta.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get groupJoinByLinkCta;

  /// No description provided for @groupJoinedOne.
  ///
  /// In en, this message translates to:
  /// **'You are in the group'**
  String get groupJoinedOne;

  /// No description provided for @groupSimranSlug.
  ///
  /// In en, this message translates to:
  /// **'Simran minutes'**
  String get groupSimranSlug;

  /// No description provided for @navSangat.
  ///
  /// In en, this message translates to:
  /// **'Sangat'**
  String get navSangat;

  /// No description provided for @simranOthersHere.
  ///
  /// In en, this message translates to:
  /// **'{count} others'**
  String simranOthersHere(int count);

  /// No description provided for @simranOthersSub.
  ///
  /// In en, this message translates to:
  /// **'are here today'**
  String get simranOthersSub;

  /// No description provided for @simranGlobeFirst.
  ///
  /// In en, this message translates to:
  /// **'You are the first here today'**
  String get simranGlobeFirst;

  /// No description provided for @simranGlobeTurn.
  ///
  /// In en, this message translates to:
  /// **'Turn the globe with your hand'**
  String get simranGlobeTurn;

  /// No description provided for @hazriMarked.
  ///
  /// In en, this message translates to:
  /// **'Today\'s hazri is marked'**
  String get hazriMarked;

  /// No description provided for @hazriNotYet.
  ///
  /// In en, this message translates to:
  /// **'Today\'s hazri is not marked yet'**
  String get hazriNotYet;

  /// No description provided for @hazriMarkedAtWith.
  ///
  /// In en, this message translates to:
  /// **'Marked at {time}, with {what}'**
  String hazriMarkedAtWith(String time, String what);

  /// No description provided for @hazriMarkedAt.
  ///
  /// In en, this message translates to:
  /// **'Marked at {time}'**
  String hazriMarkedAt(String time);

  /// No description provided for @hazriHow.
  ///
  /// In en, this message translates to:
  /// **'One paath, or one sitting of simran, marks it'**
  String get hazriHow;

  /// No description provided for @hazriSimran.
  ///
  /// In en, this message translates to:
  /// **'Naam Simran'**
  String get hazriSimran;

  /// No description provided for @hazriGoalsAllDone.
  ///
  /// In en, this message translates to:
  /// **'All of today\'s goals are done'**
  String get hazriGoalsAllDone;

  /// No description provided for @hazriSeeDiary.
  ///
  /// In en, this message translates to:
  /// **'See my diary'**
  String get hazriSeeDiary;

  /// No description provided for @diaryHazriDot.
  ///
  /// In en, this message translates to:
  /// **'Hazri'**
  String get diaryHazriDot;

  /// No description provided for @diaryGoalsDot.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get diaryGoalsDot;

  /// No description provided for @diaryNotYet.
  ///
  /// In en, this message translates to:
  /// **'not yet'**
  String get diaryNotYet;

  /// No description provided for @diaryHazriNote.
  ///
  /// In en, this message translates to:
  /// **'One paath or five, a single sitting of simran — any of them marks the day\'s hazri. The count is what you did, not what you owed.'**
  String get diaryHazriNote;

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Bring my account back'**
  String get restoreTitle;

  /// No description provided for @restoreBeenHere.
  ///
  /// In en, this message translates to:
  /// **'You have been here before'**
  String get restoreBeenHere;

  /// No description provided for @restoreThisAccount.
  ///
  /// In en, this message translates to:
  /// **'Restore this account'**
  String get restoreThisAccount;

  /// No description provided for @restoreOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get restoreOr;

  /// No description provided for @restoreStartFresh.
  ///
  /// In en, this message translates to:
  /// **'Start a new account'**
  String get restoreStartFresh;

  /// No description provided for @restoreStartFreshSub.
  ///
  /// In en, this message translates to:
  /// **'Nothing from the old one comes with it'**
  String get restoreStartFreshSub;

  /// No description provided for @restoreNothingSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Restoring signs nothing out. The same account can be on more than one phone at once.'**
  String get restoreNothingSignedOut;

  /// No description provided for @restoreSendLink.
  ///
  /// In en, this message translates to:
  /// **'Send me the link'**
  String get restoreSendLink;

  /// No description provided for @restorePasteLabel.
  ///
  /// In en, this message translates to:
  /// **'Paste the link from the email'**
  String get restorePasteLabel;

  /// No description provided for @restorePasteHint.
  ///
  /// In en, this message translates to:
  /// **'Open the email on this phone, copy the whole link and paste it here.'**
  String get restorePasteHint;

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'Your account is back'**
  String get restoreDone;

  /// No description provided for @restoreDiaryNote.
  ///
  /// In en, this message translates to:
  /// **'Your diary comes back only if sync was on. With sync off, your groups and goals are kept and the diary stays on the phone that wrote it.'**
  String get restoreDiaryNote;

  /// No description provided for @restoreOpenToday.
  ///
  /// In en, this message translates to:
  /// **'Open Today'**
  String get restoreOpenToday;

  /// No description provided for @linkProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'That link did not work'**
  String get linkProblemTitle;

  /// No description provided for @linkUsedTitle.
  ///
  /// In en, this message translates to:
  /// **'Already used'**
  String get linkUsedTitle;

  /// No description provided for @linkUsedBody.
  ///
  /// In en, this message translates to:
  /// **'This link has signed in a phone already. Every link works once and then stops, which is what keeps a forwarded email from being a way in.'**
  String get linkUsedBody;

  /// No description provided for @linkExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Too old'**
  String get linkExpiredTitle;

  /// No description provided for @linkExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Links last an hour. This one has lapsed on its own — nobody used it.'**
  String get linkExpiredBody;

  /// No description provided for @linkWrongTitle.
  ///
  /// In en, this message translates to:
  /// **'Not a link from us'**
  String get linkWrongTitle;

  /// No description provided for @linkWrongBody.
  ///
  /// In en, this message translates to:
  /// **'That does not look like the link we sent. Copy the whole of it, including everything after the question mark.'**
  String get linkWrongBody;

  /// No description provided for @linkSendAnother.
  ///
  /// In en, this message translates to:
  /// **'Send a new link'**
  String get linkSendAnother;

  /// No description provided for @linkWrongAddressNote.
  ///
  /// In en, this message translates to:
  /// **'If neither of those was you, change your email address before you verify. A link is only ever sent to the address on the account.'**
  String get linkWrongAddressNote;

  /// No description provided for @verifyConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your email is confirmed'**
  String get verifyConfirmed;

  /// No description provided for @privacyDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & my data'**
  String get privacyDataTitle;

  /// No description provided for @privacyOnPhoneOnly.
  ///
  /// In en, this message translates to:
  /// **'On this phone only'**
  String get privacyOnPhoneOnly;

  /// No description provided for @privacyPhoneDiary.
  ///
  /// In en, this message translates to:
  /// **'Your diary and streaks'**
  String get privacyPhoneDiary;

  /// No description provided for @privacyPhoneDiarySynced.
  ///
  /// In en, this message translates to:
  /// **'Your streaks; your diary also syncs to your account'**
  String get privacyPhoneDiarySynced;

  /// No description provided for @privacyPhoneProgress.
  ///
  /// In en, this message translates to:
  /// **'Reading position and goals'**
  String get privacyPhoneProgress;

  /// No description provided for @privacyPhoneContent.
  ///
  /// In en, this message translates to:
  /// **'Every bani, its audio and the calendar'**
  String get privacyPhoneContent;

  /// No description provided for @privacySharedWithSangat.
  ///
  /// In en, this message translates to:
  /// **'Shared with the sangat'**
  String get privacySharedWithSangat;

  /// No description provided for @privacyShareName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get privacyShareName;

  /// No description provided for @privacyShareCity.
  ///
  /// In en, this message translates to:
  /// **'The city you chose — shown as one dot on the globe'**
  String get privacyShareCity;

  /// No description provided for @privacyShareGroups.
  ///
  /// In en, this message translates to:
  /// **'Which groups you are in'**
  String get privacyShareGroups;

  /// No description provided for @privacyShareCounts.
  ///
  /// In en, this message translates to:
  /// **'How much you have completed towards a shared goal'**
  String get privacyShareCounts;

  /// No description provided for @privacyAccountOnly.
  ///
  /// In en, this message translates to:
  /// **'Held for your account alone'**
  String get privacyAccountOnly;

  /// No description provided for @privacyAccountEmail.
  ///
  /// In en, this message translates to:
  /// **'Your email — the only thing it does is bring your account back'**
  String get privacyAccountEmail;

  /// No description provided for @privacyShowMyName.
  ///
  /// In en, this message translates to:
  /// **'Show my name in groups'**
  String get privacyShowMyName;

  /// No description provided for @privacyShowMyNameSub.
  ///
  /// In en, this message translates to:
  /// **'Off shows you as “a member”'**
  String get privacyShowMyNameSub;

  /// No description provided for @privacyDownload.
  ///
  /// In en, this message translates to:
  /// **'Download everything we hold'**
  String get privacyDownload;

  /// No description provided for @privacyDownloadSub.
  ///
  /// In en, this message translates to:
  /// **'A file you can keep, read and check'**
  String get privacyDownloadSub;

  /// No description provided for @privacyDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete my account and data'**
  String get privacyDelete;

  /// No description provided for @privacyDeleteSub.
  ///
  /// In en, this message translates to:
  /// **'Your diary stays on this phone'**
  String get privacyDeleteSub;

  /// No description provided for @privacyDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete everything the sangat holds? Your groups, your counts and your account go. Nothing on this phone is touched.'**
  String get privacyDeleteConfirm;

  /// No description provided for @privacyDeleteDo.
  ///
  /// In en, this message translates to:
  /// **'Delete it'**
  String get privacyDeleteDo;

  /// No description provided for @privacyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account and its data are gone'**
  String get privacyDeleted;

  /// No description provided for @privacyNotJoined.
  ///
  /// In en, this message translates to:
  /// **'You have not joined the sangat, so nothing here has left this phone.'**
  String get privacyNotJoined;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Vichar'**
  String get libraryTitle;

  /// No description provided for @librarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read, and look things up'**
  String get librarySubtitle;

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search articles, gurdwaras, banis…'**
  String get librarySearchHint;

  /// No description provided for @libraryKindAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libraryKindAll;

  /// No description provided for @libraryKindArticle.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get libraryKindArticle;

  /// No description provided for @libraryKindGurdwara.
  ///
  /// In en, this message translates to:
  /// **'Gurdwaras'**
  String get libraryKindGurdwara;

  /// No description provided for @libraryKindGuru.
  ///
  /// In en, this message translates to:
  /// **'Guru Sahibans'**
  String get libraryKindGuru;

  /// No description provided for @libraryKindBani.
  ///
  /// In en, this message translates to:
  /// **'Banis'**
  String get libraryKindBani;

  /// No description provided for @libraryKindDay.
  ///
  /// In en, this message translates to:
  /// **'Sikh days'**
  String get libraryKindDay;

  /// No description provided for @libraryMoreToRead.
  ///
  /// In en, this message translates to:
  /// **'More to read'**
  String get libraryMoreToRead;

  /// No description provided for @libraryMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min read'**
  String libraryMinutes(int count);

  /// No description provided for @libraryNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Vichar is the one part of Hazri that needs a connection. Your banis, their recitations, the calendar and your diary never do.'**
  String get libraryNeedsConnection;

  /// No description provided for @libraryNothingMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches that yet'**
  String get libraryNothingMatches;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'There is nothing here yet. Vichar is written on the website and every phone reads the same copy, so what appears here is whatever has been published.'**
  String get libraryEmpty;

  /// No description provided for @libraryOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get libraryOffline;

  /// No description provided for @libraryClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get libraryClear;

  /// No description provided for @libraryResults.
  ///
  /// In en, this message translates to:
  /// **'{count} results for “{query}”'**
  String libraryResults(int count, String query);

  /// No description provided for @libraryCorrections.
  ///
  /// In en, this message translates to:
  /// **'Fetched from the website. If something here is wrong, it is corrected once there and every phone sees the correction.'**
  String get libraryCorrections;

  /// No description provided for @libraryOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get libraryOpen;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

  /// No description provided for @syncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What happens, and when'**
  String get syncSubtitle;

  /// No description provided for @syncStateSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncStateSynced;

  /// No description provided for @syncStateSyncedSub.
  ///
  /// In en, this message translates to:
  /// **'Everything is up to date'**
  String get syncStateSyncedSub;

  /// No description provided for @syncStateWaiting.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get syncStateWaiting;

  /// No description provided for @syncStateWaitingSub.
  ///
  /// In en, this message translates to:
  /// **'Carry on — your paath is saved on this phone and goes up when you are back'**
  String get syncStateWaitingSub;

  /// No description provided for @syncStateWifi.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Wi‑Fi'**
  String get syncStateWifi;

  /// No description provided for @syncStateWifiSub.
  ///
  /// In en, this message translates to:
  /// **'Your paath is saved on this phone. Turn off “only on Wi‑Fi” to send it now.'**
  String get syncStateWifiSub;

  /// No description provided for @syncStateSending.
  ///
  /// In en, this message translates to:
  /// **'Sending {count} days'**
  String syncStateSending(int count);

  /// No description provided for @syncStateOff.
  ///
  /// In en, this message translates to:
  /// **'Sync is off'**
  String get syncStateOff;

  /// No description provided for @syncStateOffSub.
  ///
  /// In en, this message translates to:
  /// **'Your diary lives on this phone and nowhere else'**
  String get syncStateOffSub;

  /// No description provided for @syncWorksWithout.
  ///
  /// In en, this message translates to:
  /// **'Hazri works with no signal. Sync only decides whether your diary can come back on a new phone.'**
  String get syncWorksWithout;

  /// No description provided for @syncMyDiary.
  ///
  /// In en, this message translates to:
  /// **'Sync my diary'**
  String get syncMyDiary;

  /// No description provided for @syncWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Only on Wi‑Fi'**
  String get syncWifiOnly;

  /// No description provided for @syncWifiOnlySub.
  ///
  /// In en, this message translates to:
  /// **'Saves mobile data'**
  String get syncWifiOnlySub;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncNeedsAccount.
  ///
  /// In en, this message translates to:
  /// **'Join the sangat first — there is nowhere to sync to without an account.'**
  String get syncNeedsAccount;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifOwnPractice.
  ///
  /// In en, this message translates to:
  /// **'Your own practice'**
  String get notifOwnPractice;

  /// No description provided for @notifYourGroups.
  ///
  /// In en, this message translates to:
  /// **'Your groups'**
  String get notifYourGroups;

  /// No description provided for @notifGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global Simran'**
  String get notifGlobal;

  /// No description provided for @notifGoalClose.
  ///
  /// In en, this message translates to:
  /// **'A goal is close'**
  String get notifGoalClose;

  /// No description provided for @notifGoalCloseSub.
  ///
  /// In en, this message translates to:
  /// **'When the group passes 90%'**
  String get notifGoalCloseSub;

  /// No description provided for @notifSomeoneJoined.
  ///
  /// In en, this message translates to:
  /// **'Someone joined'**
  String get notifSomeoneJoined;

  /// No description provided for @notifSomeoneJoinedSub.
  ///
  /// In en, this message translates to:
  /// **'New members in your groups'**
  String get notifSomeoneJoinedSub;

  /// No description provided for @notifGroupSummary.
  ///
  /// In en, this message translates to:
  /// **'Daily group summary'**
  String get notifGroupSummary;

  /// No description provided for @notifGroupSummarySub.
  ///
  /// In en, this message translates to:
  /// **'One message, at 9 PM'**
  String get notifGroupSummarySub;

  /// No description provided for @notifLargeGatherings.
  ///
  /// In en, this message translates to:
  /// **'Large gatherings'**
  String get notifLargeGatherings;

  /// No description provided for @notifLargeGatheringsSub.
  ///
  /// In en, this message translates to:
  /// **'When thousands are sitting together'**
  String get notifLargeGatheringsSub;

  /// No description provided for @notifGroupsNotYet.
  ///
  /// In en, this message translates to:
  /// **'These need a message sent from a server, and Hazri has none yet. Your own reminders above are set by this phone and work with the radio off.'**
  String get notifGroupsNotYet;

  /// No description provided for @menuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTooltip;

  /// No description provided for @simranYouAndOthers.
  ///
  /// In en, this message translates to:
  /// **'You and {count} others'**
  String simranYouAndOthers(int count);

  /// No description provided for @simranAreHereToday.
  ///
  /// In en, this message translates to:
  /// **'are here today'**
  String get simranAreHereToday;

  /// No description provided for @simranCitiesToday.
  ///
  /// In en, this message translates to:
  /// **'{count} cities today'**
  String simranCitiesToday(int count);

  /// No description provided for @simranLegendYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get simranLegendYou;

  /// No description provided for @simranLegendHere.
  ///
  /// In en, this message translates to:
  /// **'Here today'**
  String get simranLegendHere;

  /// No description provided for @simranBeginMinutes.
  ///
  /// In en, this message translates to:
  /// **'Begin Simran · {count} min'**
  String simranBeginMinutes(int count);

  /// No description provided for @simranTurnGlobeShort.
  ///
  /// In en, this message translates to:
  /// **'Turn the globe with your hand'**
  String get simranTurnGlobeShort;

  /// No description provided for @readerLoggedInDiary.
  ///
  /// In en, this message translates to:
  /// **'Logged in your diary · {time}'**
  String readerLoggedInDiary(String time);

  /// No description provided for @readerThisMarkedHazri.
  ///
  /// In en, this message translates to:
  /// **'This is what marked it — the first thing finished today'**
  String get readerThisMarkedHazri;

  /// No description provided for @readerStartAgain.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get readerStartAgain;

  /// No description provided for @readerNextBani.
  ///
  /// In en, this message translates to:
  /// **'Next bani'**
  String get readerNextBani;

  /// No description provided for @goalsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your goals'**
  String get goalsCardTitle;

  /// No description provided for @goalsDoneOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String goalsDoneOf(int done, int total);

  /// No description provided for @goalSimranOrBani.
  ///
  /// In en, this message translates to:
  /// **'Simran counts in minutes; a bani counts in paath'**
  String get goalSimranOrBani;

  /// No description provided for @goalHowLong.
  ///
  /// In en, this message translates to:
  /// **'How long each time'**
  String get goalHowLong;

  /// No description provided for @goalCustomMinutes.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get goalCustomMinutes;

  /// No description provided for @goalSimranLoops.
  ///
  /// In en, this message translates to:
  /// **'The recitation is five minutes long and starts again from the top for anything longer.'**
  String get goalSimranLoops;

  /// No description provided for @groupStartCounts.
  ///
  /// In en, this message translates to:
  /// **'Starting it here counts towards the goal when you finish'**
  String get groupStartCounts;

  /// No description provided for @groupSetGoalCta.
  ///
  /// In en, this message translates to:
  /// **'Set a shared goal'**
  String get groupSetGoalCta;

  /// No description provided for @groupChangeGoal.
  ///
  /// In en, this message translates to:
  /// **'Change the goal'**
  String get groupChangeGoal;

  /// No description provided for @groupNoGoalMember.
  ///
  /// In en, this message translates to:
  /// **'The group\'s admin sets what it recites together'**
  String get groupNoGoalMember;

  /// No description provided for @groupNoGoalAdmin.
  ///
  /// In en, this message translates to:
  /// **'Set what the group recites together, and how many'**
  String get groupNoGoalAdmin;

  /// No description provided for @groupInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Or give them this code'**
  String get groupInviteCode;

  /// No description provided for @groupInviteCodeHow.
  ///
  /// In en, this message translates to:
  /// **'In Hazri: Sangat → Have a link? Join a group → paste the code. The link itself opens the website, which is not built yet.'**
  String get groupInviteCodeHow;

  /// No description provided for @groupInviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Join {group} on Hazri.\n\nOpen Hazri → Sangat → “Have a link? Join a group”, and paste this code:\n\n{code}'**
  String groupInviteShareText(String group, String code);

  /// No description provided for @diarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every day you marked your hazri'**
  String get diarySubtitle;

  /// No description provided for @diaryStatHazriDays.
  ///
  /// In en, this message translates to:
  /// **'hazri days'**
  String get diaryStatHazriDays;

  /// No description provided for @diaryStatGoalsMet.
  ///
  /// In en, this message translates to:
  /// **'goals met'**
  String get diaryStatGoalsMet;

  /// No description provided for @diaryStatDaysInRow.
  ///
  /// In en, this message translates to:
  /// **'days in a row'**
  String get diaryStatDaysInRow;

  /// No description provided for @diaryNotYetAt.
  ///
  /// In en, this message translates to:
  /// **'not yet · {time}'**
  String diaryNotYetAt(String time);

  /// No description provided for @diaryHazriAndGoals.
  ///
  /// In en, this message translates to:
  /// **'Hazri and goals'**
  String get diaryHazriAndGoals;

  /// No description provided for @diaryTickGoals.
  ///
  /// In en, this message translates to:
  /// **'Any paath or sitting of simran marks the hazri. Tick a goal you completed on this day, or mark the hazri yourself for a paath read elsewhere.'**
  String get diaryTickGoals;

  /// No description provided for @diaryNoGoalsThatDay.
  ///
  /// In en, this message translates to:
  /// **'No goals were set on this day'**
  String get diaryNoGoalsThatDay;

  /// No description provided for @simranPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get simranPaused;

  /// No description provided for @simranBrandDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily '**
  String get simranBrandDaily;

  /// No description provided for @simranBrandName.
  ///
  /// In en, this message translates to:
  /// **'Simran'**
  String get simranBrandName;

  /// No description provided for @simranKicker.
  ///
  /// In en, this message translates to:
  /// **'ONE BREATH · ONE WORLD · ONE WAHEGURU'**
  String get simranKicker;

  /// No description provided for @simranHeadlineOne.
  ///
  /// In en, this message translates to:
  /// **'One Name.'**
  String get simranHeadlineOne;

  /// No description provided for @simranHeadlineTwoLead.
  ///
  /// In en, this message translates to:
  /// **'A Brighter '**
  String get simranHeadlineTwoLead;

  /// No description provided for @simranHeadlineTwoWord.
  ///
  /// In en, this message translates to:
  /// **'World.'**
  String get simranHeadlineTwoWord;

  /// No description provided for @simranVerseOne.
  ///
  /// In en, this message translates to:
  /// **'Breathe in peace, breathe out worry.'**
  String get simranVerseOne;

  /// No description provided for @simranVerseTwoLead.
  ///
  /// In en, this message translates to:
  /// **'With every breath, say '**
  String get simranVerseTwoLead;

  /// No description provided for @simranVerseTwoWord.
  ///
  /// In en, this message translates to:
  /// **'Waheguru.'**
  String get simranVerseTwoWord;
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
