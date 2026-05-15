// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appName => 'అథిదిహబ్';

  @override
  String get home => 'హోమ్';

  @override
  String get dashboard => 'డాష్‌బోర్డ్';

  @override
  String get properties => 'ఆస్తులు';

  @override
  String get tenants => 'అద్దెకారులు';

  @override
  String get invoices => 'ఇన్వాయిసులు';

  @override
  String get payments => 'చెల్లింపులు';

  @override
  String get maintenance => 'నిర్వహణ';

  @override
  String get documents => 'పత్రాలు';

  @override
  String get errorLoadingDocuments => 'పత్రాలను లోడ్ చేయలేకపోయాం';

  @override
  String get uploadedDocuments => 'అప్‌లోడ్ చేసిన పత్రాలు';

  @override
  String get verificationStatusTitle => 'సత్యాపన స్థితి';

  @override
  String get statusNotStarted => 'ప్రారంభించలేదు';

  @override
  String get statusInProgress => 'ప్రగతిలో ఉంది';

  @override
  String get statusVerified => 'ధృవీకరించబడింది';

  @override
  String get statusRejected => 'తిరస్కరించబడింది';

  @override
  String get statusUnderReview => 'సమీక్షలో ఉంది';

  @override
  String get statusExpired => 'కాలనంతరించిపోయింది';

  @override
  String get statusRetryAvailable => 'మళ్లీ ప్రయత్నించడానికి উপলబ్దం';

  @override
  String get completionProgress => 'సంపూర్ణత పురోగతి';

  @override
  String get verificationInProgressTitle => 'సత్యాపన ప్రక్రియలో ఉంది';

  @override
  String get verificationInProgressSubtitle =>
      'మేము మీ ఆధార్‌ను ధృవీకరిస్తున్నా వరకు వేచి ఉండండి. దీనిలో కొన్ని నిమిషాలు పట్టవచ్చు.';

  @override
  String get kycVerifiedSuccessfullyTitle => 'KYC విజయవంతంగా ధృవీకరించబడింది';

  @override
  String get kycVerifiedSuccessfullySubtitle =>
      'మీ గుర్తింపు ధృవీకరించబడింది. మీరు ఇప్పుడు చెక్-ఇన్ కొనసాగించవచ్చు.';

  @override
  String get verificationRejectedTitle => 'సత్యాపన తిరస్కరించబడింది';

  @override
  String get retryInitiated => 'పునఃప్రయత్నం ప్రారంభించబడింది';

  @override
  String get startKycVerificationButton => 'KYC సత్యాపన ప్రారంభించండి';

  @override
  String get openDocumentUploadButton => 'పత్రాల అప్‌లోడ్ ఓపెన్ చేయండి';

  @override
  String get couldNotStartKyc => 'KYC సత్యాపన ప్రారంభించలేకపోయాం.';

  @override
  String get invalidKycVerificationUrl => 'అసంగత KYC సత్యాపన URL.';

  @override
  String get couldNotOpenKycVerificationPage =>
      'KYC సత్యాపన పేజీని తెరవలేకపోయాం.';

  @override
  String get couldNotOpenDocument => 'పత్రాన్ని తెరవలేకపోయాం';

  @override
  String verifiedWithScore(int score) {
    return 'ధృవీకరించబడింది ($score%)';
  }

  @override
  String get pendingVerification => 'సత్యాపన నిల్వలో ఉంది';

  @override
  String get view => 'బ్రౌజ్';

  @override
  String get reupload => 'మళ్లీ అప్‌లోడ్ చేయండి';

  @override
  String get statusReady => 'సಿದ್ಧంగా ఉంది';

  @override
  String get statusPending => 'పెండింగ్';

  @override
  String get statusNotReady => 'సిద్ధం లేదు';

  @override
  String get aboutKycVerificationTitle => 'KYC సత్యాపన గురించి';

  @override
  String get aboutKycVerificationParagraph =>
      '• చెక్-ఇన్‌కు ముందు KYC సత్యాపన అవసరం\n• గుర్తింపు నిర్ధారణకు మేము సురక్షిత ఆధార్ సత్యాపనను ఉపయోగిస్తాం\n• మీ డేటా సంకేతీకృతంగా మరియు సురక్షితంగా నిల్వ చేయబడుతుంది\n• ఆధార్ యొక్క కేవలం చివరి 4 అంకెలే నిల్వ చేయబడతాయి\n• సత్యాపన సాధారణంగా 5-10 నిమిషాలు పడవచ్చు';

  @override
  String get profile => 'ప్రొఫైల్';

  @override
  String get all => 'అన్నీ';

  @override
  String get pendingStatus => 'పెండింగ్';

  @override
  String get paidStatus => 'చెల్లించబడింది';

  @override
  String get overdueStatus => 'గడువు మించిపోయింది';

  @override
  String get filtered => 'ఫిల్టర్ చేయబడింది';

  @override
  String get filterByMonth => 'నెల ఆధారంగా ఫిల్టర్ చేయండి';

  @override
  String get clear => 'తొలగించు';

  @override
  String get apply => 'వర్తించు';

  @override
  String get searchInvoices =>
      'అద్దెకారి పేరు, ఇమెయిల్, ఫోన్ ద్వారా వెతకండి...';

  @override
  String get pleaseSelectOrganizationFirst =>
      'దయచేసి ముందుగా ఒక సంస్థను ఎంచుకోండి';

  @override
  String get sendBulkReminders => 'బల్క్ రిమైండర్లు పంపండి';

  @override
  String get sendPersonalizedWhatsAppReminders =>
      'వ్యక్తిగతీకరించిన వాట్సాప్ రిమైండర్‌లను పంపండి';

  @override
  String get includeOverdue => 'బకాయిలను చేర్చండి';

  @override
  String get remindForPastDueDates => 'గత గడువు తేదీల కోసం గుర్తు చేయండి';

  @override
  String get dueWindow => 'గడువు విండో';

  @override
  String dueWithinDays(int days) {
    return '$days రోజుల్లోపు గడువు';
  }

  @override
  String get queuingWhatsAppMessages => 'వాట్సాప్ సందేశాలను క్యూలో ఉంచుతోంది';

  @override
  String get thisMayTakeAMoment => 'దీనికి కొంత సమయం పట్టవచ్చు';

  @override
  String get failedToSendReminders => 'రిమైండర్‌లు పంపడంలో విఫలమైంది';

  @override
  String get close => 'మూసివేయి';

  @override
  String get sendNow => 'ఇప్పుడే పంపు';

  @override
  String get couldNotLoadInvoices => 'ఇన్వాయిసులు లోడ్ చేయలేకపోయాం';

  @override
  String get noInvoicesFound => 'ఇన్వాయిసులు లభించలేదు';

  @override
  String get tryDifferentSearchTerm => 'వేరే శోధన పదాన్ని ప్రయత్నించండి';

  @override
  String get invoicesWillAppearHere => 'ఇన్వాయిసులు ఇక్కడ కనిపిస్తాయి';

  @override
  String get payNow => 'ఇప్పుడే చెల్లించండి';

  @override
  String get paid => 'చెల్లించబడింది';

  @override
  String due(String dueDate) {
    return 'గడువు $dueDate';
  }

  @override
  String get refresh => 'రిఫ్రెష్';

  @override
  String get refreshing => 'రిఫ్రెష్ అవుతోంది...';

  @override
  String get goodMorning => 'శుభోదయం';

  @override
  String get goodAfternoon => 'శుభ మధ్యాహ్నం';

  @override
  String get goodEvening => 'శుభ సాయంత్రం';

  @override
  String get portfolioOverview => 'ఇది మీ పోర్ట్‌ఫోలియో అవలోకనం';

  @override
  String get occupancy => 'ఆక్యుపెన్సీ';

  @override
  String get vacantBeds => 'ఖాళీ బెడ్లు';

  @override
  String get revenueLastSixMonths => 'ఆదాయం (6 నెలలు)';

  @override
  String get recentActivity => 'ఇటీవలి కార్యకలాపం';

  @override
  String get setUpYourOrganization => 'మీ సంస్థను ఏర్పాటు చేయండి';

  @override
  String get createYourOrganizationDescription =>
      'ప్రాపర్టీలు, గదులు, అద్దెకారులు, బిల్లింగ్ మరియు అనలిటిక్స్‌ను అన్‌లాక్ చేయడానికి మీ సంస్థను సృష్టించండి.';

  @override
  String get createOrganization => 'సంస్థను సృష్టించండి';

  @override
  String get couldNotLoadDashboard => 'డాష్‌బోర్డ్‌ను లోడ్ చేయలేకపోయాం';

  @override
  String get monthlyRevenue => 'మాసిక ఆదాయం';

  @override
  String get fromLastMonth => 'గత నెలతో పోల్చితే ↑ 12%';

  @override
  String get noRecentActivityYet => 'ఇంకా ఇటీవలి కార్యకలాపం లేదు.';

  @override
  String get justNow => 'ఇప్పుడే';

  @override
  String minutesAgo(int minutes) {
    return '$minutes నిమిషాల క్రితం';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours గంటల క్రితం';
  }

  @override
  String daysAgo(int days) {
    return '$days రోజుల క్రితం';
  }

  @override
  String pleaseWaitBeforeRefreshingAgain(int seconds) {
    return 'మళ్లీ రిఫ్రెష్ చేయడానికి ముందు దయచేసి $seconds సెకన్లు వేచిచూడండి';
  }

  @override
  String get dataRefreshedSuccessfully => 'డేటా విజయవంతంగా రిఫ్రెష్ అయ్యింది';

  @override
  String failedToRefresh(String error) {
    return 'రిఫ్రెష్ చేయడం విఫలమైంది: $error';
  }

  @override
  String get webView => 'వెబ్ వ్యూ';

  @override
  String get retry => 'మళ్లీ ప్రయత్నించండి';

  @override
  String errorPrefix(String message) {
    return 'లోపం: $message';
  }

  @override
  String get pressBackAgainToExitApp =>
      'యాప్ నుండి బయటకు రావడానికి మళ్లీ వెనక్కి నొక్కండి';

  @override
  String get pressBackAgainToExitPortal =>
      'బయటకు రావడానికి మళ్లీ వెనక్కి నొక్కండి';

  @override
  String get signOut => 'సైన్ అవుట్';

  @override
  String get signOutTitle => 'సైన్ అవుట్';

  @override
  String get signOutMessage =>
      'మీరు మీ ఖాతా నుండి లాగ్ అవుట్ అవుతారు.\nసేవ్ చేయని మార్పులు పోతాయి.';

  @override
  String get tenantPortalSignOutTitle =>
      'టెనెంట్ పోర్టల్ నుండి సైన్ అవుట్ చేయాలా?';

  @override
  String get tenantPortalSignOutMessage =>
      'మీరు ఈ పరికరం నుండి లాగ్ అవుట్ అవుతారు మరియు లాగిన్ స్క్రీన్‌కు తిరిగి వెళ్తారు.';

  @override
  String get unsavedProfileChangesLost =>
      'సేవ్ చేయని ప్రొఫైల్ మార్పులు పోతాయి.';

  @override
  String get cancel => 'రద్దు';

  @override
  String get edit => 'సవరించు';

  @override
  String get save => 'సేవ్ చేయి';

  @override
  String get personalInfo => 'వ్యక్తిగత సమాచారం';

  @override
  String get fullName => 'పూర్తి పేరు';

  @override
  String get phone => 'ఫోన్';

  @override
  String get cannotBeChanged => 'మార్చలేరు';

  @override
  String get emergencyContact => 'అత్యవసర సంప్రదింపు';

  @override
  String get yourAccount => 'మీ ఖాతా';

  @override
  String get role => 'పాత్ర';

  @override
  String get owner => 'యజమాని';

  @override
  String get tenant => 'అద్దెకారి';

  @override
  String get status => 'స్థితి';

  @override
  String get active => 'క్రియాశీలం';

  @override
  String get appearance => 'రూపురేఖలు';

  @override
  String get darkMode => 'డార్క్ మోడ్';

  @override
  String get useDarkAppearanceAcrossApp =>
      'యాప్ అంతటా డార్క్ థీమ్‌ను ఉపయోగించండి';

  @override
  String get useDarkTheme => 'డార్క్ థీమ్‌ను ఉపయోగించండి';

  @override
  String get organization => 'సంస్థ';

  @override
  String get organizationDetails => 'సంస్థ వివరాలు';

  @override
  String get settings => 'సెట్టింగ్స్';

  @override
  String get editProfile => 'ప్రొఫైల్‌ను సవరించు';

  @override
  String get stayInfo => 'నివాస సమాచారం';

  @override
  String get aadhaar => 'ఆధార్';

  @override
  String get checkIn => 'చెక్-ఇన్';

  @override
  String get verified => 'ధృవీకరించబడింది';

  @override
  String get pending => 'పెండింగ్';

  @override
  String get done => 'పూర్తైంది';

  @override
  String get inactive => 'క్రియారహితం';

  @override
  String get more => 'మరిన్ని';

  @override
  String get quickActions => 'త్వరిత చర్యలు';

  @override
  String get addTenant => 'అద్దెకారిని జోడించండి';

  @override
  String get addProperty => 'ఆస్తిని జోడించండి';

  @override
  String get kycReview => 'KYC సమీక్ష';

  @override
  String get reminders => 'గుర్తింపులు';

  @override
  String get noOrganizationSelected => 'ఏ సంస్థను ఎంచుకోలేదు';

  @override
  String get sendPaymentReminders => 'చెల్లింపు గుర్తింపులు పంపండి';

  @override
  String get send => 'పంపు';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count రోజులు',
      one: '1 రోజు',
    );
    return '$_temp0';
  }

  @override
  String get optionalMessage => 'ఐచ్ఛిక సందేశం';

  @override
  String get remindersQueued => 'రిమైండర్‌లు విజయవంతంగా క్యూలో ఉంచబడ్డాయి';

  @override
  String get notificationPreferences => 'నోటిఫికేషన్ ప్రాధాన్యతలు';

  @override
  String get languageAndRegion => 'భాష & ప్రాంతం';

  @override
  String get securityAndPassword => 'భద్రత & పాస్‌వర్డ్';

  @override
  String get privacyPolicy => 'గోప్యతా విధానం';

  @override
  String get helpAndSupport => 'సహాయం & మద్దతు';

  @override
  String get about => 'గురించి';

  @override
  String version(String version) {
    return 'వెర్షన్ $version';
  }

  @override
  String get avatarUpdated => 'అవతార్ నవీకరించబడింది!';

  @override
  String get photoUpdated => 'ఫోటో నవీకరించబడింది!';

  @override
  String get profileUpdated => 'ప్రొఫైల్ నవీకరించబడింది!';

  @override
  String uploadFailed(String error) {
    return 'అప్‌లోడ్ విఫలమైంది: $error';
  }

  @override
  String saveFailed(String error) {
    return 'సేవ్ చేయడం విఫలమైంది: $error';
  }

  @override
  String get selectLanguage => 'భాషను ఎంచుకోండి';

  @override
  String get chooseAppLanguage => 'యాప్ భాషను ఎంచుకోండి';

  @override
  String get systemDefault => 'సిస్టమ్ డిఫాల్ట్';

  @override
  String get currentLanguage => 'ప్రస్తుత భాష';

  @override
  String get english => 'ఇంగ్లీష్';

  @override
  String get hindi => 'హిందీ';

  @override
  String get telugu => 'తెలుగు';

  @override
  String get languageSaved => 'భాష సేవ్ చేయబడింది';

  @override
  String get verifyWithAadhaar => 'ఆధార్‌తో ధృవీకరించండి';

  @override
  String get uploadDocumentsFallback => 'పత్రాలు అప్‌లోడ్ చేయండి (వికల్పం)';

  @override
  String get startNewVerification => 'కొత్త ధృవీకరణ ప్రారంభించండి';

  @override
  String get retryVerification => 'ధృవీకరణను మళ్లీ ప్రయత్నించండి';

  @override
  String get uploadDocuments => 'పత్రాలు అప్‌లోడ్ చేయండి';

  @override
  String get submitForVerification => 'ధృవీకరణకు పంపండి';

  @override
  String get takePhoto => 'ఫోటో తీసుకోండి';

  @override
  String get chooseFromGallery => 'గ్యాలరీ నుండి ఎంచుకోండి';

  @override
  String get flagged => 'ఫ్లాగ్ చేయబడింది';

  @override
  String get unflagged => 'ఫ్లాగ్ చేయలేదు';

  @override
  String get previous => 'మునుపటి';

  @override
  String get next => 'తదుపరి';

  @override
  String get approve => 'ఆమోదించండి';

  @override
  String get reject => 'తిరస్కరించండి';

  @override
  String get viewDetails => 'వివరాలు చూడండి';

  @override
  String get assignBed => 'బెడ్ కేటాయించండి';

  @override
  String get recordPayment => 'చెల్లింపు నమోదు చేయండి';

  @override
  String get downloadPdf => 'PDF డౌన్‌లోడ్ చేయండి';

  @override
  String get generateInvoice => 'ఇన్వాయిస్ సృష్టించండి';

  @override
  String get successfullyQueued => 'విజయవంతంగా క్యూలో ఉంచబడ్డాయి';

  @override
  String get alreadySentToday => 'ఈరోజు ఇప్పటికే పంపబడింది';

  @override
  String get missingPhoneNo => 'ఫోన్ నంబర్ లేదు';
}
