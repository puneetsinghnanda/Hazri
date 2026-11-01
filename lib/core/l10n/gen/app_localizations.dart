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
  /// **'Mark your Hazri to Waheguru'**
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
  /// **'Goals'**
  String get goalsTitle;

  /// No description provided for @goalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done today'**
  String goalsSubtitle(int done, int total);

  /// No description provided for @goalsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add or change paaths'**
  String get goalsAdd;

  /// No description provided for @goalPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Your day of paath'**
  String get goalPlanTitle;

  /// No description provided for @goalPlanIntro.
  ///
  /// In en, this message translates to:
  /// **'Each paath sits at its time in the day. Tap one to add it to your goal, and tap it again to take it out.'**
  String get goalPlanIntro;

  /// No description provided for @goalPlanAmritVela.
  ///
  /// In en, this message translates to:
  /// **'Amrit Vela'**
  String get goalPlanAmritVela;

  /// No description provided for @goalPlanMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get goalPlanMorning;

  /// No description provided for @goalPlanDaytime.
  ///
  /// In en, this message translates to:
  /// **'Daytime'**
  String get goalPlanDaytime;

  /// No description provided for @goalPlanEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get goalPlanEvening;

  /// No description provided for @goalPlanChangeTime.
  ///
  /// In en, this message translates to:
  /// **'Change reminder time'**
  String get goalPlanChangeTime;

  /// No description provided for @goalPlanReminderNote.
  ///
  /// In en, this message translates to:
  /// **'Reminders are always on. Each paath starts at its usual time; tap the time to change it. Hazri stays quiet once that paath is done.'**
  String get goalPlanReminderNote;

  /// No description provided for @goalPlanStart.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Start goal · 1 paath a day} other{Start goal · {count} paaths a day}}'**
  String goalPlanStart(int count);

  /// No description provided for @goalPlanSave.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Save goal · 1 paath a day} other{Save goal · {count} paaths a day}}'**
  String goalPlanSave(int count);

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
  /// **'Hazri has no password and no sign-in screen. Reading a bani, hearing it, seeing the calendar and writing your diary all happen on this phone and work with no network.'**
  String get privacyBody;

  /// No description provided for @notifChannelGoals.
  ///
  /// In en, this message translates to:
  /// **'Goal reminders'**
  String get notifChannelGoals;

  /// No description provided for @notifGurpurabTitle.
  ///
  /// In en, this message translates to:
  /// **'Today: {event}'**
  String notifGurpurabTitle(String event);

  /// No description provided for @notifActionStartNitnem.
  ///
  /// In en, this message translates to:
  /// **'Start Nitnem'**
  String get notifActionStartNitnem;

  /// No description provided for @notifActionLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get notifActionLater;

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

  /// No description provided for @sangatBusy.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a few minutes and ask for another link — your signal is fine.'**
  String get sangatBusy;

  /// No description provided for @sangatFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong at our end ({code}). Your paath is safe on this phone.'**
  String sangatFailed(String code);

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

  /// No description provided for @accountOpenedWith.
  ///
  /// In en, this message translates to:
  /// **'Opened with: {route}'**
  String accountOpenedWith(String route);

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
  /// **'Sent. It can take a minute to arrive — look in your spam folder if it does not.'**
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

  /// No description provided for @verifyDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Your email is confirmed'**
  String get verifyDoneTitle;

  /// No description provided for @verifyDoneBody.
  ///
  /// In en, this message translates to:
  /// **'This address can bring your account back on a new phone.'**
  String get verifyDoneBody;

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

  /// No description provided for @diaryWhatYouDid.
  ///
  /// In en, this message translates to:
  /// **'What you completed'**
  String get diaryWhatYouDid;

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
  /// **'Restored {count} entries'**
  String restoreDone(int count);

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
  /// **'Link already used'**
  String get linkUsedTitle;

  /// No description provided for @linkUsedBody.
  ///
  /// In en, this message translates to:
  /// **'This link has signed in a phone already. Every link works once and then stops, which is what keeps a forwarded email from being a way in.'**
  String get linkUsedBody;

  /// No description provided for @linkExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Link expired'**
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

  /// No description provided for @linkMismatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Made for a different address'**
  String get linkMismatchTitle;

  /// No description provided for @linkMismatchBody.
  ///
  /// In en, this message translates to:
  /// **'This link is ours and it still works, but it was sent to a different address than the one above. Correct the address, or paste the link that went to it — a new link will not help.'**
  String get linkMismatchBody;

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
  /// **'Vichar comes from the website. The first time it needs a connection; after that the last copy stays on your phone and opens without one, and a newer one is fetched whenever there is a connection.'**
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

  /// No description provided for @saakhiTitle.
  ///
  /// In en, this message translates to:
  /// **'Saakhis'**
  String get saakhiTitle;

  /// No description provided for @saakhiLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stories from Sikh history to read and listen to with your children.'**
  String get saakhiLibrarySubtitle;

  /// No description provided for @saakhiEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no saakhis on this phone yet.'**
  String get saakhiEmpty;

  /// No description provided for @saakhiSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get saakhiSeeAll;

  /// No description provided for @saakhiOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Today\'s saakhi'**
  String get saakhiOfTheDay;

  /// No description provided for @saakhiMore.
  ///
  /// In en, this message translates to:
  /// **'More saakhis'**
  String get saakhiMore;

  /// No description provided for @saakhiPages.
  ///
  /// In en, this message translates to:
  /// **'{count} pages'**
  String saakhiPages(int count);

  /// No description provided for @saakhiMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String saakhiMinutes(int count);

  /// No description provided for @saakhiNarrationPunjabi.
  ///
  /// In en, this message translates to:
  /// **'Punjabi and English narration'**
  String get saakhiNarrationPunjabi;

  /// No description provided for @saakhiNarrationEnglish.
  ///
  /// In en, this message translates to:
  /// **'English narration'**
  String get saakhiNarrationEnglish;

  /// No description provided for @saakhiNarrationComing.
  ///
  /// In en, this message translates to:
  /// **'Narration coming soon'**
  String get saakhiNarrationComing;

  /// No description provided for @saakhiPunjabiNarrationComing.
  ///
  /// In en, this message translates to:
  /// **'The Punjabi narration is coming soon'**
  String get saakhiPunjabiNarrationComing;

  /// No description provided for @saakhiListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get saakhiListen;

  /// No description provided for @saakhiRead.
  ///
  /// In en, this message translates to:
  /// **'Read the saakhi'**
  String get saakhiRead;

  /// No description provided for @saakhiReadShort.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get saakhiReadShort;

  /// No description provided for @saakhiPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String saakhiPageOf(int page, int total);

  /// No description provided for @saakhiShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get saakhiShare;

  /// No description provided for @saakhiGurbani.
  ///
  /// In en, this message translates to:
  /// **'Gurbani'**
  String get saakhiGurbani;

  /// No description provided for @saakhiAng.
  ///
  /// In en, this message translates to:
  /// **'Ang {ang}'**
  String saakhiAng(int ang);

  /// No description provided for @saakhiSourceAng.
  ///
  /// In en, this message translates to:
  /// **'{source} · Ang {ang}'**
  String saakhiSourceAng(String source, int ang);

  /// No description provided for @saakhiReadAgain.
  ///
  /// In en, this message translates to:
  /// **'Read again'**
  String get saakhiReadAgain;

  /// No description provided for @saakhiTalkTogether.
  ///
  /// In en, this message translates to:
  /// **'Talk about it together'**
  String get saakhiTalkTogether;

  /// No description provided for @saakhiFavourite.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get saakhiFavourite;

  /// No description provided for @saakhiPreviousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get saakhiPreviousPage;

  /// No description provided for @saakhiNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get saakhiNextPage;

  /// No description provided for @saakhiPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get saakhiPlay;

  /// No description provided for @saakhiPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get saakhiPause;

  /// No description provided for @saakhiShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share this saakhi'**
  String get saakhiShareTitle;

  /// No description provided for @saakhiShareThisPage.
  ///
  /// In en, this message translates to:
  /// **'This page'**
  String get saakhiShareThisPage;

  /// No description provided for @saakhiShareWhole.
  ///
  /// In en, this message translates to:
  /// **'Whole saakhi'**
  String get saakhiShareWhole;

  /// No description provided for @saakhiCopyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get saakhiCopyText;

  /// No description provided for @saakhiCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied.'**
  String get saakhiCopied;

  /// No description provided for @saakhiShareEyebrow.
  ///
  /// In en, this message translates to:
  /// **'A saakhi'**
  String get saakhiShareEyebrow;

  /// No description provided for @saakhiShareBandTitle.
  ///
  /// In en, this message translates to:
  /// **'Read and listen to the full saakhi'**
  String get saakhiShareBandTitle;

  /// No description provided for @saakhiShareBandSub.
  ///
  /// In en, this message translates to:
  /// **'Free in the Hazri app · {site}'**
  String saakhiShareBandSub(String site);

  /// No description provided for @saakhiShareMessage.
  ///
  /// In en, this message translates to:
  /// **'{title}: {blurb} Free in the Hazri app: {link}'**
  String saakhiShareMessage(String title, String blurb, String link);

  /// No description provided for @libraryShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get libraryShare;

  /// No description provided for @libraryInDays.
  ///
  /// In en, this message translates to:
  /// **'In {count} days'**
  String libraryInDays(int count);

  /// No description provided for @libraryNextInCalendar.
  ///
  /// In en, this message translates to:
  /// **'Next in the calendar'**
  String get libraryNextInCalendar;

  /// No description provided for @libraryPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get libraryPrevious;

  /// No description provided for @libraryNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get libraryNext;

  /// No description provided for @libraryInTheCalendar.
  ///
  /// In en, this message translates to:
  /// **'In the calendar'**
  String get libraryInTheCalendar;

  /// No description provided for @libraryHowItUnfolds.
  ///
  /// In en, this message translates to:
  /// **'How the story unfolds'**
  String get libraryHowItUnfolds;

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
  /// **'The recitation is five minutes long and loops with a soft crossfade for anything longer.'**
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

  /// No description provided for @diaryStatPaath.
  ///
  /// In en, this message translates to:
  /// **'paath'**
  String get diaryStatPaath;

  /// No description provided for @diaryStatSimranMinutes.
  ///
  /// In en, this message translates to:
  /// **'simran minutes'**
  String get diaryStatSimranMinutes;

  /// No description provided for @diaryStatDaysInRow.
  ///
  /// In en, this message translates to:
  /// **'days in a row'**
  String get diaryStatDaysInRow;

  /// No description provided for @diaryTickAnything.
  ///
  /// In en, this message translates to:
  /// **'Tick anything you completed on this day'**
  String get diaryTickAnything;

  /// No description provided for @diaryNotYetAt.
  ///
  /// In en, this message translates to:
  /// **'not yet · {time}'**
  String diaryNotYetAt(String time);

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

  /// No description provided for @notifAv1Title.
  ///
  /// In en, this message translates to:
  /// **'Amrit Vela'**
  String get notifAv1Title;

  /// No description provided for @notifAv1Body.
  ///
  /// In en, this message translates to:
  /// **'The quietest hour of the day is here. {bani} is ready when you are.'**
  String notifAv1Body(String bani);

  /// No description provided for @notifAv2Title.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String notifAv2Title(String name);

  /// No description provided for @notifAv2Body.
  ///
  /// In en, this message translates to:
  /// **'Sunrise in {city} is at {sunrise}. Your Nitnem is ready.'**
  String notifAv2Body(String city, String sunrise);

  /// No description provided for @notifAv3Title.
  ///
  /// In en, this message translates to:
  /// **'The sangat is waking up'**
  String get notifAv3Title;

  /// No description provided for @notifAv3Body.
  ///
  /// In en, this message translates to:
  /// **'Mark your Hazri with Sangat. Begin now.'**
  String get notifAv3Body;

  /// No description provided for @notifAv4Title.
  ///
  /// In en, this message translates to:
  /// **'Day {streak} of your Hazri'**
  String notifAv4Title(int streak);

  /// No description provided for @notifAv4Body.
  ///
  /// In en, this message translates to:
  /// **'{streak} days in a row. Today\'s is waiting.'**
  String notifAv4Body(int streak);

  /// No description provided for @notifAv5Title.
  ///
  /// In en, this message translates to:
  /// **'Before the world wakes'**
  String get notifAv5Title;

  /// No description provided for @notifAv5Body.
  ///
  /// In en, this message translates to:
  /// **'A few quiet minutes now, before the day begins. {bani} is one tap away.'**
  String notifAv5Body(String bani);

  /// No description provided for @notifAv6Title.
  ///
  /// In en, this message translates to:
  /// **'Your Hazri for {weekday}'**
  String notifAv6Title(String weekday);

  /// No description provided for @notifAv6Body.
  ///
  /// In en, this message translates to:
  /// **'Mark today\'s Hazri with Nitnem or five minutes of Naam Simran.'**
  String get notifAv6Body;

  /// No description provided for @notifAv7Title.
  ///
  /// In en, this message translates to:
  /// **'Start the day with Waheguru'**
  String get notifAv7Title;

  /// No description provided for @notifAv7Body.
  ///
  /// In en, this message translates to:
  /// **'Nitnem first, everything else after. Hazri is open.'**
  String get notifAv7Body;

  /// No description provided for @notifGoalBaniTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for {bani}'**
  String notifGoalBaniTitle(String bani);

  /// No description provided for @notifGoalBaniBody.
  ///
  /// In en, this message translates to:
  /// **'{done} of {target} today. Your goal, day {day} of {days}.'**
  String notifGoalBaniBody(int done, int target, int day, int days);

  /// No description provided for @notifGoalBaniOpenBody.
  ///
  /// In en, this message translates to:
  /// **'{done} of {target} today.'**
  String notifGoalBaniOpenBody(int done, int target);

  /// No description provided for @notifGoalSimranTitle.
  ///
  /// In en, this message translates to:
  /// **'Your {minutes} minutes of Naam Simran'**
  String notifGoalSimranTitle(int minutes);

  /// No description provided for @notifGoalSimranBody.
  ///
  /// In en, this message translates to:
  /// **'One tap and the timer begins.'**
  String get notifGoalSimranBody;

  /// No description provided for @notifGurpurabBody.
  ///
  /// In en, this message translates to:
  /// **'Mark the day with Nitnem and your Hazri.'**
  String get notifGurpurabBody;

  /// No description provided for @notifRememberTitle.
  ///
  /// In en, this message translates to:
  /// **'Today we remember: {event}'**
  String notifRememberTitle(String event);

  /// No description provided for @notifRememberBody.
  ///
  /// In en, this message translates to:
  /// **'Begin the day with Nitnem and your Hazri.'**
  String get notifRememberBody;

  /// No description provided for @notifEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Today: {event}'**
  String notifEventTitle(String event);

  /// No description provided for @notifEventBody.
  ///
  /// In en, this message translates to:
  /// **'Begin the day with Nitnem and your Hazri.'**
  String get notifEventBody;

  /// No description provided for @notifHn1Title.
  ///
  /// In en, this message translates to:
  /// **'Your Hazri for today is still open'**
  String get notifHn1Title;

  /// No description provided for @notifHn1Body.
  ///
  /// In en, this message translates to:
  /// **'Five minutes of Naam Simran marks it. Begin when you\'re ready.'**
  String get notifHn1Body;

  /// No description provided for @notifHn2Title.
  ///
  /// In en, this message translates to:
  /// **'{count} of the sangat are here today'**
  String notifHn2Title(int count);

  /// No description provided for @notifHn2Body.
  ///
  /// In en, this message translates to:
  /// **'Join them with five minutes of Waheguru Simran.'**
  String get notifHn2Body;

  /// No description provided for @notifHn3Title.
  ///
  /// In en, this message translates to:
  /// **'Five minutes, just for you'**
  String get notifHn3Title;

  /// No description provided for @notifHn3Body.
  ///
  /// In en, this message translates to:
  /// **'Begin the day with Waheguru Simran, and your Hazri is marked.'**
  String get notifHn3Body;

  /// No description provided for @notifHn4Title.
  ///
  /// In en, this message translates to:
  /// **'Make it a habit'**
  String get notifHn4Title;

  /// No description provided for @notifHn4Body.
  ///
  /// In en, this message translates to:
  /// **'Add Naam Simran to a daily goal and Hazri will remind you at your own time.'**
  String get notifHn4Body;

  /// No description provided for @notifHn5Title.
  ///
  /// In en, this message translates to:
  /// **'Five minutes before the day gets busy'**
  String get notifHn5Title;

  /// No description provided for @notifHn5Body.
  ///
  /// In en, this message translates to:
  /// **'A short sitting of Naam Simran now marks today\'s Hazri.'**
  String get notifHn5Body;

  /// No description provided for @notifHn6Title.
  ///
  /// In en, this message translates to:
  /// **'Light up {city} on the globe'**
  String notifHn6Title(String city);

  /// No description provided for @notifHn6Body.
  ///
  /// In en, this message translates to:
  /// **'Open Hazri and you show as live today. Five minutes of Simran marks your Hazri.'**
  String get notifHn6Body;

  /// No description provided for @notifHn7Title.
  ///
  /// In en, this message translates to:
  /// **'One small step today'**
  String get notifHn7Title;

  /// No description provided for @notifHn7Body.
  ///
  /// In en, this message translates to:
  /// **'Five minutes of Naam Simran. That\'s all today\'s Hazri needs.'**
  String get notifHn7Body;

  /// No description provided for @notifActionOpenBani.
  ///
  /// In en, this message translates to:
  /// **'Open {bani}'**
  String notifActionOpenBani(String bani);

  /// No description provided for @notifActionBeginMinutes.
  ///
  /// In en, this message translates to:
  /// **'Begin {minutes} min'**
  String notifActionBeginMinutes(int minutes);

  /// No description provided for @notifActionSnooze.
  ///
  /// In en, this message translates to:
  /// **'In 15 min'**
  String get notifActionSnooze;

  /// No description provided for @notifActionSeeCalendar.
  ///
  /// In en, this message translates to:
  /// **'See calendar'**
  String get notifActionSeeCalendar;

  /// No description provided for @notifActionSetGoal.
  ///
  /// In en, this message translates to:
  /// **'Set a goal'**
  String get notifActionSetGoal;

  /// No description provided for @notifActionOpenHazri.
  ///
  /// In en, this message translates to:
  /// **'Open Hazri'**
  String get notifActionOpenHazri;

  /// No description provided for @notifActionOpenSangat.
  ///
  /// In en, this message translates to:
  /// **'Open Sangat'**
  String get notifActionOpenSangat;

  /// No description provided for @notifChannelAmritVela.
  ///
  /// In en, this message translates to:
  /// **'Amrit Vela'**
  String get notifChannelAmritVela;

  /// No description provided for @notifChannelCalendar.
  ///
  /// In en, this message translates to:
  /// **'Gurpurab and Sikh events'**
  String get notifChannelCalendar;

  /// No description provided for @notifChannelHazri.
  ///
  /// In en, this message translates to:
  /// **'Hazri reminder'**
  String get notifChannelHazri;

  /// No description provided for @notifChannelSangat.
  ///
  /// In en, this message translates to:
  /// **'Sangat'**
  String get notifChannelSangat;

  /// No description provided for @notifKindsHeading.
  ///
  /// In en, this message translates to:
  /// **'What Hazri sends'**
  String get notifKindsHeading;

  /// No description provided for @notifKindAmritVela.
  ///
  /// In en, this message translates to:
  /// **'Amrit Vela'**
  String get notifKindAmritVela;

  /// No description provided for @notifKindAmritVelaSub.
  ///
  /// In en, this message translates to:
  /// **'Every day at 4:00 AM'**
  String get notifKindAmritVelaSub;

  /// No description provided for @notifKindGoals.
  ///
  /// In en, this message translates to:
  /// **'Goal reminders'**
  String get notifKindGoals;

  /// No description provided for @notifKindGoalsSub.
  ///
  /// In en, this message translates to:
  /// **'At the time you set on each goal'**
  String get notifKindGoalsSub;

  /// No description provided for @notifKindCalendar.
  ///
  /// In en, this message translates to:
  /// **'Gurpurab and Sikh events'**
  String get notifKindCalendar;

  /// No description provided for @notifKindCalendarSub.
  ///
  /// In en, this message translates to:
  /// **'On the day: Gurpurabs at 6:00 AM, other days at 7:00 AM'**
  String get notifKindCalendarSub;

  /// No description provided for @notifKindHazri.
  ///
  /// In en, this message translates to:
  /// **'Hazri reminder'**
  String get notifKindHazri;

  /// No description provided for @notifKindHazriSub.
  ///
  /// In en, this message translates to:
  /// **'At 7:00 AM, only with no goal and no Hazri yet'**
  String get notifKindHazriSub;

  /// No description provided for @notifKindSangat.
  ///
  /// In en, this message translates to:
  /// **'Sangat'**
  String get notifKindSangat;

  /// No description provided for @notifKindSangatSub.
  ///
  /// In en, this message translates to:
  /// **'Your groups at 9:00 PM, and their milestones'**
  String get notifKindSangatSub;

  /// No description provided for @notifExactNote.
  ///
  /// In en, this message translates to:
  /// **'Reminders can arrive late, sometimes by hours, until Android allows Hazri \"Alarms & reminders\".'**
  String get notifExactNote;

  /// No description provided for @notifNoAds.
  ///
  /// In en, this message translates to:
  /// **'Hazri never sends anything you did not ask for, and never an advertisement.'**
  String get notifNoAds;

  /// No description provided for @notifDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get notifDiagnostics;

  /// No description provided for @notifDiagnosticsSub.
  ///
  /// In en, this message translates to:
  /// **'What this phone says about reminders'**
  String get notifDiagnosticsSub;

  /// No description provided for @notifDiagAllowed.
  ///
  /// In en, this message translates to:
  /// **'Notifications allowed'**
  String get notifDiagAllowed;

  /// No description provided for @notifDiagExact.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms allowed'**
  String get notifDiagExact;

  /// No description provided for @notifDiagBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery optimisation off for Hazri'**
  String get notifDiagBattery;

  /// No description provided for @notifDiagPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get notifDiagPending;

  /// No description provided for @notifDiagNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get notifDiagNext;

  /// No description provided for @notifDiagNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get notifDiagNone;

  /// No description provided for @notifDiagLast.
  ///
  /// In en, this message translates to:
  /// **'Last delivered'**
  String get notifDiagLast;

  /// No description provided for @notifDiagSendNow.
  ///
  /// In en, this message translates to:
  /// **'Send one now'**
  String get notifDiagSendNow;

  /// No description provided for @notifDiagSendSoon.
  ///
  /// In en, this message translates to:
  /// **'Send one in two minutes'**
  String get notifDiagSendSoon;

  /// No description provided for @notifDiagTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Hazri test'**
  String get notifDiagTestTitle;

  /// No description provided for @notifDiagTestBody.
  ///
  /// In en, this message translates to:
  /// **'If you can read this, reminders reach this phone.'**
  String get notifDiagTestBody;

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

  /// No description provided for @goalSetCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a daily goal'**
  String get goalSetCardTitle;

  /// No description provided for @goalSetCardSubtitleFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose the banis you want to recite each day.'**
  String get goalSetCardSubtitleFirst;

  /// No description provided for @goalSetCardSubtitleAgain.
  ///
  /// In en, this message translates to:
  /// **'Your last goal is complete. Set a new one.'**
  String get goalSetCardSubtitleAgain;

  /// No description provided for @goalWidgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s goal'**
  String get goalWidgetTitle;

  /// No description provided for @goalWidgetProgress.
  ///
  /// In en, this message translates to:
  /// **'{met} of {total} done'**
  String goalWidgetProgress(int met, int total);

  /// No description provided for @goalTimesOfTarget.
  ///
  /// In en, this message translates to:
  /// **'{done} of {target}'**
  String goalTimesOfTarget(int done, int target);

  /// No description provided for @goalSimranMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String goalSimranMinutes(int minutes);

  /// No description provided for @goalDurationDays.
  ///
  /// In en, this message translates to:
  /// **'For {n} days'**
  String goalDurationDays(int n);

  /// No description provided for @goalDurationUntil.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String goalDurationUntil(String date);

  /// No description provided for @goalDayOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Day {n} of {total}'**
  String goalDayOfTotal(int n, int total);

  /// No description provided for @goalEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get goalEditSave;

  /// No description provided for @goalRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get goalRemove;

  /// No description provided for @goalRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String goalRemoveConfirmTitle(String name);

  /// No description provided for @goalRemoveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It leaves your goal from today. Days already recorded stay as they are.'**
  String get goalRemoveConfirmBody;

  /// No description provided for @goalEndDateInPast.
  ///
  /// In en, this message translates to:
  /// **'Choose today or a later date.'**
  String get goalEndDateInPast;

  /// No description provided for @goalReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Time for your daily goal'**
  String get goalReminderBody;

  /// No description provided for @goalTimesRule.
  ///
  /// In en, this message translates to:
  /// **'{times, plural, =1{once a day} other{{times} times a day}}'**
  String goalTimesRule(int times);

  /// No description provided for @goalNaamSimran.
  ///
  /// In en, this message translates to:
  /// **'Naam Simran'**
  String get goalNaamSimran;

  /// No description provided for @goalMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get goalMinutesLabel;

  /// No description provided for @goalEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get goalEdit;

  /// No description provided for @goalCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s goal is done'**
  String get goalCompleteTitle;

  /// No description provided for @diaryHazriMarked.
  ///
  /// In en, this message translates to:
  /// **'Hazri marked'**
  String get diaryHazriMarked;

  /// No description provided for @diaryNoHazri.
  ///
  /// In en, this message translates to:
  /// **'No hazri'**
  String get diaryNoHazri;

  /// No description provided for @diaryGoalSummary.
  ///
  /// In en, this message translates to:
  /// **'Goal: {met} of {total} met'**
  String diaryGoalSummary(int met, int total);

  /// No description provided for @diaryLegendHazri.
  ///
  /// In en, this message translates to:
  /// **'Hazri'**
  String get diaryLegendHazri;

  /// No description provided for @diaryLegendGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal met'**
  String get diaryLegendGoal;

  /// No description provided for @diarySourceRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get diarySourceRead;

  /// No description provided for @diarySourceListened.
  ///
  /// In en, this message translates to:
  /// **'Listened'**
  String get diarySourceListened;

  /// No description provided for @diarySourceDiary.
  ///
  /// In en, this message translates to:
  /// **'Marked in Diary'**
  String get diarySourceDiary;

  /// No description provided for @diarySourceRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get diarySourceRestored;

  /// No description provided for @diarySourceMigrated.
  ///
  /// In en, this message translates to:
  /// **'Carried over'**
  String get diarySourceMigrated;

  /// No description provided for @diarySimranStoppedEarly.
  ///
  /// In en, this message translates to:
  /// **'stopped early'**
  String get diarySimranStoppedEarly;

  /// No description provided for @diaryReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Days more than 7 days ago can\'t be changed.'**
  String get diaryReadOnly;

  /// No description provided for @diaryRecited.
  ///
  /// In en, this message translates to:
  /// **'Recited'**
  String get diaryRecited;

  /// No description provided for @diaryCountTimes.
  ///
  /// In en, this message translates to:
  /// **'× {count}'**
  String diaryCountTimes(int count);

  /// No description provided for @diaryAddRemove.
  ///
  /// In en, this message translates to:
  /// **'Add or take away'**
  String get diaryAddRemove;

  /// No description provided for @diaryStreakNow.
  ///
  /// In en, this message translates to:
  /// **'days in a row now'**
  String get diaryStreakNow;

  /// No description provided for @diaryStreakLongest.
  ///
  /// In en, this message translates to:
  /// **'your longest'**
  String get diaryStreakLongest;

  /// No description provided for @todayStreakCaption.
  ///
  /// In en, this message translates to:
  /// **'days of Hazri in a row'**
  String get todayStreakCaption;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @profileWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get profileWelcome;

  /// No description provided for @profileWelcomeName.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String profileWelcomeName(String name);

  /// No description provided for @profileBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get profileBannerTitle;

  /// No description provided for @profileBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your name and email to personalise the app.'**
  String get profileBannerSubtitle;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up profile'**
  String get profileSetupTitle;

  /// No description provided for @profileFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get profileFieldName;

  /// No description provided for @profileFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email *'**
  String get profileFieldEmail;

  /// No description provided for @profileFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get profileFieldPhone;

  /// No description provided for @profileFieldCity.
  ///
  /// In en, this message translates to:
  /// **'City *'**
  String get profileFieldCity;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get profileSave;

  /// No description provided for @profileErrNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get profileErrNameEmpty;

  /// No description provided for @profileErrNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Name must be 2–50 letters (spaces, . \' - allowed)'**
  String get profileErrNameInvalid;

  /// No description provided for @profileErrEmailEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get profileErrEmailEmpty;

  /// No description provided for @profileErrEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get profileErrEmailInvalid;

  /// No description provided for @profileErrCityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please choose your city'**
  String get profileErrCityEmpty;

  /// No description provided for @profileCityChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose your city'**
  String get profileCityChoose;

  /// No description provided for @profileCitySearch.
  ///
  /// In en, this message translates to:
  /// **'Search cities'**
  String get profileCitySearch;

  /// No description provided for @profileCityNearest.
  ///
  /// In en, this message translates to:
  /// **'Not on the list? Choose the nearest city.'**
  String get profileCityNearest;

  /// No description provided for @profileSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSavedTitle;

  /// No description provided for @profileSavedBody.
  ///
  /// In en, this message translates to:
  /// **'Would you like to confirm your email {email}? This is optional.'**
  String profileSavedBody(String email);

  /// No description provided for @profileSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get profileSkipForNow;

  /// No description provided for @profileConfirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm my email'**
  String get profileConfirmEmail;

  /// No description provided for @profileSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the email. You can try again from your profile.'**
  String get profileSendFailed;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileRowName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileRowName;

  /// No description provided for @profileRowEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileRowEmail;

  /// No description provided for @profileRowPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profileRowPhone;

  /// No description provided for @profileRowCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileRowCity;

  /// No description provided for @profileRowEmailStatus.
  ///
  /// In en, this message translates to:
  /// **'Email status'**
  String get profileRowEmailStatus;

  /// No description provided for @profileNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get profileNotProvided;

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileVerified;

  /// No description provided for @profileNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get profileNotVerified;

  /// No description provided for @profileStale.
  ///
  /// In en, this message translates to:
  /// **'Showing saved details. Couldn\'t refresh your email status.'**
  String get profileStale;

  /// No description provided for @profileRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get profileRetry;

  /// No description provided for @profileNone.
  ///
  /// In en, this message translates to:
  /// **'No profile found'**
  String get profileNone;

  /// No description provided for @profileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile.'**
  String get profileUnavailable;

  /// No description provided for @profileChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get profileChangeEmail;

  /// No description provided for @profileEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditButton;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTitle;

  /// No description provided for @profileEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileEditSave;

  /// No description provided for @profileEmailPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you to confirm {email}'**
  String profileEmailPending(String email);

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profileEmailExistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Email already registered'**
  String get profileEmailExistsTitle;

  /// No description provided for @profileEmailExistsBody.
  ///
  /// In en, this message translates to:
  /// **'An account with {email} already exists. To restore it on this phone, we will send a confirmation link to this email.'**
  String profileEmailExistsBody(String email);

  /// No description provided for @profileSendLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get profileSendLink;

  /// No description provided for @profileEmailNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found for this email. Please tap Save Profile again.'**
  String get profileEmailNotFound;

  /// No description provided for @emailSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get emailSentTitle;

  /// No description provided for @emailSentVerify.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to {email}. Open it on this phone to confirm your email.'**
  String emailSentVerify(String email);

  /// No description provided for @emailSentRestore.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to {email}. Open it on this phone within 1 hour to restore your profile.'**
  String emailSentRestore(String email);

  /// No description provided for @emailSentResend.
  ///
  /// In en, this message translates to:
  /// **'Resend link'**
  String get emailSentResend;

  /// No description provided for @emailSentResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {n}s'**
  String emailSentResendIn(int n);

  /// No description provided for @emailSentBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get emailSentBackHome;

  /// No description provided for @emailSentWrongEmail.
  ///
  /// In en, this message translates to:
  /// **'Wrong email? Change it'**
  String get emailSentWrongEmail;

  /// No description provided for @linkResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Email link'**
  String get linkResultTitle;

  /// No description provided for @linkChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking your link…'**
  String get linkChecking;

  /// No description provided for @linkEmailVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get linkEmailVerifiedTitle;

  /// No description provided for @linkEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Your email is verified.'**
  String get linkEmailVerified;

  /// No description provided for @linkEmailAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'Your email is already verified.'**
  String get linkEmailAlreadyVerified;

  /// No description provided for @linkEmailChanged.
  ///
  /// In en, this message translates to:
  /// **'Your new email is confirmed.'**
  String get linkEmailChanged;

  /// No description provided for @linkRestoredTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile restored'**
  String get linkRestoredTitle;

  /// No description provided for @linkRestored.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}. Your profile has been restored.'**
  String linkRestored(String name);

  /// No description provided for @linkExpired.
  ///
  /// In en, this message translates to:
  /// **'This link has expired.'**
  String get linkExpired;

  /// No description provided for @linkInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'Link not valid'**
  String get linkInvalidTitle;

  /// No description provided for @linkInvalid.
  ///
  /// In en, this message translates to:
  /// **'This link is invalid or has been replaced by a newer link.'**
  String get linkInvalid;

  /// No description provided for @linkUsed.
  ///
  /// In en, this message translates to:
  /// **'This link has already been used.'**
  String get linkUsed;

  /// No description provided for @linkWrongPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Wrong phone'**
  String get linkWrongPhoneTitle;

  /// No description provided for @linkWrongPhone.
  ///
  /// In en, this message translates to:
  /// **'Open this link on the phone where you requested the restore.'**
  String get linkWrongPhone;

  /// No description provided for @linkDeviceHasProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile already set up'**
  String get linkDeviceHasProfileTitle;

  /// No description provided for @linkDeviceHasProfile.
  ///
  /// In en, this message translates to:
  /// **'This phone already has a profile.'**
  String get linkDeviceHasProfile;

  /// No description provided for @linkBadRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid link.'**
  String get linkBadRequest;

  /// No description provided for @linkCouldNotCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check link'**
  String get linkCouldNotCheckTitle;

  /// No description provided for @linkSendNew.
  ///
  /// In en, this message translates to:
  /// **'Send a new link'**
  String get linkSendNew;

  /// No description provided for @linkTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get linkTryAgain;

  /// No description provided for @linkGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get linkGoHome;

  /// No description provided for @msgNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please try again.'**
  String get msgNetwork;

  /// No description provided for @msgGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get msgGeneric;

  /// No description provided for @msgRateLimitSeconds.
  ///
  /// In en, this message translates to:
  /// **'Please wait {n} seconds before requesting another email.'**
  String msgRateLimitSeconds(int n);

  /// No description provided for @msgRateLimitHours.
  ///
  /// In en, this message translates to:
  /// **'Too many emails requested. Please try again in {h} hours.'**
  String msgRateLimitHours(int h);

  /// No description provided for @msgEmailNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Email can\'t be sent yet. Your profile is saved; try confirming later.'**
  String get msgEmailNotConfigured;

  /// No description provided for @changeEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmailTitle;

  /// No description provided for @changeEmailField.
  ///
  /// In en, this message translates to:
  /// **'New email *'**
  String get changeEmailField;

  /// No description provided for @changeEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'We will send a new confirmation link to this email.'**
  String get changeEmailHelper;

  /// No description provided for @changeEmailSave.
  ///
  /// In en, this message translates to:
  /// **'Save and send link'**
  String get changeEmailSave;

  /// No description provided for @changeEmailSame.
  ///
  /// In en, this message translates to:
  /// **'This is already your email'**
  String get changeEmailSame;

  /// No description provided for @changeEmailExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists'**
  String get changeEmailExists;

  /// No description provided for @changeEmailAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'Your email is already verified and can\'t be changed.'**
  String get changeEmailAlreadyVerified;

  /// No description provided for @privacyNothingUnless.
  ///
  /// In en, this message translates to:
  /// **'Nothing leaves this phone unless you make a profile or join a group. Analytics are not collected, and there is no advertising ID and no ads.'**
  String get privacyNothingUnless;

  /// No description provided for @privacyPhoneSignIn.
  ///
  /// In en, this message translates to:
  /// **'An anonymous sign-in when the app starts: an install number, never a name'**
  String get privacyPhoneSignIn;

  /// No description provided for @privacyWithProfile.
  ///
  /// In en, this message translates to:
  /// **'If you make a profile'**
  String get privacyWithProfile;

  /// No description provided for @privacyProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Your name, email and city, and your phone number if you give it'**
  String get privacyProfileDetails;

  /// No description provided for @privacyProfileMail.
  ///
  /// In en, this message translates to:
  /// **'Emails only to that address: to confirm it, and to bring your profile back on a new phone'**
  String get privacyProfileMail;

  /// No description provided for @privacyProfileAttendance.
  ///
  /// In en, this message translates to:
  /// **'Once a day, that you opened the app — which is how your city shows on the globe'**
  String get privacyProfileAttendance;

  /// No description provided for @privacyProfileBackup.
  ///
  /// In en, this message translates to:
  /// **'A weekly backup of your goals, what you recited, your simran and your badges, so a restore can bring them back'**
  String get privacyProfileBackup;

  /// No description provided for @privacyWithGroup.
  ///
  /// In en, this message translates to:
  /// **'If you join a group'**
  String get privacyWithGroup;

  /// No description provided for @privacyGroupCounts.
  ///
  /// In en, this message translates to:
  /// **'Each paath or sitting that counts toward your groups'**
  String get privacyGroupCounts;

  /// No description provided for @privacyGroupName.
  ///
  /// In en, this message translates to:
  /// **'Your name, shown only to the members of your groups'**
  String get privacyGroupName;

  /// No description provided for @privacyGroupToken.
  ///
  /// In en, this message translates to:
  /// **'This phone\'s notification token, language and time zone, for the group\'s notifications'**
  String get privacyGroupToken;

  /// No description provided for @privacyGlobe.
  ///
  /// In en, this message translates to:
  /// **'The globe shows a city and a count, never a name. Nothing is sold or shared with anyone.'**
  String get privacyGlobe;

  /// No description provided for @backupLastLine.
  ///
  /// In en, this message translates to:
  /// **'Last backed up {date}'**
  String backupLastLine(String date);

  /// No description provided for @backupNever.
  ///
  /// In en, this message translates to:
  /// **'Not backed up yet'**
  String get backupNever;

  /// No description provided for @backupStale.
  ///
  /// In en, this message translates to:
  /// **'Not backed up for over two weeks'**
  String get backupStale;

  /// No description provided for @backupNowButton.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNowButton;

  /// No description provided for @backupDone.
  ///
  /// In en, this message translates to:
  /// **'Backed up'**
  String get backupDone;

  /// No description provided for @restoreDataButton.
  ///
  /// In en, this message translates to:
  /// **'Restore my goals and diary'**
  String get restoreDataButton;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This adds your goals and diary from the backup to this phone. Nothing already on this phone is removed.'**
  String get restoreConfirmBody;

  /// No description provided for @restoreAsOf.
  ///
  /// In en, this message translates to:
  /// **'Backup from {date}. Anything after that is not included.'**
  String restoreAsOf(String date);

  /// No description provided for @restoreNothing.
  ///
  /// In en, this message translates to:
  /// **'There is no backup to restore yet'**
  String get restoreNothing;

  /// No description provided for @restoreButton.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreButton;

  /// No description provided for @backupSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupSectionTitle;

  /// No description provided for @sangatMyGroups.
  ///
  /// In en, this message translates to:
  /// **'My groups'**
  String get sangatMyGroups;

  /// No description provided for @sangatBuiltInGroups.
  ///
  /// In en, this message translates to:
  /// **'Join the sangat'**
  String get sangatBuiltInGroups;

  /// No description provided for @sangatEndedHeading.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get sangatEndedHeading;

  /// No description provided for @sangatCreate.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get sangatCreate;

  /// No description provided for @sangatJoinWithCode.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get sangatJoinWithCode;

  /// No description provided for @sangatJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get sangatJoin;

  /// No description provided for @sangatLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get sangatLeave;

  /// No description provided for @sangatCreateNeedsProfile.
  ///
  /// In en, this message translates to:
  /// **'Create your profile to start a group of your own.'**
  String get sangatCreateNeedsProfile;

  /// No description provided for @sangatLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You have {limit} active groups. To start more, write to support@hazri.me.'**
  String sangatLimitReached(int limit);

  /// No description provided for @sangatGroupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get sangatGroupName;

  /// No description provided for @sangatGoalBani.
  ///
  /// In en, this message translates to:
  /// **'Paath of one bani'**
  String get sangatGoalBani;

  /// No description provided for @sangatGoalSimran.
  ///
  /// In en, this message translates to:
  /// **'Naam Simran'**
  String get sangatGoalSimran;

  /// No description provided for @sangatGoalTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get sangatGoalTarget;

  /// No description provided for @sangatGoalEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends on'**
  String get sangatGoalEnds;

  /// No description provided for @sangatGoalSummaryBani.
  ///
  /// In en, this message translates to:
  /// **'{target} {bani} by {date}'**
  String sangatGoalSummaryBani(int target, String bani, String date);

  /// No description provided for @sangatGoalSummarySimran.
  ///
  /// In en, this message translates to:
  /// **'{target} minutes of Naam Simran by {date}'**
  String sangatGoalSummarySimran(int target, String date);

  /// No description provided for @sangatProgress.
  ///
  /// In en, this message translates to:
  /// **'{total} of {target} · {pct}%'**
  String sangatProgress(int total, int target, int pct);

  /// No description provided for @sangatToday.
  ///
  /// In en, this message translates to:
  /// **'{count} today'**
  String sangatToday(int count);

  /// No description provided for @sangatDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String sangatDaysLeft(int days);

  /// No description provided for @sangatEndedOn.
  ///
  /// In en, this message translates to:
  /// **'Ended on {date}'**
  String sangatEndedOn(String date);

  /// No description provided for @sangatMembers.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String sangatMembers(int count);

  /// No description provided for @sangatMoreMembers.
  ///
  /// In en, this message translates to:
  /// **'{count} more members'**
  String sangatMoreMembers(int count);

  /// No description provided for @sangatAnonymousName.
  ///
  /// In en, this message translates to:
  /// **'Sangat member'**
  String get sangatAnonymousName;

  /// No description provided for @sangatCreatorLabel.
  ///
  /// In en, this message translates to:
  /// **'Started this group'**
  String get sangatCreatorLabel;

  /// No description provided for @sangatShareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share invite'**
  String get sangatShareInvite;

  /// No description provided for @sangatInviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Join \"{group}\" on Hazri: {target} {goal} together by {date}. Tap {link} or enter code {code} in the app.'**
  String sangatInviteMessage(
    String group,
    int target,
    String goal,
    String date,
    String link,
    String code,
  );

  /// No description provided for @sangatResetCode.
  ///
  /// In en, this message translates to:
  /// **'Reset invite code'**
  String get sangatResetCode;

  /// No description provided for @sangatPasteCode.
  ///
  /// In en, this message translates to:
  /// **'Paste code'**
  String get sangatPasteCode;

  /// No description provided for @sangatCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'This code isn\'t valid. Ask for a new invite.'**
  String get sangatCodeInvalid;

  /// No description provided for @sangatGroupFull.
  ///
  /// In en, this message translates to:
  /// **'This group is full.'**
  String get sangatGroupFull;

  /// No description provided for @sangatGroupEnded.
  ///
  /// In en, this message translates to:
  /// **'This group has ended.'**
  String get sangatGroupEnded;

  /// No description provided for @sangatChangeEndDate.
  ///
  /// In en, this message translates to:
  /// **'Change end date'**
  String get sangatChangeEndDate;

  /// No description provided for @sangatRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get sangatRemoveMember;

  /// No description provided for @sangatDeleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get sangatDeleteGroup;

  /// No description provided for @sangatReport.
  ///
  /// In en, this message translates to:
  /// **'Report group'**
  String get sangatReport;

  /// No description provided for @sangatReportReasonOffensive.
  ///
  /// In en, this message translates to:
  /// **'Offensive name'**
  String get sangatReportReasonOffensive;

  /// No description provided for @sangatReportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get sangatReportReasonSpam;

  /// No description provided for @sangatReportReasonOffTopic.
  ///
  /// In en, this message translates to:
  /// **'Not about Sikhi'**
  String get sangatReportReasonOffTopic;

  /// No description provided for @sangatReportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get sangatReportReasonOther;

  /// No description provided for @sangatReportSent.
  ///
  /// In en, this message translates to:
  /// **'Thank you. We\'ll look into it.'**
  String get sangatReportSent;

  /// No description provided for @sangatUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String sangatUpdatedAt(String time);

  /// No description provided for @sangatOffline.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the sangat right now'**
  String get sangatOffline;

  /// No description provided for @sangatGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Set the goal'**
  String get sangatGoalTitle;

  /// No description provided for @sangatCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get sangatCreateAction;

  /// No description provided for @sangatGoalOnce.
  ///
  /// In en, this message translates to:
  /// **'The goal can\'t be changed later; only its end date can.'**
  String get sangatGoalOnce;

  /// No description provided for @sangatNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a group name'**
  String get sangatNameRequired;

  /// No description provided for @sangatTargetInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 1,000,000'**
  String get sangatTargetInvalid;

  /// No description provided for @sangatChooseBani.
  ///
  /// In en, this message translates to:
  /// **'Choose a bani'**
  String get sangatChooseBani;

  /// No description provided for @sangatNoGoalYet.
  ///
  /// In en, this message translates to:
  /// **'No goal yet'**
  String get sangatNoGoalYet;

  /// No description provided for @sangatJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a group'**
  String get sangatJoinTitle;

  /// No description provided for @sangatCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get sangatCodeLabel;

  /// No description provided for @sangatLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave {group}? What you contributed stays in its total.'**
  String sangatLeaveConfirm(String group);

  /// No description provided for @sangatDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {group}? This removes it and everything in it.'**
  String sangatDeleteConfirm(String group);

  /// No description provided for @sangatRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the group? What they contributed stays.'**
  String sangatRemoveConfirm(String name);

  /// No description provided for @sangatReportNote.
  ///
  /// In en, this message translates to:
  /// **'A note (optional)'**
  String get sangatReportNote;

  /// No description provided for @sangatReportSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sangatReportSend;

  /// No description provided for @sangatLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get sangatLeft;

  /// No description provided for @sangatYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get sangatYou;

  /// No description provided for @sangatNoGroups.
  ///
  /// In en, this message translates to:
  /// **'You are not in any group yet.'**
  String get sangatNoGroups;

  /// No description provided for @sangatJoinFromInvite.
  ///
  /// In en, this message translates to:
  /// **'You have an invite to a group.'**
  String get sangatJoinFromInvite;

  /// No description provided for @simranLegendLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get simranLegendLive;

  /// No description provided for @globeLiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} live today'**
  String globeLiveCount(int count);

  /// No description provided for @globeStale.
  ///
  /// In en, this message translates to:
  /// **'Last updated {time}'**
  String globeStale(String time);

  /// No description provided for @globeOffline.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the sangat right now'**
  String get globeOffline;

  /// No description provided for @globeProfileBanner.
  ///
  /// In en, this message translates to:
  /// **'Create your profile to see yourself on the globe'**
  String get globeProfileBanner;

  /// No description provided for @appBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Hazri'**
  String get appBarTitle;

  /// No description provided for @todayStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String todayStreakDays(int count);

  /// No description provided for @badgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badgesTitle;

  /// No description provided for @badgesSummary.
  ///
  /// In en, this message translates to:
  /// **'{earned} of 10 earned · Hazri on {count} days'**
  String badgesSummary(int earned, int count);

  /// No description provided for @badgesSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all 10'**
  String get badgesSeeAll;

  /// No description provided for @badgesMenuCount.
  ///
  /// In en, this message translates to:
  /// **'{earned} of 10'**
  String badgesMenuCount(int earned);

  /// No description provided for @badgeEarnedOn.
  ///
  /// In en, this message translates to:
  /// **'Earned {date}'**
  String badgeEarnedOn(String date);

  /// No description provided for @badgeNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get badgeNotYet;

  /// No description provided for @badgeNumber.
  ///
  /// In en, this message translates to:
  /// **'Badge {n} of 10'**
  String badgeNumber(int n);

  /// No description provided for @badgeWhatItMarks.
  ///
  /// In en, this message translates to:
  /// **'What it marks'**
  String get badgeWhatItMarks;

  /// No description provided for @badgeHowEarned.
  ///
  /// In en, this message translates to:
  /// **'How it is earned'**
  String get badgeHowEarned;

  /// No description provided for @badgeEarnedNew.
  ///
  /// In en, this message translates to:
  /// **'New badge'**
  String get badgeEarnedNew;

  /// No description provided for @badgeEarnedYours.
  ///
  /// In en, this message translates to:
  /// **'Your badges'**
  String get badgeEarnedYours;

  /// No description provided for @badgeEarnedDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get badgeEarnedDone;

  /// No description provided for @badgeEarnedSee.
  ///
  /// In en, this message translates to:
  /// **'See all badges'**
  String get badgeEarnedSee;

  /// No description provided for @badgeMarksJigyasu.
  ///
  /// In en, this message translates to:
  /// **'The seeker: the first hazri'**
  String get badgeMarksJigyasu;

  /// No description provided for @badgeMarksShardhalu.
  ///
  /// In en, this message translates to:
  /// **'Coming back with shardha'**
  String get badgeMarksShardhalu;

  /// No description provided for @badgeMarksAbhyasi.
  ///
  /// In en, this message translates to:
  /// **'One who practises: the habit is forming'**
  String get badgeMarksAbhyasi;

  /// No description provided for @badgeMarksNitnemi.
  ///
  /// In en, this message translates to:
  /// **'Keeps the Nitnem'**
  String get badgeMarksNitnemi;

  /// No description provided for @badgeMarksSimrani.
  ///
  /// In en, this message translates to:
  /// **'Settled in Simran'**
  String get badgeMarksSimrani;

  /// No description provided for @badgeMarksPaathi.
  ///
  /// In en, this message translates to:
  /// **'Has read every bani through, Sukhmani Sahib included'**
  String get badgeMarksPaathi;

  /// No description provided for @badgeMarksSevadar.
  ///
  /// In en, this message translates to:
  /// **'Sewa in the sangat: group goals carried to their end'**
  String get badgeMarksSevadar;

  /// No description provided for @badgeMarksGursikh.
  ///
  /// In en, this message translates to:
  /// **'The whole of it held together over months'**
  String get badgeMarksGursikh;

  /// No description provided for @badgeMarksSatsangi.
  ///
  /// In en, this message translates to:
  /// **'Brought others into the sangat'**
  String get badgeMarksSatsangi;

  /// No description provided for @badgeMarksVichari.
  ///
  /// In en, this message translates to:
  /// **'The long road: a year of days'**
  String get badgeMarksVichari;

  /// No description provided for @badgeRuleJigyasu.
  ///
  /// In en, this message translates to:
  /// **'Your first hazri'**
  String get badgeRuleJigyasu;

  /// No description provided for @badgeRuleShardhalu.
  ///
  /// In en, this message translates to:
  /// **'Hazri on 7 days'**
  String get badgeRuleShardhalu;

  /// No description provided for @badgeRuleAbhyasi.
  ///
  /// In en, this message translates to:
  /// **'Hazri on 40 days'**
  String get badgeRuleAbhyasi;

  /// No description provided for @badgeRuleNitnemi.
  ///
  /// In en, this message translates to:
  /// **'The five morning banis on 40 days'**
  String get badgeRuleNitnemi;

  /// No description provided for @badgeRuleSimrani.
  ///
  /// In en, this message translates to:
  /// **'Simran of 5 minutes or more on 108 days'**
  String get badgeRuleSimrani;

  /// No description provided for @badgeRulePaathi.
  ///
  /// In en, this message translates to:
  /// **'Every bani read through once'**
  String get badgeRulePaathi;

  /// No description provided for @badgeRuleSevadar.
  ///
  /// In en, this message translates to:
  /// **'3 sangat goals reached with you'**
  String get badgeRuleSevadar;

  /// No description provided for @badgeRuleGursikh.
  ///
  /// In en, this message translates to:
  /// **'Nitnemi, Simrani, Paathi and hazri on 180 days'**
  String get badgeRuleGursikh;

  /// No description provided for @badgeRuleSatsangi.
  ///
  /// In en, this message translates to:
  /// **'5 people joined groups you created'**
  String get badgeRuleSatsangi;

  /// No description provided for @badgeRuleVichari.
  ///
  /// In en, this message translates to:
  /// **'Hazri on 365 days'**
  String get badgeRuleVichari;

  /// No description provided for @badgeHowJigyasu.
  ///
  /// In en, this message translates to:
  /// **'Mark your hazri once: finish any bani, or sit in Simran for 5 minutes.'**
  String get badgeHowJigyasu;

  /// No description provided for @badgeHowShardhalu.
  ///
  /// In en, this message translates to:
  /// **'Hazri on 7 days. The days need not be in a row.'**
  String get badgeHowShardhalu;

  /// No description provided for @badgeHowAbhyasi.
  ///
  /// In en, this message translates to:
  /// **'Hazri on 40 days. The days need not be in a row.'**
  String get badgeHowAbhyasi;

  /// No description provided for @badgeHowNitnemi.
  ///
  /// In en, this message translates to:
  /// **'{banis}, all five on the same day, on 40 days. The days need not be in a row.'**
  String badgeHowNitnemi(String banis);

  /// No description provided for @badgeHowSimrani.
  ///
  /// In en, this message translates to:
  /// **'A sitting of Simran of 5 minutes or more on 108 days. The days need not be in a row.'**
  String get badgeHowSimrani;

  /// No description provided for @badgeHowPaathi.
  ///
  /// In en, this message translates to:
  /// **'Read or listen to every bani in the app through to the end at least once, Ardas and Sukhmani Sahib included.'**
  String get badgeHowPaathi;

  /// No description provided for @badgeHowSevadar.
  ///
  /// In en, this message translates to:
  /// **'Be part of 3 sangat goals that are reached, with at least one paath of your own in each. Needs a profile.'**
  String get badgeHowSevadar;

  /// No description provided for @badgeHowGursikh.
  ///
  /// In en, this message translates to:
  /// **'Earn Nitnemi, Simrani and Paathi, and hazri on 180 days. The days need not be in a row.'**
  String get badgeHowGursikh;

  /// No description provided for @badgeHowSatsangi.
  ///
  /// In en, this message translates to:
  /// **'5 people join groups you created, each counted once. Needs a profile.'**
  String get badgeHowSatsangi;

  /// No description provided for @badgeHowVichari.
  ///
  /// In en, this message translates to:
  /// **'Hazri on 365 days. The days need not be in a row.'**
  String get badgeHowVichari;

  /// No description provided for @welcomeTitleLead.
  ///
  /// In en, this message translates to:
  /// **'From Amrit Vela to bedtime, mark your hazri to'**
  String get welcomeTitleLead;

  /// No description provided for @welcomeTitleWord.
  ///
  /// In en, this message translates to:
  /// **'Waheguru.'**
  String get welcomeTitleWord;

  /// No description provided for @welcomeAmritVelaTime.
  ///
  /// In en, this message translates to:
  /// **'4:00 AM'**
  String get welcomeAmritVelaTime;

  /// No description provided for @welcomeAmritVela.
  ///
  /// In en, this message translates to:
  /// **'Amrit Vela'**
  String get welcomeAmritVela;

  /// No description provided for @welcomeAmritVelaSub.
  ///
  /// In en, this message translates to:
  /// **'A gentle reminder, {bani} is ready'**
  String welcomeAmritVelaSub(String bani);

  /// No description provided for @welcomeHazriTime.
  ///
  /// In en, this message translates to:
  /// **'5:10 AM'**
  String get welcomeHazriTime;

  /// No description provided for @welcomeHazriSub.
  ///
  /// In en, this message translates to:
  /// **'With {bani}'**
  String welcomeHazriSub(String bani);

  /// No description provided for @welcomeGoalTime.
  ///
  /// In en, this message translates to:
  /// **'6:30 PM'**
  String get welcomeGoalTime;

  /// No description provided for @welcomeGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily goal · 1 of 2 done'**
  String get welcomeGoal;

  /// No description provided for @welcomeGoalSub.
  ///
  /// In en, this message translates to:
  /// **'{bani}, and 11 minutes of Simran'**
  String welcomeGoalSub(String bani);

  /// No description provided for @welcomeSangatTime.
  ///
  /// In en, this message translates to:
  /// **'9:00 PM'**
  String get welcomeSangatTime;

  /// No description provided for @welcomeSangat.
  ///
  /// In en, this message translates to:
  /// **'Your sangat group'**
  String get welcomeSangat;

  /// No description provided for @welcomeSangatSub.
  ///
  /// In en, this message translates to:
  /// **'68 of 101 {bani}, together'**
  String welcomeSangatSub(String bani);

  /// No description provided for @welcomeStreakTime.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get welcomeStreakTime;

  /// No description provided for @welcomeStreak.
  ///
  /// In en, this message translates to:
  /// **'12 days in a row'**
  String get welcomeStreak;

  /// No description provided for @welcomeStreakSub.
  ///
  /// In en, this message translates to:
  /// **'Kept in your diary'**
  String get welcomeStreakSub;

  /// No description provided for @welcomeBegin.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get welcomeBegin;

  /// No description provided for @setupLanguageNote.
  ///
  /// In en, this message translates to:
  /// **'You can change it any time in Settings.'**
  String get setupLanguageNote;

  /// No description provided for @elderModeSetup.
  ///
  /// In en, this message translates to:
  /// **'Larger text and simpler screens'**
  String get elderModeSetup;

  /// No description provided for @sangatSimranMinutesUnit.
  ///
  /// In en, this message translates to:
  /// **'minutes of Naam Simran'**
  String get sangatSimranMinutesUnit;

  /// No description provided for @sangatProgressMinutes.
  ///
  /// In en, this message translates to:
  /// **'{total} of {target} min · {pct}%'**
  String sangatProgressMinutes(int total, int target, int pct);

  /// No description provided for @sangatTodayMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min today'**
  String sangatTodayMinutes(int count);

  /// No description provided for @sangatGoalTargetMinutes.
  ///
  /// In en, this message translates to:
  /// **'Target, in minutes of Naam Simran'**
  String get sangatGoalTargetMinutes;

  /// No description provided for @readerStartAgainNote.
  ///
  /// In en, this message translates to:
  /// **'Start again takes you to the first line and clears where you left off.'**
  String get readerStartAgainNote;

  /// No description provided for @goalPlayNow.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get goalPlayNow;

  /// No description provided for @notifExactAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow on-time reminders'**
  String get notifExactAllow;

  /// No description provided for @playerQueuePosition.
  ///
  /// In en, this message translates to:
  /// **'{slot} · {index} of {count}'**
  String playerQueuePosition(String slot, int index, int count);

  /// No description provided for @sangatCreateSub.
  ///
  /// In en, this message translates to:
  /// **'One goal, an end date'**
  String get sangatCreateSub;

  /// No description provided for @sangatJoinGroupTile.
  ///
  /// In en, this message translates to:
  /// **'Join group'**
  String get sangatJoinGroupTile;

  /// No description provided for @sangatJoinGroupSub.
  ///
  /// In en, this message translates to:
  /// **'With a link or code'**
  String get sangatJoinGroupSub;

  /// No description provided for @sangatTotalOf.
  ///
  /// In en, this message translates to:
  /// **'{total} of {target}'**
  String sangatTotalOf(String total, String target);

  /// No description provided for @sangatTotalOfMinutes.
  ///
  /// In en, this message translates to:
  /// **'{total} of {target} min'**
  String sangatTotalOfMinutes(String total, String target);

  /// No description provided for @sangatOfTarget.
  ///
  /// In en, this message translates to:
  /// **'of {target}'**
  String sangatOfTarget(String target);

  /// No description provided for @sangatOfTargetMinutes.
  ///
  /// In en, this message translates to:
  /// **'of {target} min'**
  String sangatOfTargetMinutes(String target);

  /// No description provided for @sangatBuiltInKind.
  ///
  /// In en, this message translates to:
  /// **'Built-in group'**
  String get sangatBuiltInKind;

  /// No description provided for @sangatGroupMenu.
  ///
  /// In en, this message translates to:
  /// **'Group menu'**
  String get sangatGroupMenu;

  /// No description provided for @sangatThisGoal.
  ///
  /// In en, this message translates to:
  /// **'This goal'**
  String get sangatThisGoal;

  /// No description provided for @sangatDayOf.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {days}'**
  String sangatDayOf(int day, int days);

  /// No description provided for @sangatStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get sangatStarted;

  /// No description provided for @sangatEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get sangatEnds;

  /// No description provided for @sangatEndsNewGoal.
  ///
  /// In en, this message translates to:
  /// **'Ends; new goal starts {date}'**
  String sangatEndsNewGoal(String date);

  /// No description provided for @sangatFigureSangatToday.
  ///
  /// In en, this message translates to:
  /// **'Sangat today'**
  String get sangatFigureSangatToday;

  /// No description provided for @sangatFigureYoursToday.
  ///
  /// In en, this message translates to:
  /// **'Yours today'**
  String get sangatFigureYoursToday;

  /// No description provided for @sangatFigureYoursGoal.
  ///
  /// In en, this message translates to:
  /// **'Yours toward the goal'**
  String get sangatFigureYoursGoal;

  /// No description provided for @sangatMinUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get sangatMinUnit;

  /// No description provided for @sangatSitFor.
  ///
  /// In en, this message translates to:
  /// **'Sit for {paath}'**
  String sangatSitFor(String paath);

  /// No description provided for @sangatMembersHeading.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get sangatMembersHeading;

  /// No description provided for @sangatMembersAtoZ.
  ///
  /// In en, this message translates to:
  /// **'{count} · A to Z'**
  String sangatMembersAtoZ(String count);

  /// No description provided for @sangatAndMore.
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String sangatAndMore(String count);

  /// No description provided for @profileYourTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileYourTitle;

  /// No description provided for @profileStatHazriDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day of Hazri} other{days of Hazri}}'**
  String profileStatHazriDays(num count);

  /// No description provided for @profileStatInARow.
  ///
  /// In en, this message translates to:
  /// **'in a row'**
  String get profileStatInARow;

  /// No description provided for @profileStatBadges.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{badge earned} other{badges earned}}'**
  String profileStatBadges(num count);

  /// No description provided for @profilePhoneNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Phone not provided'**
  String get profilePhoneNotProvided;

  /// No description provided for @profilePrivacyLine.
  ///
  /// In en, this message translates to:
  /// **'Your email is never shown to anyone in the app. Your city is one dot on the Simran globe, and nothing finer.'**
  String get profilePrivacyLine;

  /// No description provided for @profileEditTodayIn.
  ///
  /// In en, this message translates to:
  /// **'Today in {city}'**
  String profileEditTodayIn(String city);

  /// No description provided for @profileEditChangedFrom.
  ///
  /// In en, this message translates to:
  /// **'Changed from {city}'**
  String profileEditChangedFrom(String city);

  /// No description provided for @profileEditSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get profileEditSunrise;

  /// No description provided for @profileEditSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get profileEditSunset;

  /// No description provided for @profileEditCityHelp.
  ///
  /// In en, this message translates to:
  /// **'Your sunrise times on Today and your dot on the Simran globe follow it.'**
  String get profileEditCityHelp;

  /// No description provided for @profileEditNameHelp.
  ///
  /// In en, this message translates to:
  /// **'2 to 50 letters. Spaces, full stops, apostrophes and hyphens are fine.'**
  String get profileEditNameHelp;

  /// No description provided for @profileEditEmailHelp.
  ///
  /// In en, this message translates to:
  /// **'A new email takes over only once you confirm it from the link we send.'**
  String get profileEditEmailHelp;

  /// No description provided for @notifDiagProbeHeading.
  ///
  /// In en, this message translates to:
  /// **'Alarm test'**
  String get notifDiagProbeHeading;

  /// No description provided for @notifDiagProbeExact.
  ///
  /// In en, this message translates to:
  /// **'Android alarm'**
  String get notifDiagProbeExact;

  /// No description provided for @notifDiagProbeClock.
  ///
  /// In en, this message translates to:
  /// **'Alarm-clock alarm'**
  String get notifDiagProbeClock;

  /// No description provided for @notifDiagProbeButton.
  ///
  /// In en, this message translates to:
  /// **'Test two alarms in about a minute'**
  String get notifDiagProbeButton;

  /// No description provided for @notifDiagProbeNever.
  ///
  /// In en, this message translates to:
  /// **'Not tried yet'**
  String get notifDiagProbeNever;

  /// No description provided for @notifDiagProbeWaiting.
  ///
  /// In en, this message translates to:
  /// **'Set for {set} · not arrived yet'**
  String notifDiagProbeWaiting(String set);

  /// No description provided for @notifDiagProbeArrived.
  ///
  /// In en, this message translates to:
  /// **'Set for {set} · arrived {arrived}'**
  String notifDiagProbeArrived(String set, String arrived);

  /// No description provided for @notifDiagProbeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hazri alarm test'**
  String get notifDiagProbeTitle;

  /// No description provided for @notifDiagBatteryAllow.
  ///
  /// In en, this message translates to:
  /// **'Let Hazri run in the background'**
  String get notifDiagBatteryAllow;

  /// No description provided for @notifDiagRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get notifDiagRefresh;

  /// No description provided for @globeTipYou.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get globeTipYou;

  /// No description provided for @globeTipLive.
  ///
  /// In en, this message translates to:
  /// **'{count} live today'**
  String globeTipLive(int count);

  /// No description provided for @globeTipHere.
  ///
  /// In en, this message translates to:
  /// **'{count} here today'**
  String globeTipHere(int count);

  /// No description provided for @sangatGlobeKey.
  ///
  /// In en, this message translates to:
  /// **'You · {today} today · {notYet} not yet · {cities} cities'**
  String sangatGlobeKey(String today, String notYet, String cities);

  /// No description provided for @sangatArrivals.
  ///
  /// In en, this message translates to:
  /// **'{count} paath arrived in the last hour'**
  String sangatArrivals(String count);

  /// No description provided for @sangatArrivalsMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes of Naam Simran in the last hour'**
  String sangatArrivalsMinutes(String minutes);

  /// No description provided for @sangatGlobeTipToday.
  ///
  /// In en, this message translates to:
  /// **'{count} today'**
  String sangatGlobeTipToday(int count);

  /// No description provided for @sangatGlobeTipNotYet.
  ///
  /// In en, this message translates to:
  /// **'{count} not yet'**
  String sangatGlobeTipNotYet(int count);

  /// No description provided for @privacyGroupGlobe.
  ///
  /// In en, this message translates to:
  /// **'A group\'s globe shows how many of its members are in each city, never their names. In a small group, a city with one member can point to that member.'**
  String get privacyGroupGlobe;

  /// No description provided for @quizTitle.
  ///
  /// In en, this message translates to:
  /// **'Gurmat Quiz'**
  String get quizTitle;

  /// No description provided for @quizDidYouKnow.
  ///
  /// In en, this message translates to:
  /// **'Did you know?'**
  String get quizDidYouKnow;

  /// No description provided for @quizKnowMore.
  ///
  /// In en, this message translates to:
  /// **'Know more'**
  String get quizKnowMore;

  /// No description provided for @quizTakeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Take the quiz'**
  String get quizTakeQuiz;

  /// No description provided for @quizQuestionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {n} of {total}'**
  String quizQuestionOf(int n, int total);

  /// No description provided for @quizNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get quizNext;

  /// No description provided for @quizNextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next question'**
  String get quizNextQuestion;

  /// No description provided for @quizTheAnswerIs.
  ///
  /// In en, this message translates to:
  /// **'The answer is {answer}'**
  String quizTheAnswerIs(String answer);

  /// No description provided for @quizEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get quizEasy;

  /// No description provided for @quizMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get quizMedium;

  /// No description provided for @quizHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get quizHard;

  /// No description provided for @quizTenPoints.
  ///
  /// In en, this message translates to:
  /// **'10 points'**
  String get quizTenPoints;

  /// No description provided for @quizSeeResult.
  ///
  /// In en, this message translates to:
  /// **'See your result'**
  String get quizSeeResult;

  /// No description provided for @quizRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get quizRight;

  /// No description provided for @quizWrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite'**
  String get quizWrong;

  /// No description provided for @quizLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the quiz?'**
  String get quizLeaveTitle;

  /// No description provided for @quizLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'This quiz won\'t count.'**
  String get quizLeaveBody;

  /// No description provided for @quizKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get quizKeepGoing;

  /// No description provided for @quizLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get quizLeave;

  /// No description provided for @quizEnglishOnly.
  ///
  /// In en, this message translates to:
  /// **'The questions are in English for now.'**
  String get quizEnglishOnly;

  /// No description provided for @quizStarting.
  ///
  /// In en, this message translates to:
  /// **'Getting your questions…'**
  String get quizStarting;

  /// No description provided for @quizResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Your answers'**
  String get quizResultTitle;

  /// No description provided for @quizPointsEarned.
  ///
  /// In en, this message translates to:
  /// **'+{points} points'**
  String quizPointsEarned(int points);

  /// No description provided for @quizPointsNeedConnection.
  ///
  /// In en, this message translates to:
  /// **'Points need a connection'**
  String get quizPointsNeedConnection;

  /// No description provided for @quizDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve taken a lot of quizzes today. Come back tomorrow.'**
  String get quizDailyLimit;

  /// No description provided for @quizMakeProfileToEarn.
  ///
  /// In en, this message translates to:
  /// **'Make a profile to earn points and join the leaderboard'**
  String get quizMakeProfileToEarn;

  /// No description provided for @quizShareChallenge.
  ///
  /// In en, this message translates to:
  /// **'Can your family beat {score} out of 5?'**
  String quizShareChallenge(int score);

  /// No description provided for @quizShareEventLine.
  ///
  /// In en, this message translates to:
  /// **'On {topic}\'s {label}, share the quiz and learn the story together.'**
  String quizShareEventLine(String topic, String label);

  /// No description provided for @quizShareLine.
  ///
  /// In en, this message translates to:
  /// **'Share the quiz and learn together.'**
  String get quizShareLine;

  /// No description provided for @quizShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share the quiz'**
  String get quizShareButton;

  /// No description provided for @quizShareBand.
  ///
  /// In en, this message translates to:
  /// **'Take the same quiz · Free in the Hazri app'**
  String get quizShareBand;

  /// No description provided for @quizShareMessage.
  ///
  /// In en, this message translates to:
  /// **'I got {score} out of 5 in the {topic} quiz on Hazri. Can you beat it? {link}'**
  String quizShareMessage(int score, String topic, String link);

  /// No description provided for @quizShareYourScore.
  ///
  /// In en, this message translates to:
  /// **'{score} out of 5'**
  String quizShareYourScore(int score);

  /// No description provided for @quizSeeLeaderboardPlace.
  ///
  /// In en, this message translates to:
  /// **'See the leaderboard · you are #{place}'**
  String quizSeeLeaderboardPlace(int place);

  /// No description provided for @quizSeeLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'See the leaderboard'**
  String get quizSeeLeaderboard;

  /// No description provided for @quizLeaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get quizLeaderboardTitle;

  /// No description provided for @quizPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get quizPeriodToday;

  /// No description provided for @quizPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get quizPeriodWeek;

  /// No description provided for @quizPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get quizPeriodMonth;

  /// No description provided for @quizEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get quizEveryone;

  /// No description provided for @quizYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get quizYou;

  /// No description provided for @quizPlayedToday.
  ///
  /// In en, this message translates to:
  /// **'Top 20 · {count} played today · resets at midnight IST'**
  String quizPlayedToday(int count);

  /// No description provided for @quizPlayedWeek.
  ///
  /// In en, this message translates to:
  /// **'Top 20 · {count} played this week · resets Monday at midnight IST'**
  String quizPlayedWeek(int count);

  /// No description provided for @quizPlayedMonth.
  ///
  /// In en, this message translates to:
  /// **'Top 20 · {count} played this month · resets on the 1st at midnight IST'**
  String quizPlayedMonth(int count);

  /// No description provided for @quizBoardStale.
  ///
  /// In en, this message translates to:
  /// **'Not updated · no connection'**
  String get quizBoardStale;

  /// No description provided for @quizBoardOffline.
  ///
  /// In en, this message translates to:
  /// **'The leaderboard needs a connection.'**
  String get quizBoardOffline;

  /// No description provided for @quizBoardEmptyToday.
  ///
  /// In en, this message translates to:
  /// **'Nobody has played this one today yet. Today\'s board starts again at midnight IST; earlier quizzes are on the week\'s and the month\'s.'**
  String get quizBoardEmptyToday;

  /// No description provided for @quizBoardEmptyWeek.
  ///
  /// In en, this message translates to:
  /// **'Nobody has played this one this week yet. Earlier quizzes are on the month\'s board.'**
  String get quizBoardEmptyWeek;

  /// No description provided for @quizSeeWeek.
  ///
  /// In en, this message translates to:
  /// **'See this week'**
  String get quizSeeWeek;

  /// No description provided for @quizSeeMonth.
  ///
  /// In en, this message translates to:
  /// **'See this month'**
  String get quizSeeMonth;

  /// No description provided for @quizBoardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody has scored yet. Be the first.'**
  String get quizBoardEmpty;

  /// No description provided for @quizProfileCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Make a profile to be on the leaderboard'**
  String get quizProfileCardTitle;

  /// No description provided for @quizProfileCardBody.
  ///
  /// In en, this message translates to:
  /// **'Your quiz points count from the day you make one. Just a name and your city.'**
  String get quizProfileCardBody;

  /// No description provided for @quizMakeProfile.
  ///
  /// In en, this message translates to:
  /// **'Make a profile'**
  String get quizMakeProfile;

  /// No description provided for @quizMakeProfileHeader.
  ///
  /// In en, this message translates to:
  /// **'Make a profile to earn points'**
  String get quizMakeProfileHeader;

  /// No description provided for @quizComingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up on the calendar'**
  String get quizComingUp;

  /// No description provided for @quizStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get quizStart;

  /// No description provided for @quizFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured categories'**
  String get quizFeatured;

  /// No description provided for @quizCatAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get quizCatAll;

  /// No description provided for @quizCatGurus.
  ///
  /// In en, this message translates to:
  /// **'Gurus'**
  String get quizCatGurus;

  /// No description provided for @quizCatGurdwaras.
  ///
  /// In en, this message translates to:
  /// **'Gurdwaras'**
  String get quizCatGurdwaras;

  /// No description provided for @quizCatBanis.
  ///
  /// In en, this message translates to:
  /// **'Banis'**
  String get quizCatBanis;

  /// No description provided for @quizCatHeroes.
  ///
  /// In en, this message translates to:
  /// **'Heroes'**
  String get quizCatHeroes;

  /// No description provided for @quizCatCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get quizCatCulture;

  /// No description provided for @quizCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 quiz} other{{count} quizzes}}'**
  String quizCount(int count);

  /// No description provided for @quizRowLine.
  ///
  /// In en, this message translates to:
  /// **'5 random questions · {points} pts so far'**
  String quizRowLine(int points);

  /// No description provided for @quizRowLineNoProfile.
  ///
  /// In en, this message translates to:
  /// **'5 random questions'**
  String get quizRowLineNoProfile;

  /// No description provided for @quizAllQuizzes.
  ///
  /// In en, this message translates to:
  /// **'All quizzes'**
  String get quizAllQuizzes;

  /// No description provided for @quizPickAnother.
  ///
  /// In en, this message translates to:
  /// **'Or pick another'**
  String get quizPickAnother;

  /// No description provided for @quizCardLine.
  ///
  /// In en, this message translates to:
  /// **'5 questions · 10 points each'**
  String get quizCardLine;

  /// No description provided for @quizCardLineNoProfile.
  ///
  /// In en, this message translates to:
  /// **'5 questions · plays on this phone'**
  String get quizCardLineNoProfile;

  /// No description provided for @quizPointsToday.
  ///
  /// In en, this message translates to:
  /// **'+{points} today'**
  String quizPointsToday(int points);

  /// No description provided for @quizPointsShort.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String quizPointsShort(int points);

  /// No description provided for @quizYourNumbers.
  ///
  /// In en, this message translates to:
  /// **'Your quiz'**
  String get quizYourNumbers;

  /// No description provided for @quizPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get quizPointsLabel;

  /// No description provided for @quizPlaceToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get quizPlaceToday;

  /// No description provided for @quizPlaceWeek.
  ///
  /// In en, this message translates to:
  /// **'this week'**
  String get quizPlaceWeek;

  /// No description provided for @quizPlaceMonth.
  ///
  /// In en, this message translates to:
  /// **'this month'**
  String get quizPlaceMonth;

  /// No description provided for @quizMonthTotal.
  ///
  /// In en, this message translates to:
  /// **'{points} points'**
  String quizMonthTotal(int points);

  /// No description provided for @quizEmpty.
  ///
  /// In en, this message translates to:
  /// **'The quiz is not on this phone yet.'**
  String get quizEmpty;

  /// No description provided for @privacyProfileQuiz.
  ///
  /// In en, this message translates to:
  /// **'When you take a Gurmat Quiz online: its topic and your five answers, scored on the server. Without a profile the quiz stays on this phone and sends nothing'**
  String get privacyProfileQuiz;

  /// No description provided for @privacyProfileLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'On the quiz leaderboards, which every Hazri user can see: your first name, the first letter of your last name, your city and your quiz points'**
  String get privacyProfileLeaderboard;

  /// No description provided for @sangatJoinedChip.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get sangatJoinedChip;

  /// No description provided for @goalShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all {count}'**
  String goalShowAll(int count);

  /// No description provided for @goalShowFewer.
  ///
  /// In en, this message translates to:
  /// **'Show fewer'**
  String get goalShowFewer;

  /// No description provided for @goalDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{count} done'**
  String goalDoneCount(int count);

  /// No description provided for @goalNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get goalNow;

  /// No description provided for @goalMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get goalMissed;

  /// No description provided for @goalNextLine.
  ///
  /// In en, this message translates to:
  /// **'Next: {name} at {time}'**
  String goalNextLine(String name, String time);

  /// No description provided for @nitnemGoalsCount.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} today'**
  String nitnemGoalsCount(int done, int total);

  /// No description provided for @nitnemGoalsChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get nitnemGoalsChange;

  /// No description provided for @slotAnyTime.
  ///
  /// In en, this message translates to:
  /// **'Any time of day'**
  String get slotAnyTime;

  /// No description provided for @privacyAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get privacyAccountTitle;

  /// No description provided for @privacyDeleteHow.
  ///
  /// In en, this message translates to:
  /// **'Opens hazri.me, where you ask for it by email. Your diary stays on this phone.'**
  String get privacyDeleteHow;

  /// No description provided for @privacyDeleteNoBrowser.
  ///
  /// In en, this message translates to:
  /// **'Could not open a browser. The page is hazri.me/delete-account'**
  String get privacyDeleteNoBrowser;
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
