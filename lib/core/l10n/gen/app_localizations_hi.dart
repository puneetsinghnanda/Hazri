// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class LHi extends L {
  LHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'हाज़िरी';

  @override
  String get appNameNative => 'ਹਾਜ਼ਰੀ';

  @override
  String get tagline => 'आपका रोज़ाना नितनेम — हमेशा अंग संग';

  @override
  String get actionContinue => 'आगे बढ़ें';

  @override
  String get actionNext => 'आगे';

  @override
  String get actionBack => 'पीछे';

  @override
  String get actionSkip => 'छोड़ें';

  @override
  String get actionSave => 'सहेजें';

  @override
  String get actionCancel => 'रद्द करें';

  @override
  String get actionDone => 'हो गया';

  @override
  String get actionChange => 'बदलें';

  @override
  String get actionClose => 'बंद करें';

  @override
  String get actionAllow => 'अनुमति दें';

  @override
  String get actionNotNow => 'अभी नहीं';

  @override
  String get actionDownload => 'डाउनलोड';

  @override
  String get actionRemove => 'हटाएँ';

  @override
  String get actionEdit => 'बदलें';

  @override
  String get actionDelete => 'मिटाएँ';

  @override
  String get actionPause => 'रोकें';

  @override
  String get actionResume => 'फिर चालू';

  @override
  String get actionShowMore => 'और देखें';

  @override
  String get actionRead => 'पढ़ें';

  @override
  String get actionListen => 'सुनें';

  @override
  String get actionShareCard => 'कार्ड शेयर करें';

  @override
  String get actionStart => 'शुरू करें';

  @override
  String get actionOpenReader => 'पाठ खोलें';

  @override
  String get actionGotIt => 'समझ गया';

  @override
  String get actionRetry => 'फिर कोशिश करें';

  @override
  String get on => 'चालू';

  @override
  String get off => 'बंद';

  @override
  String get today => 'आज';

  @override
  String get tomorrow => 'कल';

  @override
  String get yesterday => 'बीता कल';

  @override
  String minutes(int count) {
    return '$count मिनट';
  }

  @override
  String minutesLeft(int count) {
    return '$count मिनट बाकी';
  }

  @override
  String nOfM(int n, int m) {
    return '$m में से $n';
  }

  @override
  String get navToday => 'आज';

  @override
  String get navNitnem => 'नितनेम';

  @override
  String get navSimran => 'सिमरन';

  @override
  String get navDiary => 'डायरी';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get slotAmritVela => 'अमृत वेला';

  @override
  String get slotEvening => 'शाम';

  @override
  String get slotBedtime => 'सोने से पहले';

  @override
  String get slotMorning => 'सुबह';

  @override
  String get slotMoreBanis => 'और बाणियाँ';

  @override
  String get chipWorksOffline => 'बिना इंटरनेट चलती है';

  @override
  String get chipNoLogin => 'कोई लॉगिन नहीं';

  @override
  String get chipNoAdsOnGurbani => 'गुरबाणी पर कोई विज्ञापन नहीं';

  @override
  String get introTitle1 => 'आपका नितनेम, हमेशा अंग संग';

  @override
  String get introBody1 =>
      'सातों नितनेम की बाणियाँ, रोज़ाना 5 मिनट का सिमरन, और गुरपुरब की याद। नितनेम की याद आपके शहर के सूर्योदय-सूर्यास्त के अनुसार आती है।';

  @override
  String get introTitle2 => 'पाठ के साथ-साथ पढ़ें';

  @override
  String get introBody2 =>
      'जो पंक्ति पढ़ी जा रही है वह रोशन होती है और पन्ना पाठी की आवाज़ के साथ चलता है। ऐप छोटा करें या फ़ोन लॉक करें — पाठ चलता रहता है।';

  @override
  String get introTitle3 => 'आपकी भाषा में, आपकी रफ़्तार से';

  @override
  String get introBody3 =>
      'गुरबाणी गुरमुखी, हिन्दी या रोमन में पढ़ें, साथ में पंजाबी, हिन्दी या अंग्रेज़ी में सरल अर्थ। बड़े अक्षर वाला ढंग सब कुछ बड़ा कर देता है।';

  @override
  String get introGetStarted => 'शुरू करें';

  @override
  String get introPhoneLocked => 'फ़ोन लॉक है';

  @override
  String get introPaathKeepsPlaying => 'पाठ चलता रहता है';

  @override
  String get introMeaningsIn => 'अर्थ: ਪੰਜਾਬੀ · हिन्दी · English';

  @override
  String introBanisCount(int count) {
    return '$count बाणियाँ';
  }

  @override
  String get introAtSunset => 'सूर्यास्त पर';

  @override
  String get introBeforeSleep => 'सोने से पहले';

  @override
  String get setupLanguageTitle => 'अपनी भाषा चुनें';

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
  String get setupReadingTitle => 'आप गुरबाणी कैसे पढ़ना पसंद करते हैं?';

  @override
  String get scriptGurmukhi => 'गुरमुखी';

  @override
  String get scriptDevanagari => 'देवनागरी';

  @override
  String get scriptRoman => 'रोमन';

  @override
  String get textSize => 'अक्षरों का आकार';

  @override
  String get textSizeLarge => 'बड़ा';

  @override
  String get elderMode => 'बड़े अक्षर';

  @override
  String get elderModeSub => 'बहुत बड़े अक्षर और बड़े बटन';

  @override
  String get versionsNote =>
      'बाणियों के रूप एसजीपीसी रहित मर्यादा के अनुसार हैं';

  @override
  String get setupRemindersTitle => 'हम आपको कब याद दिलाएँ?';

  @override
  String get setupRemindersBody =>
      'अपने-आप वाला ढंग आपके शहर के सूर्योदय-सूर्यास्त के अनुसार चलता है। अपना समय चुनने या याद बंद करने के लिए किसी भी समय पर टैप करें।';

  @override
  String get reminderAuto => 'अपने-आप';

  @override
  String get reminderMyTime => 'मेरा समय';

  @override
  String get reminderOff => 'याद बंद';

  @override
  String get reminderAutoBeforeSunrise => 'अपने-आप · सूर्योदय से पहले';

  @override
  String get reminderAutoAtSunset => 'अपने-आप · सूर्यास्त पर';

  @override
  String get reminderAutoFollowsSunrise => 'अपने-आप · सूर्योदय के अनुसार';

  @override
  String get reminderEveningBefore => 'एक दिन पहले शाम को';

  @override
  String get reminderGurpurabDays => 'गुरपुरब के दिन';

  @override
  String get reminderDailySimran => 'रोज़ाना सिमरन';

  @override
  String get allowOnTimeTitle => 'समय पर याद की अनुमति दें';

  @override
  String get allowOnTimeBody =>
      'एंड्रॉइड एक बार पूछता है, ताकि अमृत वेला की याद ठीक मिनट पर आए।';

  @override
  String get allowOnTimeGranted => 'समय पर याद की अनुमति है';

  @override
  String get allowOnTimeDenied => 'अभी नहीं — याद कुछ मिनट देर से आ सकती है';

  @override
  String get notificationRationale =>
      'याद दिखाने के लिए अनुमति चाहिए। और कुछ कभी नहीं भेजा जाता।';

  @override
  String usingCityForSun(String city) {
    return 'सूर्योदय-सूर्यास्त के लिए $city का उपयोग हो रहा है';
  }

  @override
  String get beginMyNitnem => 'मेरा नितनेम शुरू करें';

  @override
  String get audioNotInBuild => 'इस बाणी की आवाज़ अभी इस बिल्ड में नहीं है';

  @override
  String get audioNotInBuildSub =>
      'जपु जी साहिब का पाठ मौजूद है। बाकी बाणियों की रिकॉर्डिंग तैयार होने पर आएँगी।';

  @override
  String reminderSheetTitle(String bani) {
    return '$bani की याद';
  }

  @override
  String get reminderSheetSameTime => 'हर रोज़ वही समय';

  @override
  String reminderSheetAtSunsetToday(String time) {
    return 'सूर्यास्त पर · आज $time';
  }

  @override
  String reminderSheetBeforeSunriseToday(String time) {
    return 'सूर्योदय से पहले · आज $time';
  }

  @override
  String get reminderSheetRepeat => 'दोहराएँ';

  @override
  String get reminderSheetShowInMyDay => 'मेरे दिन में दिखाएँ';

  @override
  String get reminderSheetTurnOff => 'यह याद बंद करें';

  @override
  String get dayMon => 'सो';

  @override
  String get dayTue => 'मं';

  @override
  String get dayWed => 'बु';

  @override
  String get dayThu => 'गु';

  @override
  String get dayFri => 'शु';

  @override
  String get daySat => 'श';

  @override
  String get daySun => 'र';

  @override
  String get greeting => 'सत श्री अकाल जी';

  @override
  String get ctaStartNitnem => 'नितनेम शुरू करें';

  @override
  String ctaContinueBani(String bani) {
    return '$bani जारी रखें';
  }

  @override
  String ctaStartBani(String bani) {
    return '$bani शुरू करें';
  }

  @override
  String get ctaAllDone => 'आज का नितनेम पूरा';

  @override
  String arcBaniInProgress(String bani) {
    return '$bani चल रहा है';
  }

  @override
  String get arcMorningComplete => 'सुबह का नितनेम पूरा';

  @override
  String arcBaniAt(String bani, String time) {
    return '$bani $time बजे';
  }

  @override
  String get arcNothingYet => 'आज अभी कुछ शुरू नहीं हुआ';

  @override
  String simranTileProgress(int done, int total) {
    return '$total में से $done मिनट';
  }

  @override
  String get simranTileDone => 'आज हो गया ✓';

  @override
  String get gurpurabTileToday => 'आज · गुरपुरब';

  @override
  String get gurpurabTileTomorrow => 'कल · गुरपुरब';

  @override
  String get gurpurabTileUpcoming => 'गुरपुरब';

  @override
  String get helpSheetTitle => 'हाज़िरी कैसे काम करती है';

  @override
  String get helpTip1 =>
      'आज वाले पन्ने पर नितनेम शुरू करें दबाएँ — पाठ वहीं से खुलेगा जहाँ छोड़ा था।';

  @override
  String get helpTip2 =>
      'पाठ में ਅ / अ / A से लिपि बदलें और Aa से अक्षरों का आकार, अर्थ और विश्राम खोलें।';

  @override
  String get helpTip3 =>
      'याद आपके शहर के सूर्योदय-सूर्यास्त के अनुसार, या आपके चुने समय पर आती है।';

  @override
  String get helpAboutLink => 'बारे में और आभार';

  @override
  String get nitnemTitle => 'नितनेम';

  @override
  String get nitnemVersionLine => 'एसजीपीसी वाला रूप';

  @override
  String get nitnemAudioSavedOffline => 'आवाज़ फ़ोन में सहेजी है';

  @override
  String get nitnemAudioNotAvailable => 'इस बिल्ड में आवाज़ नहीं';

  @override
  String get nitnemPlayAll => 'सभी चलाएँ';

  @override
  String nitnemSectionSummary(int count, int minutes) {
    return '$count बाणियाँ · लगभग $minutes मिनट';
  }

  @override
  String nitnemYourTime(String time) {
    return 'आपका समय · $time';
  }

  @override
  String nitnemAtSunset(String time) {
    return 'सूर्यास्त पर · $time';
  }

  @override
  String nitnemResumeAt(String position) {
    return '$position तक';
  }

  @override
  String nitnemLineOf(int line, int total) {
    return 'पंक्ति $line / $total';
  }

  @override
  String get goalsSummaryCard => 'मेरे पाठ के संकल्प';

  @override
  String goalsSummaryLine(int done, int total) {
    return '$total में से $done आज पूरे';
  }

  @override
  String get goalsSetOne => 'पाठ का संकल्प रखें';

  @override
  String get baniNotInBuild => 'यह बाणी अभी इस बिल्ड में नहीं है';

  @override
  String get baniNotInBuildBody =>
      'हाज़िरी में पूरा जपु जी साहिब मौजूद है। बाकी बाणियाँ पाठ की जाँच के बाद आएँगी।';

  @override
  String get readerTextSettings => 'अक्षर सेटिंग';

  @override
  String get readerShowMeanings => 'अर्थ दिखाएँ';

  @override
  String get readerMeaningLanguage => 'अर्थों की भाषा';

  @override
  String get readerRomanUnder => 'गुरमुखी के नीचे रोमन';

  @override
  String get readerPauseMarks => 'विश्राम';

  @override
  String get readerPauseMarksSub => 'छोटे और बड़े विश्राम रंग में';

  @override
  String get readerLarivaar => 'लड़ीवार';

  @override
  String get readerLarivaarSub => 'शब्द जुड़े हुए, जैसे सरूप में';

  @override
  String get readerKeepScreenOn => 'पढ़ते समय स्क्रीन चालू रखें';

  @override
  String get readerFollowAudio => 'आवाज़ के साथ चलें';

  @override
  String get readerFollowAudioSub => 'पंक्ति रोशन करें और पाठ के साथ चलें';

  @override
  String get readerShortPause => 'छोटा विश्राम';

  @override
  String get readerLongPause => 'बड़ा विश्राम';

  @override
  String readerMeaningLabel(String language) {
    return 'अर्थ: $language';
  }

  @override
  String readerCommentaryExpand(String source) {
    return 'टीका ($source)';
  }

  @override
  String get readerCommentaryNote =>
      'फ़रीदकोट वाला टीका — ब्रज/साधुक्कड़ी हिन्दी का टीका, देवनागरी में बदला गया। यह पंक्ति का अनुवाद नहीं, व्याख्या है।';

  @override
  String readerCompleteTitle(String bani) {
    return '$bani पूरा हुआ';
  }

  @override
  String readerCompleteNext(String bani) {
    return 'आगे: $bani';
  }

  @override
  String get readerCompleteBackToNitnem => 'नितनेम पर वापस';

  @override
  String readerBackToPaath(int line) {
    return 'पाठ पर वापस · पंक्ति $line';
  }

  @override
  String get readerAutoScrollPaused => 'अपने-आप चलना रुका';

  @override
  String get readerFollowingAudio => 'आवाज़ के साथ चल रहा';

  @override
  String readerSourceCredit(String text, String meanings) {
    return 'पाठ: $text · अर्थ: $meanings';
  }

  @override
  String get langPunjabi => 'पंजाबी';

  @override
  String get langHindi => 'हिन्दी';

  @override
  String get langEnglish => 'अंग्रेज़ी';

  @override
  String get playerNowPlaying => 'अभी चल रहा';

  @override
  String get playerMorningNitnem => 'सुबह का नितनेम';

  @override
  String get playerUpNext => 'आगे';

  @override
  String get playerSpeed => 'रफ़्तार';

  @override
  String get playerSleepTimer => 'सोने का समय';

  @override
  String get diaryTitle => 'नितनेम डायरी';

  @override
  String diaryStreakDays(int count) {
    return 'लगातार $count दिन';
  }

  @override
  String get diaryStreakOne => 'लगातार 1 दिन';

  @override
  String get diaryStreakNone => 'जब मन करे शुरू करें';

  @override
  String get diaryGentleStreak => 'एक नरम लड़ी';

  @override
  String diaryGrace(int count) {
    return 'एक दिन छूट गया? रियायती दिन लड़ी बनाए रखते हैं। इस महीने $count बाकी हैं।';
  }

  @override
  String get diaryGraceLabel => 'रियायत';

  @override
  String get diaryFooter =>
      'इसी फ़ोन में रहता है। आपके गूगल खाते में बैकअप होता है।';

  @override
  String diaryTickTitle(String date) {
    return '$date';
  }

  @override
  String get diaryTickHint => 'इस दिन जो कुछ पूरा किया, उस पर निशान लगाएँ।';

  @override
  String get diaryTickTooOld => 'केवल आज और पिछले 7 दिन बदले जा सकते हैं।';

  @override
  String get diaryStatJapji => 'जपुजी';

  @override
  String get diaryStatRehras => 'रहरासि';

  @override
  String get diaryStatSohila => 'सोहिला';

  @override
  String get diaryStatSimran => 'सिमरन';

  @override
  String get simranTitle => 'रोज़ाना सिमरन';

  @override
  String get simranSubtitle => '5 शांत मिनट नाम सिमरन';

  @override
  String get simranWaheguru => 'वाहिगुरू';

  @override
  String simranLeftOf(String total) {
    return '$total में से बाकी';
  }

  @override
  String get simranEnd => 'समाप्त';

  @override
  String get simranBegin => 'शुरू करें';

  @override
  String simranRecent(int done, int total) {
    return 'पिछले $total दिनों में से $done दिन किया';
  }

  @override
  String get simranLoggedInDiary => 'डायरी में दर्ज';

  @override
  String get simranCompleteToast => 'सिमरन पूरा — डायरी में दर्ज हो गया';

  @override
  String get gurpurabTitle => 'गुरपुरब कैलेंडर';

  @override
  String get gurpurabTodayNanakshahi => 'आज · नानकशाही';

  @override
  String get gurpurabRemindersLine => 'हर दिन से एक शाम पहले और उस सुबह याद';

  @override
  String get gurpurabThisWeek => 'इस हफ़्ते';

  @override
  String get gurpurabComingUp => 'आने वाले';

  @override
  String get gurpurabFooter =>
      'तारीख़ें एसजीपीसी के कैलेंडर के अनुसार हैं। ये ऐप के साथ आती हैं और साल में एक बार बदलती हैं।';

  @override
  String get gurpurabNoData => 'इस तारीख़ के लिए कैलेंडर इस बिल्ड में नहीं है';

  @override
  String gurpurabNoDataBody(String from, String to) {
    return 'हाज़िरी में जंत्री का उतना हिस्सा है जितना मिला ($from से $to)। बाकी ऐप अपडेट में आएगा।';
  }

  @override
  String get gurpurabFilterAll => 'सभी दिन';

  @override
  String get gurpurabFilterGurpurabsOnly => 'केवल गुरपुरब';

  @override
  String get gurpurabNoneUpcoming => 'अगले 90 दिनों में कोई दिवस नहीं';

  @override
  String get goalsTitle => 'मेरे संकल्प';

  @override
  String goalsSubtitle(int done, int total) {
    return '$total में से $done आज पूरे';
  }

  @override
  String get goalsAdd => 'पाठ का संकल्प जोड़ें';

  @override
  String get goalsFooter =>
      'संकल्प, गिनती और याद इसी फ़ोन में रहते हैं और आपकी डायरी में दिखते हैं।';

  @override
  String get goalsEmpty =>
      'अभी कोई संकल्प नहीं। संकल्प अतिरिक्त पाठ जारी रखने का एक शांत ढंग है।';

  @override
  String get goalRuleOnce => 'दिन में एक बार';

  @override
  String goalRuleTimes(int count) {
    return 'दिन में $count बार';
  }

  @override
  String goalRuleForDays(int days, int count) {
    return '$days दिनों के लिए · रोज़ $count अतिरिक्त पाठ';
  }

  @override
  String goalRuleUntil(String date) {
    return '$date तक';
  }

  @override
  String get goalStatusDone => 'आज हो गया';

  @override
  String goalStatusProgress(int done, int total) {
    return 'आज $total में से $done';
  }

  @override
  String goalStatusDay(int day, int total) {
    return 'दिन $day / $total · बाकी';
  }

  @override
  String get goalStatusComplete => 'संकल्प पूरा हुआ';

  @override
  String get goalFieldBani => 'बाणी';

  @override
  String get goalFieldTimes => 'दिन में कितनी बार';

  @override
  String goalFieldTimesHint(int minutes) {
    return 'हर बार लगभग $minutes मिनट';
  }

  @override
  String get goalFieldDuration => 'कितने समय के लिए';

  @override
  String get goalDurationEveryDay => 'हर रोज़';

  @override
  String get goalDuration40Days => '40 दिन';

  @override
  String get goalDurationUntilDate => 'किसी तारीख़ तक';

  @override
  String get goalFieldReminder => 'याद';

  @override
  String goalReminderEveryDayAt(String time) {
    return 'हर रोज़ $time बजे';
  }

  @override
  String get goalSave => 'संकल्प सहेजें';

  @override
  String get goalMoreBanis => 'और…';

  @override
  String get goalPause => 'संकल्प रोकें';

  @override
  String get goalDeleteConfirm =>
      'यह संकल्प मिटाएँ? इसकी गिनती डायरी में रहेगी।';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsSectionLanguage => 'भाषा';

  @override
  String get settingsAppLanguage => 'ऐप की भाषा';

  @override
  String get settingsSectionReading => 'पढ़ना';

  @override
  String get settingsGurbaniScript => 'गुरबाणी की लिपि';

  @override
  String get settingsGurbaniScriptSub => 'पाठ में से भी कभी भी बदलें';

  @override
  String get settingsShowMeaningsSub => 'पंजाबी, हिन्दी या अंग्रेज़ी';

  @override
  String get settingsSectionAudio => 'आवाज़';

  @override
  String get settingsNitnemAudio => 'नितनेम की आवाज़';

  @override
  String get settingsSukhmaniAudio => 'सुखमनी साहिब की आवाज़';

  @override
  String get settingsSectionVersions => 'बाणियों के रूप';

  @override
  String get settingsSectionReminders => 'याद';

  @override
  String get settingsPaathGoals => 'पाठ के संकल्प';

  @override
  String get settingsPaathGoalsSub => 'हर संकल्प के लिए याद रखें';

  @override
  String settingsGoalsCount(int count) {
    return '$count संकल्प';
  }

  @override
  String get settingsOnTimeReminders => 'समय पर याद';

  @override
  String get settingsOnTimeAllowed => 'अनुमति है — याद ठीक मिनट पर आती है';

  @override
  String get settingsOnTimeNotAllowed =>
      'अनुमति नहीं — याद कुछ मिनट देर हो सकती है';

  @override
  String get settingsSunFor => 'सूर्योदय-सूर्यास्त इस शहर के लिए';

  @override
  String get settingsRemindersNotArriving => 'याद नहीं आ रही?';

  @override
  String get settingsSectionDisplay => 'दिखावट';

  @override
  String get settingsTheme => 'थीम';

  @override
  String get settingsThemeAuto => 'अपने-आप';

  @override
  String get settingsThemeLight => 'उजाला';

  @override
  String get settingsThemeDark => 'अँधेरा';

  @override
  String get settingsSectionDiary => 'डायरी';

  @override
  String get settingsBackup => 'गूगल खाते में बैकअप';

  @override
  String get settingsBackupSub => 'नए फ़ोन पर वापस आ जाता है';

  @override
  String get settingsSectionAbout => 'बारे में';

  @override
  String get settingsAboutCredits => 'बारे में और आभार';

  @override
  String get settingsAboutCreditsSub => 'पाठी, पाठ के स्रोत, अनुवाद';

  @override
  String get settingsPrivacy => 'निजता';

  @override
  String get settingsPrivacySub =>
      'गुरबाणी वाले पन्नों पर कोई विज्ञापन नहीं · कोई लॉगिन नहीं · बिना इंटरनेट चलती है';

  @override
  String get settingsAnalytics => 'गुमनाम उपयोग और क्रैश रिपोर्ट साझा करें';

  @override
  String get settingsAnalyticsSub => 'इस बिल्ड में कुछ इकट्ठा नहीं होता';

  @override
  String get settingsLicences => 'ओपन-सोर्स लाइसेंस';

  @override
  String settingsVersion(String version) {
    return 'हाज़िरी $version';
  }

  @override
  String get cityPickerTitle => 'अपना शहर चुनें';

  @override
  String get cityPickerSearch => 'शहर खोजें';

  @override
  String get cityPickerUseLocation => 'मेरी जगह का उपयोग करें';

  @override
  String get cityPickerNoResults =>
      'कोई शहर नहीं मिला। पास का कोई बड़ा शहर देखें।';

  @override
  String get cityPickerNote =>
      'केवल इसी फ़ोन पर, सूर्योदय-सूर्यास्त का हिसाब लगाने के लिए उपयोग होता है।';

  @override
  String get batteryHelpTitle => 'याद नहीं आ रही?';

  @override
  String get batteryHelpBody =>
      'कुछ फ़ोन बैटरी बचाने के लिए ऐप्स को पीछे चलने से रोक देते हैं। अगर याद देर से या गायब हो, तो हाज़िरी को पीछे चलने की अनुमति दें।';

  @override
  String get batteryHelpSamsung =>
      'सैमसंग: सेटिंग्स → बैटरी → Background usage limits → Sleeping apps में से हाज़िरी हटाएँ।';

  @override
  String get batteryHelpXiaomi =>
      'शाओमी/रेडमी: सेटिंग्स → Apps → हाज़िरी → Autostart चालू, और Battery saver → No restrictions।';

  @override
  String get batteryHelpVivo =>
      'वीवो/iQOO: सेटिंग्स → बैटरी → Background power consumption → हाज़िरी को अनुमति दें।';

  @override
  String get batteryHelpOppo =>
      'ओप्पो/रियलमी: सेटिंग्स → बैटरी → App battery usage → हाज़िरी → Allow background activity।';

  @override
  String get batteryHelpOnePlus =>
      'वनप्लस: सेटिंग्स → बैटरी → Battery optimisation → हाज़िरी → Don\'t optimise।';

  @override
  String get batteryHelpButton => 'बैटरी सेटिंग्स खोलें';

  @override
  String get aboutTitle => 'बारे में और आभार';

  @override
  String get aboutPurpose =>
      'हाज़िरी पंजाबी, हिन्दी और अंग्रेज़ी में एक मुफ़्त, बिना-इंटरनेट चलने वाली नितनेम ऐप है। गुरबाणी पर कोई विज्ञापन नहीं। कोई लॉगिन नहीं।';

  @override
  String get aboutTextSources => 'गुरबाणी पाठ और लिप्यंतरण';

  @override
  String get aboutMeaningSources => 'अर्थ और टीके';

  @override
  String get aboutCalendarSource => 'कैलेंडर';

  @override
  String get aboutCityData => 'शहरों का डेटा';

  @override
  String get aboutFonts => 'फ़ॉन्ट';

  @override
  String get aboutFontsBody =>
      'मुक्ता, बलू पाजी 2, नोटो सेरिफ़ गुरमुखी और नोटो सेरिफ़ देवनागरी — SIL Open Font License।';

  @override
  String get aboutContact => 'संपर्क';

  @override
  String get aboutNoAudioYet =>
      'ऐप के साथ आई पाठ की रिकॉर्डिंग फ़ोन से ही चलती है, कभी स्ट्रीम नहीं होती।';

  @override
  String get privacyTitle => 'निजता';

  @override
  String get privacyBody =>
      'हाज़िरी में न कोई पासवर्ड है और न कोई साइन-इन स्क्रीन। बाणी पढ़ना, सुनना, कैलेंडर देखना और डायरी लिखना — सब इसी फ़ोन पर होता है और बिना इंटरनेट के भी चलता है। आपकी डायरी, संकल्प और सेटिंग्स इसी फ़ोन और आपके अपने गूगल बैकअप में रहते हैं। अगर आप शहर चुनते हैं या अपनी जगह का उपयोग करते हैं, वह फ़ोन में ही रहती है और केवल सूर्योदय-सूर्यास्त के लिए उपयोग होती है।';

  @override
  String get privacyNoAnalytics =>
      'जब तक आप संगत से नहीं जुड़ते, इस फ़ोन से कुछ भी बाहर नहीं जाता। इस बिल्ड में एनालिटिक्स बंद हैं और कोई क्रैश रिपोर्ट नहीं भेजी जाती।';

  @override
  String get privacySangat =>
      'अगर आप संगत से जुड़ते हैं, तो सर्वर पर सिर्फ़ आपका नाम, शहर, ईमेल और आपके ग्रुप व संकल्पों की गिनती जाती है। आपकी डायरी के शब्द कभी नहीं जाते, और आपकी ईमेल किसी और को कभी नहीं दिखाई जाती।';

  @override
  String get notifChannelNitnem => 'नितनेम की याद';

  @override
  String get notifChannelSimran => 'रोज़ाना सिमरन';

  @override
  String get notifChannelGurpurab => 'गुरपुरब';

  @override
  String get notifChannelGoals => 'पाठ के संकल्प';

  @override
  String get notifAmritVelaTitle => 'अमृत वेला';

  @override
  String notifAmritVelaBody(String bani, String time) {
    return '$bani तैयार है — आज सूर्योदय $time बजे है।';
  }

  @override
  String get notifSimranTitle => 'रोज़ाना सिमरन';

  @override
  String get notifSimranBody => 'वाहिगुरू सिमरन के पाँच शांत मिनट।';

  @override
  String get notifGurpurabTitle => 'कल गुरपुरब है';

  @override
  String get notifGurpurabToday => 'आज गुरपुरब है';

  @override
  String notifRehrasBody(int minutes) {
    return 'आपकी शाम की बाणी, आपके चुने समय पर — $minutes मिनट।';
  }

  @override
  String notifBaniBody(String bani, int minutes) {
    return '$bani — $minutes मिनट।';
  }

  @override
  String notifGoalBody(int done, int total) {
    return 'आज का आपका पाठ संकल्प — $total में से $done हो गए।';
  }

  @override
  String get notifActionStartNitnem => 'नितनेम शुरू करें';

  @override
  String get notifActionStart => 'शुरू करें';

  @override
  String get notifActionLater => 'बाद में';

  @override
  String get notifActionBegin => 'शुरू';

  @override
  String get notifActionSkipToday => 'आज छोड़ें';

  @override
  String get notifActionOpenCalendar => 'कैलेंडर खोलें';

  @override
  String get shareCardTitle => 'आज का विचार';

  @override
  String get shareCardFooter => 'हाज़िरी पर रोज़ाना पढ़ें';

  @override
  String get shareCardTruncated => '…हाज़िरी में पढ़ें';

  @override
  String get shareCardPreview => 'शेयर कार्ड की झलक';

  @override
  String get shareCardShare => 'शेयर करें';

  @override
  String get comingSoonShort => 'जल्द';

  @override
  String get audioIncluded => 'पाठ की आवाज़ शामिल है';

  @override
  String get audioIncludedSub =>
      'जपु जी साहिब बिना इंटरनेट चलता है, और लिखाई साथ-साथ चलती है।';

  @override
  String get settingsAudioOnPhone => 'इसी फ़ोन में सहेजी है';

  @override
  String get aboutAudioHeading => 'पाठ की रिकॉर्डिंग';

  @override
  String get readerTapLineToSeek =>
      'पाठ वहीं से शुरू करने के लिए किसी भी पंक्ति पर टैप करें';

  @override
  String get readerLockControlsOff => 'लॉक-स्क्रीन नियंत्रण बंद हैं';

  @override
  String get readerLockControlsOffSub =>
      'सूचनाओं की अनुमति दें, फिर पाठ लॉक स्क्रीन से रोका जा सकेगा।';

  @override
  String get settingsLockScreenControls => 'लॉक-स्क्रीन नियंत्रण';

  @override
  String get settingsLockScreenAllowed =>
      'अनुमति है — फ़ोन लॉक होने पर चलाएँ और रोकें दिखते हैं';

  @override
  String get settingsLockScreenBlocked =>
      'अनुमति नहीं — हाज़री के लिए सूचनाएँ बंद हैं';

  @override
  String get actionStop => 'बंद करें';

  @override
  String get playerStillPlaying => 'अभी चल रहा है';

  @override
  String get vicharTitle => 'आज का विचार';

  @override
  String get vicharNative => 'ਅੱਜ ਦਾ ਵਿਚਾਰ';

  @override
  String get vicharSource => 'श्री गुरु ग्रंथ साहिब जी';

  @override
  String get vicharExplore => 'और देखें';

  @override
  String get vicharShareTitle => 'यह विचार साझा करें';

  @override
  String get vicharShareBody => 'भेजने का तरीका चुनें';

  @override
  String get vicharShareAsText => 'पाठ के रूप में';

  @override
  String get vicharShareAsImage => 'छवि के रूप में';

  @override
  String get vicharMeaningPa => 'पंजाबी में';

  @override
  String get vicharMeaningEn => 'अंग्रेज़ी में';

  @override
  String get vicharNone => 'इस बिल्ड में अभी विचार नहीं है';

  @override
  String vicharDayOf(int day, int total) {
    return '$total में से पंक्ति $day';
  }

  @override
  String get goalsEmptyTitle => 'रोज़ का लक्ष्य रखें';

  @override
  String get goalsEmptyBody =>
      'बाणी चुनें और बताएँ कि दिन में कितनी बार पढ़नी है। आपके लक्ष्य यहाँ उसी समय दिखेंगे जो आपने रखा है।';

  @override
  String get errorGeneric => 'कुछ गलत हो गया।';

  @override
  String get errorContentDb =>
      'ऐप के साथ आई सामग्री नहीं खुल सकी। हाज़िरी फिर इंस्टॉल करने से ठीक हो जाएगा।';

  @override
  String get calendarKindPrakash => 'प्रकाश';

  @override
  String get calendarKindGurgaddi => 'गुरगद्दी';

  @override
  String get calendarKindJotiJot => 'ज्योति जोत';

  @override
  String get calendarKindShaheedi => 'शहीदी';

  @override
  String get calendarKindJorMela => 'जोड़ मेला';

  @override
  String get calendarKindBirth => 'जन्म दिवस';

  @override
  String get calendarKindHistorical => 'ऐतिहासिक';

  @override
  String get calendarKindFestival => 'त्योहार';

  @override
  String get calendarKindSpecial => 'दिवस';

  @override
  String get calendarKindSangrand => 'संगरांद';

  @override
  String get calendarKindPuranmashi => 'पूरनमाशी';

  @override
  String get calendarKindMasya => 'मस्या';

  @override
  String get gurpurabSupplementary => 'क्रॉस-चेक, SGPC सूची में नहीं';

  @override
  String get sangatSheetTitle => 'संगत से जुड़ें';

  @override
  String get sangatSheetBody =>
      'हाज़री इसके बिना भी पूरी चलती है। यह संगत जोड़ता है।';

  @override
  String get sangatPerkSee => 'देखें कौन पाठ कर रहा है';

  @override
  String get sangatPerkSeeSub => 'आपका परिवार, आपकी संगत, सारा जगत';

  @override
  String get sangatPerkGoal => 'साझे संकल्प में जुड़ें';

  @override
  String get sangatPerkGoalSub => 'समूह का पाठ, एक साथ गिना जाता';

  @override
  String get sangatPerkDiary => 'अपनी डायरी सुरक्षित रखें';

  @override
  String get sangatPerkDiarySub => 'फ़ोन बदलने पर वापस आ जाती है';

  @override
  String get sangatSetUp => 'शुरू करें — कुछ सेकंड लगते हैं';

  @override
  String get sangatNotNow => 'अभी नहीं';

  @override
  String get sangatNoAds =>
      'कोई पासवर्ड नहीं · कोई विज्ञापन नहीं · आपका पाठ आपके फ़ोन में रहता है';

  @override
  String get sangatBannerTitle => 'संगत से जुड़ें';

  @override
  String get sangatBannerBody =>
      'देखें आपके साथ दुनिया भर में कौन पाठ कर रहा है';

  @override
  String get sangatBannerTime => 'कुछ सेकंड लगते हैं';

  @override
  String get sangatBannerCta => 'शुरू करें';

  @override
  String get sangatProfileTitle => 'संगत से जुड़ें';

  @override
  String get sangatProfileSub => 'ताकि आपका पाठ औरों के साथ गिना जाए';

  @override
  String get sangatFieldName => 'आपका नाम';

  @override
  String get sangatFieldEmail => 'ईमेल';

  @override
  String get sangatFieldEmailHint =>
      'फ़ोन बदलने पर आपकी संगत इसी से वापस आती है। ऐप में और कोई इसे नहीं देखता।';

  @override
  String get sangatFieldPhone => 'फ़ोन';

  @override
  String get sangatFieldPhoneHint => 'नंबर जोड़ें';

  @override
  String get sangatFieldCity => 'शहर';

  @override
  String get sangatFieldCityHint =>
      'सिमरन के गोले पर एक बिंदु के रूप में दिखता है, इससे अधिक कुछ नहीं।';

  @override
  String get sangatOptional => 'वैकल्पिक';

  @override
  String get sangatNoPasswordEver =>
      'कोई पासवर्ड बनाना या याद रखना नहीं, और कभी नहीं होगा। जारी रखें दबाते ही आप संगत में हैं।';

  @override
  String get sangatContinue => 'जारी रखें';

  @override
  String get sangatWhatWeStore => 'हम क्या रखते हैं और क्यों';

  @override
  String get sangatNeedName => 'कृपया अपना नाम लिखें';

  @override
  String get sangatNeedEmail => 'कृपया ईमेल पता लिखें';

  @override
  String get sangatBadEmail => 'यह ईमेल पते जैसा नहीं लगता';

  @override
  String get sangatNeedCity => 'कृपया अपना शहर लिखें';

  @override
  String get sangatUnavailable =>
      'संगत तक नहीं पहुँच सके। आपका पाठ इस फ़ोन में सुरक्षित है — सिग्नल आने पर फिर कोशिश करें।';

  @override
  String get sangatEmailInUse => 'इस ईमेल से पहले ही हाज़री खाता है';

  @override
  String get sangatJoined => 'आप संगत में हैं';

  @override
  String get sangatRefused =>
      'गड़बड़ हमारी तरफ़ है, आपकी तरफ़ नहीं। आपका पाठ इस फ़ोन में सुरक्षित है।';

  @override
  String get accountTitle => 'आपका खाता';

  @override
  String get accountEmail => 'ईमेल';

  @override
  String get accountPhone => 'फ़ोन';

  @override
  String get accountCity => 'शहर';

  @override
  String get accountNotAdded => 'नहीं जोड़ा';

  @override
  String get accountVerified => 'पुष्टि हो गई';

  @override
  String get accountNotVerified => 'पुष्टि बाकी';

  @override
  String get accountVerifyTitle => 'अपनी पुष्टि पूरी करें';

  @override
  String get accountVerifyBody =>
      'आपका खाता दोनों हालात में चलता है। ईमेल की पुष्टि ही इसे फ़ोन बदलने पर वापस लाती है।';

  @override
  String get accountVerifyCta => 'मेरी ईमेल की पुष्टि करें';

  @override
  String get accountSafeTitle => 'आपकी संगत सुरक्षित है';

  @override
  String get accountSafeBody =>
      'किसी भी फ़ोन पर इस ईमेल से दाखिल हों और आपके समूह, संकल्प और डायरी वापस आ जाएँगे।';

  @override
  String get accountSignOut => 'इस फ़ोन से बाहर आएँ';

  @override
  String get accountSignOutWarn =>
      'आपके खाते की अभी पुष्टि नहीं हुई, इसलिए बाहर आने पर यह खो जाएगा। पहले ईमेल की पुष्टि करें।';

  @override
  String get accountSignOutConfirm => 'फिर भी बाहर आएँ';

  @override
  String get accountSectionYou => 'आप';

  @override
  String get accountJoinedFirst =>
      'अपना खाता यहाँ देखने के लिए संगत से जुड़ें।';

  @override
  String get verifyTitle => 'ईमेल की पुष्टि करें';

  @override
  String get verifyCheckInbox => 'अपनी ईमेल देखें';

  @override
  String verifySentTo(String email) {
    return 'हमने $email पर एक लिंक भेजा है। उसे दबाएँ और इस फ़ोन की पुष्टि हो जाएगी।';
  }

  @override
  String get verifySend => 'लिंक भेजें';

  @override
  String get verifySendAgain => 'दोबारा भेजें';

  @override
  String get verifySent => 'भेज दिया। पहुँचने में एक मिनट लग सकता है।';

  @override
  String get verifyWrongAddress => 'ग़लत पता?';

  @override
  String get verifyChangeIt => 'इसे बदलें और हम नया लिंक भेजेंगे';

  @override
  String get verifyUntilThen =>
      'जब तक यह नहीं होता, आपके समूह और संकल्प सिर्फ़ इसी फ़ोन में रहते हैं, और फ़ोन बदलने पर वापस नहीं आ सकते।';

  @override
  String get verifyLater => 'यह बाद में करें';

  @override
  String get sangatTitle => 'संगत';

  @override
  String get sangatCreateOrJoin => 'बनाएँ या जुड़ें';

  @override
  String get sangatWorldwide => 'दुनिया भर की संगत';

  @override
  String get sangatYourGroups => 'आपके ग्रुप';

  @override
  String get sangatCanJoin => 'जिनसे आप जुड़ सकते हैं';

  @override
  String get sangatSeeAll => 'सभी देखें';

  @override
  String get sangatJoinGroup => 'जुड़ें';

  @override
  String get sangatHaveLink => 'लिंक है? ग्रुप से जुड़ें';

  @override
  String get sangatNoGroupsYet =>
      'आप संगत से जुड़े हैं, पर अभी किसी ग्रुप में नहीं। अपने परिवार का ग्रुप बनाएँ, या नीचे किसी से जुड़ें।';

  @override
  String get sangatNotJoinedTitle =>
      'संगत वह जगह है जहाँ पाठ मिलकर गिना जाता है';

  @override
  String get groupKindFamily => 'पारिवारिक ग्रुप';

  @override
  String get groupKindSangat => 'संगत';

  @override
  String get groupKindCircle => 'सिमरन मंडली';

  @override
  String groupMembers(int count) {
    return '$count लोग';
  }

  @override
  String get groupNoGoalYet => 'अभी कोई साझा संकल्प नहीं';

  @override
  String groupProgress(String done, String target, String unit) {
    return '$target में से $done $unit';
  }

  @override
  String get unitPaath => 'पाठ';

  @override
  String get unitMinutes => 'मिनट';

  @override
  String get groupGone => 'वह ग्रुप अब मौजूद नहीं है';

  @override
  String get groupCreateTitle => 'ग्रुप बनाएँ';

  @override
  String get groupWhatKind => 'किस तरह का';

  @override
  String get groupKindFamilySub => 'जिनके साथ आप रहते या बात करते हैं';

  @override
  String get groupKindSangatSub => 'गुरुद्वारा या कोई बड़ी संगत';

  @override
  String get groupKindCircleSub => 'पाठ नहीं, मिनट गिने जाते हैं';

  @override
  String get groupNameLabel => 'ग्रुप का नाम';

  @override
  String get groupNameHint =>
      'ग्रुप के लोग यह देखते हैं। जब चाहें बदल सकते हैं।';

  @override
  String get groupNeedName => 'ग्रुप का नाम लिखें';

  @override
  String get groupWhoCanFind => 'कौन ढूँढ सकता है';

  @override
  String get groupPrivate => 'निजी — सिर्फ़ जिन्हें आप लिंक भेजें';

  @override
  String get groupPrivateSub => 'तुरंत चालू';

  @override
  String get groupListed => 'संगत में दिखाया — कोई भी ढूँढ सकता है';

  @override
  String get groupListedSub => 'दिखाने से पहले जाँचा जाता है';

  @override
  String get groupListedNote =>
      'दिखाए गए ग्रुप का नाम वे लोग भी देखते हैं जो आपको नहीं जानते, इसलिए दिखाने से पहले हम उसे पढ़ते हैं — आमतौर पर उसी दिन। निजी ग्रुप तुरंत चालू हो जाते हैं।';

  @override
  String get groupCreateCta => 'ग्रुप बनाएँ';

  @override
  String get groupCreated => 'आपका ग्रुप तैयार है';

  @override
  String get groupSharedGoal => 'साझा संकल्प';

  @override
  String get groupYou => 'आप';

  @override
  String get groupTheGroup => 'ग्रुप';

  @override
  String get groupStartPaath => 'पाठ शुरू करें';

  @override
  String get groupLogPaath => 'पाठ दर्ज करें';

  @override
  String get groupMembersTitle => 'सदस्य';

  @override
  String get groupInvite => 'बुलाएँ';

  @override
  String get groupReport => 'इस ग्रुप की शिकायत करें';

  @override
  String get groupAnonMember => 'एक सदस्य';

  @override
  String get groupYouSuffix => 'आप';

  @override
  String get groupAdmin => 'प्रबंधक';

  @override
  String get groupLogTitle => 'पाठ दर्ज करें';

  @override
  String get groupLogAdd => 'ग्रुप में जोड़ें';

  @override
  String get groupLogged => 'ग्रुप में जुड़ गया';

  @override
  String get groupLeave => 'यह ग्रुप छोड़ें';

  @override
  String get groupLeft => 'आपने ग्रुप छोड़ दिया';

  @override
  String get groupSetGoalTitle => 'साझा संकल्प';

  @override
  String get groupGoalWhat => 'ग्रुप क्या करेगा';

  @override
  String get groupGoalHowMany => 'मिलकर कितने';

  @override
  String get groupGoalByWhen => 'कब तक';

  @override
  String get groupGoalNoEnd => 'या कोई आख़िरी तारीख़ नहीं';

  @override
  String get groupGoalPickDate => 'दूसरी तारीख़ चुनें';

  @override
  String get groupGoalWillSee => 'ग्रुप यह देखेगा';

  @override
  String get groupGoalSet => 'संकल्प तय करें';

  @override
  String get groupGoalSaved => 'ग्रुप का संकल्प तय हो गया';

  @override
  String get groupGoalNeedTarget => 'कितने, यह चुनें';

  @override
  String get groupInviteTitle => 'बुलाएँ';

  @override
  String get groupInviteShareLink => 'यह लिंक साझा करें';

  @override
  String get groupInviteShare => 'लिंक साझा करें';

  @override
  String get groupInviteCopied => 'लिंक कॉपी हो गया';

  @override
  String get groupInviteRemove => 'हटाएँ';

  @override
  String get groupInviteStarted => 'यह ग्रुप आपने शुरू किया';

  @override
  String get groupJoinByLinkTitle => 'ग्रुप से जुड़ें';

  @override
  String get groupJoinByLinkBody =>
      'जो लिंक किसी ने भेजा है वह डालें, या उसके अंत वाला कोड।';

  @override
  String get groupJoinByLinkLabel => 'लिंक या कोड';

  @override
  String get groupJoinByLinkCta => 'जुड़ें';

  @override
  String get groupJoinedOne => 'आप ग्रुप में हैं';

  @override
  String get groupSimranSlug => 'सिमरन के मिनट';

  @override
  String get navSangat => 'संगत';

  @override
  String simranOthersHere(int count) {
    return '$count और';
  }

  @override
  String get simranOthersSub => 'आज साथ बैठे हैं';

  @override
  String get simranGlobeFirst => 'आज सबसे पहले आप हैं';

  @override
  String get simranGlobeTurn => 'गोले को हाथ से घुमाएँ';

  @override
  String get hazriMarked => 'आज की हाज़िरी लग गई';

  @override
  String get hazriNotYet => 'आज की हाज़िरी अभी नहीं लगी';

  @override
  String hazriMarkedAtWith(String time, String what) {
    return '$time बजे, $what के साथ';
  }

  @override
  String hazriMarkedAt(String time) {
    return '$time बजे लगी';
  }

  @override
  String get hazriHow => 'एक पाठ, या एक बार का सिमरन — हाज़िरी लग जाती है';

  @override
  String get hazriSimran => 'नाम सिमरन';

  @override
  String get hazriGoalsAllDone => 'आज के सभी संकल्प पूरे हुए';

  @override
  String get hazriSeeDiary => 'मेरी डायरी देखें';

  @override
  String get diaryHazriDot => 'हाज़िरी';

  @override
  String get diaryGoalsDot => 'संकल्प';

  @override
  String get diaryWhatYouDid => 'जो आपने पूरा किया';

  @override
  String get diaryNotYet => 'अभी नहीं';

  @override
  String get diaryHazriNote =>
      'एक पाठ हो या पाँच, या एक बार का सिमरन — हाज़िरी लग जाती है। गिनती वह है जो आपने किया, वह नहीं जो करना था।';

  @override
  String get restoreTitle => 'मेरा खाता वापस लाएँ';

  @override
  String get restoreBeenHere => 'आप पहले भी यहाँ आ चुके हैं';

  @override
  String get restoreThisAccount => 'यही खाता वापस लाएँ';

  @override
  String get restoreOr => 'या';

  @override
  String get restoreStartFresh => 'नया खाता शुरू करें';

  @override
  String get restoreStartFreshSub => 'पुराने में से कुछ साथ नहीं आएगा';

  @override
  String get restoreNothingSignedOut =>
      'वापस लाने से कहीं कुछ साइन-आउट नहीं होता। एक ही खाता एक से ज़्यादा फ़ोन पर रह सकता है।';

  @override
  String get restoreSendLink => 'मुझे लिंक भेजें';

  @override
  String get restorePasteLabel => 'ईमेल वाला लिंक यहाँ डालें';

  @override
  String get restorePasteHint =>
      'इसी फ़ोन पर ईमेल खोलें, पूरा लिंक कॉपी करें और यहाँ डालें।';

  @override
  String get restoreDone => 'आपका खाता वापस आ गया';

  @override
  String get restoreDiaryNote =>
      'डायरी तभी वापस आती है जब सिंक चालू था। सिंक बंद हो तो ग्रुप और संकल्प रहते हैं, और डायरी उसी फ़ोन में रहती है जिसने लिखी थी।';

  @override
  String get restoreOpenToday => 'आज खोलें';

  @override
  String get linkProblemTitle => 'वह लिंक काम नहीं किया';

  @override
  String get linkUsedTitle => 'पहले ही इस्तेमाल हो चुका';

  @override
  String get linkUsedBody =>
      'यह लिंक एक फ़ोन को साइन-इन कर चुका है। हर लिंक एक बार चलता है और फिर बंद हो जाता है — इसी वजह से आगे भेजी गई ईमेल अंदर आने का रास्ता नहीं बनती।';

  @override
  String get linkExpiredTitle => 'बहुत पुराना';

  @override
  String get linkExpiredBody =>
      'लिंक एक घंटा चलते हैं। यह अपने आप ख़त्म हो गया — किसी ने इस्तेमाल नहीं किया।';

  @override
  String get linkWrongTitle => 'यह हमारा लिंक नहीं लगता';

  @override
  String get linkWrongBody =>
      'यह वह लिंक नहीं लगता जो हमने भेजा था। पूरा लिंक कॉपी करें, प्रश्नचिह्न के बाद वाला हिस्सा भी।';

  @override
  String get linkSendAnother => 'नया लिंक भेजें';

  @override
  String get linkWrongAddressNote =>
      'अगर इनमें से कोई भी आप नहीं थे, तो पुष्टि से पहले अपनी ईमेल बदलें। लिंक सिर्फ़ खाते वाले पते पर ही जाता है।';

  @override
  String get verifyConfirmed => 'आपकी ईमेल की पुष्टि हो गई';

  @override
  String get privacyDataTitle => 'निजता और मेरा डेटा';

  @override
  String get privacyOnPhoneOnly => 'सिर्फ़ इसी फ़ोन में';

  @override
  String get privacyPhoneDiary => 'आपकी डायरी और निरंतरता';

  @override
  String get privacyPhoneProgress => 'पढ़ने की जगह और संकल्प';

  @override
  String get privacyPhoneContent => 'हर बाणी, उसका पाठ और कैलेंडर';

  @override
  String get privacySharedWithSangat => 'संगत के साथ साझा';

  @override
  String get privacyShareName => 'आपका नाम';

  @override
  String get privacyShareCity => 'आपका चुना शहर — गोले पर एक बिंदु के रूप में';

  @override
  String get privacyShareGroups => 'आप किन ग्रुपों में हैं';

  @override
  String get privacyShareCounts => 'साझा संकल्प में आपने कितना किया';

  @override
  String get privacyAccountOnly => 'सिर्फ़ आपके खाते के लिए रखा';

  @override
  String get privacyAccountEmail =>
      'आपकी ईमेल — इसका एक ही काम है, खाता वापस लाना';

  @override
  String get privacyShowMyName => 'ग्रुपों में मेरा नाम दिखाएँ';

  @override
  String get privacyShowMyNameSub => 'बंद हो तो “एक सदस्य” दिखाई देता है';

  @override
  String get privacyDownload => 'जो कुछ हमारे पास है, सब डाउनलोड करें';

  @override
  String get privacyDownloadSub => 'एक फ़ाइल जो आप रख और पढ़ सकते हैं';

  @override
  String get privacyDelete => 'मेरा खाता और डेटा मिटाएँ';

  @override
  String get privacyDeleteSub => 'आपकी डायरी इसी फ़ोन में रहेगी';

  @override
  String get privacyDeleteConfirm =>
      'जो संगत के पास है, सब मिटा दें? आपके ग्रुप, आपकी गिनती और खाता चले जाएँगे। इस फ़ोन में कुछ नहीं छेड़ा जाएगा।';

  @override
  String get privacyDeleteDo => 'मिटा दें';

  @override
  String get privacyDeleted => 'आपका खाता और उसका डेटा मिट गया';

  @override
  String get privacyNotJoined =>
      'आप संगत से नहीं जुड़े, इसलिए यहाँ से कुछ भी इस फ़ोन से बाहर नहीं गया।';

  @override
  String get libraryTitle => 'विचार';

  @override
  String get librarySubtitle => 'पढ़ें, और ढूँढें';

  @override
  String get librarySearchHint => 'लेख, गुरुद्वारे, बाणियाँ ढूँढें…';

  @override
  String get libraryKindAll => 'सभी';

  @override
  String get libraryKindArticle => 'लेख';

  @override
  String get libraryKindGurdwara => 'गुरुद्वारे';

  @override
  String get libraryKindGuru => 'गुरु साहिबान';

  @override
  String get libraryKindBani => 'बाणियाँ';

  @override
  String get libraryKindDay => 'सिख दिवस';

  @override
  String get libraryMoreToRead => 'और पढ़ने के लिए';

  @override
  String libraryMinutes(int count) {
    return '$count मिनट का पाठ';
  }

  @override
  String get libraryNeedsConnection =>
      'विचार ही हाज़िरी का वह एक हिस्सा है जिसे इंटरनेट चाहिए। आपकी बाणियाँ, उनका पाठ, कैलेंडर और डायरी को कभी नहीं।';

  @override
  String get libraryNothingMatches => 'इससे अभी कुछ नहीं मिलता';

  @override
  String get libraryEmpty =>
      'यहाँ अभी कुछ नहीं है। विचार वेबसाइट पर लिखा जाता है और हर फ़ोन वही पढ़ता है, इसलिए यहाँ वही आएगा जो छापा गया है।';

  @override
  String get libraryOffline => 'कोई कनेक्शन नहीं';

  @override
  String get libraryClear => 'हटाएँ';

  @override
  String libraryResults(int count, String query) {
    return '“$query” के लिए $count नतीजे';
  }

  @override
  String get libraryCorrections =>
      'वेबसाइट से लिया गया। अगर यहाँ कुछ ग़लत है, वहाँ एक बार ठीक होता है और हर फ़ोन को ठीक दिखता है।';

  @override
  String get libraryOpen => 'खोलें';

  @override
  String get syncTitle => 'सिंक';

  @override
  String get syncSubtitle => 'क्या होता है, और कब';

  @override
  String get syncStateSynced => 'सिंक हो गया';

  @override
  String get syncStateSyncedSub => 'सब कुछ अप टू डेट है';

  @override
  String get syncStateWaiting => 'कोई कनेक्शन नहीं';

  @override
  String get syncStateWaitingSub =>
      'चलते रहें — आपका पाठ इसी फ़ोन में सहेजा है और कनेक्शन आने पर चला जाएगा';

  @override
  String get syncStateWifi => 'वाई-फ़ाई का इंतज़ार';

  @override
  String get syncStateWifiSub =>
      'आपका पाठ इसी फ़ोन में सहेजा है। अभी भेजना है तो “सिर्फ़ वाई-फ़ाई पर” बंद करें।';

  @override
  String syncStateSending(int count) {
    return '$count दिन भेजे जा रहे हैं';
  }

  @override
  String get syncStateOff => 'सिंक बंद है';

  @override
  String get syncStateOffSub => 'आपकी डायरी सिर्फ़ इसी फ़ोन में है';

  @override
  String get syncWorksWithout =>
      'हाज़िरी बिना सिग्नल चलती है। सिंक सिर्फ़ यह तय करता है कि नए फ़ोन पर आपकी डायरी वापस आ सके या नहीं।';

  @override
  String get syncMyDiary => 'मेरी डायरी सिंक करें';

  @override
  String get syncWifiOnly => 'सिर्फ़ वाई-फ़ाई पर';

  @override
  String get syncWifiOnlySub => 'मोबाइल डेटा बचाता है';

  @override
  String get syncNow => 'अभी सिंक करें';

  @override
  String get syncNeedsAccount =>
      'पहले संगत से जुड़ें — खाते के बिना सिंक करने के लिए कोई जगह नहीं।';

  @override
  String get notifTitle => 'सूचनाएँ';

  @override
  String get notifOwnPractice => 'आपका अपना अभ्यास';

  @override
  String get notifYourGroups => 'आपके ग्रुप';

  @override
  String get notifGlobal => 'दुनिया भर का सिमरन';

  @override
  String get notifGoalClose => 'संकल्प नज़दीक है';

  @override
  String get notifGoalCloseSub => 'जब ग्रुप 90% से आगे निकले';

  @override
  String get notifSomeoneJoined => 'कोई जुड़ा';

  @override
  String get notifSomeoneJoinedSub => 'आपके ग्रुपों में नए सदस्य';

  @override
  String get notifGroupSummary => 'रोज़ाना ग्रुप का सार';

  @override
  String get notifGroupSummarySub => 'एक संदेश, रात 9 बजे';

  @override
  String get notifLargeGatherings => 'बड़े इकट्ठ';

  @override
  String get notifLargeGatheringsSub => 'जब हज़ारों मिलकर बैठे हों';

  @override
  String get notifGroupsNotYet =>
      'इनके लिए सर्वर से संदेश भेजना पड़ता है, और हाज़िरी के पास अभी वह नहीं है। ऊपर वाली आपकी अपनी याद-दिलाएँ इसी फ़ोन की हैं और बिना इंटरनेट चलती हैं।';

  @override
  String get menuTooltip => 'मेन्यू';

  @override
  String simranYouAndOthers(int count) {
    return 'आप और $count अन्य';
  }

  @override
  String get simranAreHereToday => 'आज यहाँ हैं';

  @override
  String simranCitiesToday(int count) {
    return 'आज $count शहर';
  }

  @override
  String get simranLegendYou => 'आप';

  @override
  String get simranLegendHere => 'आज यहाँ';

  @override
  String simranBeginMinutes(int count) {
    return 'सिमरन शुरू करें · $count मिनट';
  }

  @override
  String get simranTurnGlobeShort => 'गोले को हाथ से घुमाएँ';

  @override
  String readerLoggedInDiary(String time) {
    return 'आपकी डायरी में दर्ज · $time';
  }

  @override
  String get readerThisMarkedHazri =>
      'हाज़िरी इसी से लगी — आज सबसे पहले यही पूरा हुआ';

  @override
  String get readerStartAgain => 'फिर से शुरू करें';

  @override
  String get readerNextBani => 'अगली बाणी';

  @override
  String get goalsCardTitle => 'आपके संकल्प';

  @override
  String goalsDoneOf(int done, int total) {
    return '$total में से $done पूरे';
  }

  @override
  String get goalSimranOrBani =>
      'सिमरन मिनटों में गिना जाता है; बाणी पाठों में';

  @override
  String get goalHowLong => 'हर बार कितनी देर';

  @override
  String get goalCustomMinutes => 'अपनी पसंद';

  @override
  String get goalSimranLoops =>
      'पाठ पाँच मिनट का है और इससे ज़्यादा के लिए हल्की मिश्रित आवाज़ के साथ दोहराया जाता है।';

  @override
  String get groupStartCounts =>
      'यहाँ से शुरू करेंगे तो पूरा होने पर संकल्प में गिना जाएगा';

  @override
  String get groupSetGoalCta => 'साझा संकल्प तय करें';

  @override
  String get groupChangeGoal => 'संकल्प बदलें';

  @override
  String get groupNoGoalMember => 'ग्रुप क्या करेगा, यह प्रबंधक तय करता है';

  @override
  String get groupNoGoalAdmin => 'तय करें कि ग्रुप मिलकर क्या करेगा, और कितना';

  @override
  String get groupInviteCode => 'या उन्हें यह कोड दें';

  @override
  String get groupInviteCodeHow =>
      'हाज़िरी में: संगत → लिंक है? ग्रुप से जुड़ें → कोड डालें। लिंक स्वयं वेबसाइट खोलता है, जो अभी बनी नहीं है।';

  @override
  String groupInviteShareText(String group, String code) {
    return '$group के साथ हाज़िरी पर जुड़ें।\n\nहाज़िरी खोलें → संगत → “लिंक है? ग्रुप से जुड़ें”, और यह कोड डालें:\n\n$code';
  }

  @override
  String get diarySubtitle => 'हर वह दिन जब आपकी हाज़िरी लगी';

  @override
  String get diaryStatHazriDays => 'हाज़िरी वाले दिन';

  @override
  String get diaryStatGoalsMet => 'संकल्प पूरे';

  @override
  String get diaryStatPaath => 'पाठ';

  @override
  String get diaryStatSimranMinutes => 'सिमरन के मिनट';

  @override
  String get diaryStatDaysInRow => 'लगातार दिन';

  @override
  String get diaryTickAnything => 'इस दिन जो भी पूरा किया, निशान लगाएँ';

  @override
  String diaryNotYetAt(String time) {
    return 'अभी नहीं · $time';
  }

  @override
  String get simranPaused => 'रुका हुआ';
}
