// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'अथिदिहब';

  @override
  String get home => 'होम';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get properties => 'प्रॉपर्टी';

  @override
  String get tenants => 'किरायेदार';

  @override
  String get invoices => 'इनवॉइस';

  @override
  String get payments => 'भुगतान';

  @override
  String get maintenance => 'मेंटेनेंस';

  @override
  String get documents => 'दस्तावेज़';

  @override
  String get errorLoadingDocuments => 'दस्तावेज़ लोड नहीं हो सके';

  @override
  String get uploadedDocuments => 'अपलोड किए गए दस्तावेज़';

  @override
  String get verificationStatusTitle => 'सत्यापन स्थिति';

  @override
  String get statusNotStarted => 'शुरू नहीं हुआ';

  @override
  String get statusInProgress => 'प्रगति में';

  @override
  String get statusVerified => 'सत्यापित';

  @override
  String get statusRejected => 'अस्वीकृत';

  @override
  String get statusUnderReview => 'समीक्षा के अंतर्गत';

  @override
  String get statusExpired => 'समाप्त';

  @override
  String get statusRetryAvailable => 'पुनः प्रयास उपलब्ध';

  @override
  String get completionProgress => 'समाप्ति प्रगति';

  @override
  String get verificationInProgressTitle => 'सत्यापन प्रगति में';

  @override
  String get verificationInProgressSubtitle =>
      'कृपया प्रतीक्षा करें जबकि हम आपका आधार सत्यापित कर रहे हैं। इसमें कुछ मिनट लग सकते हैं।';

  @override
  String get kycVerifiedSuccessfullyTitle => 'KYC सफलतापूर्वक सत्यापित';

  @override
  String get kycVerifiedSuccessfullySubtitle =>
      'आपकी पहचान सत्यापित हो गई है। आप अब चेक-इन जारी रख सकते हैं।';

  @override
  String get verificationRejectedTitle => 'सत्यापन अस्वीकृत';

  @override
  String get retryInitiated => 'पुनः प्रयास आरंभ किया गया';

  @override
  String get startKycVerificationButton => 'KYC सत्यापन शुरू करें';

  @override
  String get openDocumentUploadButton => 'दस्तावेज़ अपलोड खोलें';

  @override
  String get couldNotStartKyc => 'KYC सत्यापन शुरू नहीं किया जा सका।';

  @override
  String get invalidKycVerificationUrl => 'अमान्य KYC सत्यापन URL।';

  @override
  String get couldNotOpenKycVerificationPage =>
      'KYC सत्यापन पृष्ठ खोलने में विफल।';

  @override
  String get couldNotOpenDocument => 'दस्तावेज़ खोलने में विफल';

  @override
  String verifiedWithScore(int score) {
    return 'सत्यापित ($score%)';
  }

  @override
  String get pendingVerification => 'सत्यापन प्रतीक्षारत';

  @override
  String get view => 'देखें';

  @override
  String get reupload => 'पुनः अपलोड करें';

  @override
  String get statusReady => 'तैयार';

  @override
  String get statusPending => 'लंबित';

  @override
  String get statusNotReady => 'तैयार नहीं';

  @override
  String get aboutKycVerificationTitle => 'KYC सत्यापन के बारे में';

  @override
  String get aboutKycVerificationParagraph =>
      '• चेक-इन से पहले KYC सत्यापन आवश्यक है\n• पहचान पुष्टि के लिए हम सुरक्षित आधार सत्यापन का उपयोग करते हैं\n• आपका डेटा एन्क्रिप्टेड और सुरक्षित रूप से संग्रहीत है\n• केवल आधार के अंतिम 4 अंक संग्रहीत किए जाते हैं\n• सत्यापन आमतौर पर 5-10 मिनट लेता है';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get all => 'सभी';

  @override
  String get pendingStatus => 'लंबित';

  @override
  String get paidStatus => 'भुगतान किया गया';

  @override
  String get overdueStatus => 'देय';

  @override
  String get filtered => 'फ़िल्टर किया गया';

  @override
  String get filterByMonth => 'महीने के अनुसार फ़िल्टर करें';

  @override
  String get clear => 'साफ करें';

  @override
  String get apply => 'लागू करें';

  @override
  String get searchInvoices => 'किरायेदार का नाम, ईमेल, फ़ोन से खोजें...';

  @override
  String get pleaseSelectOrganizationFirst => 'कृपया पहले एक संगठन चुनें';

  @override
  String get sendBulkReminders => 'बल्क अनुस्मारक भेजें';

  @override
  String get sendPersonalizedWhatsAppReminders =>
      'व्यक्तिगत व्हाट्सएप रिमाइंडर भेजें';

  @override
  String get includeOverdue => 'बकाया शामिल करें';

  @override
  String get remindForPastDueDates => 'पिछली देय तिथियों के लिए याद दिलाएं';

  @override
  String get dueWindow => 'देय अवधि';

  @override
  String dueWithinDays(int days) {
    return '$days दिनों के भीतर देय';
  }

  @override
  String get queuingWhatsAppMessages =>
      'व्हाट्सएप संदेश कतारबद्ध किए जा रहे हैं';

  @override
  String get thisMayTakeAMoment => 'इसमें थोड़ा समय लग सकता है';

  @override
  String get failedToSendReminders => 'रिमाइंडर भेजने में विफल';

  @override
  String get close => 'बंद करें';

  @override
  String get sendNow => 'अभी भेजें';

  @override
  String get couldNotLoadInvoices => 'इनवॉइस लोड नहीं हो सके';

  @override
  String get noInvoicesFound => 'कोई इनवॉइस नहीं मिला';

  @override
  String get tryDifferentSearchTerm => 'कोई अलग खोज शब्द आज़माएँ';

  @override
  String get invoicesWillAppearHere => 'इनवॉइस यहां दिखाई देंगे';

  @override
  String get payNow => 'अभी भुगतान करें';

  @override
  String get paid => 'भुगतान किया गया';

  @override
  String due(String dueDate) {
    return 'देय $dueDate';
  }

  @override
  String get refresh => 'रीफ़्रेश';

  @override
  String get refreshing => 'रीफ़्रेश हो रहा है...';

  @override
  String get goodMorning => 'सुप्रभात';

  @override
  String get goodAfternoon => 'नमस्कार';

  @override
  String get goodEvening => 'शुभ संध्या';

  @override
  String get portfolioOverview => 'यहां आपके पोर्टफोलियो का अवलोकन है';

  @override
  String get occupancy => 'अधिभोग';

  @override
  String get vacantBeds => 'खाली बेड';

  @override
  String get revenueLastSixMonths => 'राजस्व (6 महीने)';

  @override
  String get recentActivity => 'हाल की गतिविधि';

  @override
  String get setUpYourOrganization => 'अपना संगठन सेट करें';

  @override
  String get createYourOrganizationDescription =>
      'प्रॉपर्टी, रूम, किरायेदार, बिलिंग और एनालिटिक्स अनलॉक करने के लिए अपना संगठन बनाएं।';

  @override
  String get createOrganization => 'संगठन बनाएं';

  @override
  String get couldNotLoadDashboard => 'डैशबोर्ड लोड नहीं हो सका';

  @override
  String get monthlyRevenue => 'मासिक राजस्व';

  @override
  String get fromLastMonth => 'पिछले महीने से ↑ 12%';

  @override
  String get noRecentActivityYet => 'अभी तक कोई हालिया गतिविधि नहीं है।';

  @override
  String get justNow => 'अभी अभी';

  @override
  String minutesAgo(int minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours घंटे पहले';
  }

  @override
  String daysAgo(int days) {
    return '$days दिन पहले';
  }

  @override
  String pleaseWaitBeforeRefreshingAgain(int seconds) {
    return 'कृपया फिर से रीफ़्रेश करने से पहले $seconds सेकंड प्रतीक्षा करें';
  }

  @override
  String get dataRefreshedSuccessfully => 'डेटा सफलतापूर्वक रीफ़्रेश हो गया';

  @override
  String failedToRefresh(String error) {
    return 'रीफ़्रेश करने में विफल: $error';
  }

  @override
  String get webView => 'वेब व्यू';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String errorPrefix(String message) {
    return 'त्रुटि: $message';
  }

  @override
  String get pressBackAgainToExitApp =>
      'ऐप से बाहर निकलने के लिए फिर से बैक दबाएँ';

  @override
  String get pressBackAgainToExitPortal =>
      'बाहर निकलने के लिए फिर से बैक दबाएँ';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get signOutTitle => 'साइन आउट';

  @override
  String get signOutMessage =>
      'आप अपने खाते से लॉग आउट हो जाएंगे।\nकोई भी बिना सहेजे बदलाव खो जाएंगे।';

  @override
  String get tenantPortalSignOutTitle => 'टेनेंट पोर्टल से साइन आउट करें?';

  @override
  String get tenantPortalSignOutMessage =>
      'आप इस डिवाइस से लॉग आउट हो जाएंगे और लॉगिन स्क्रीन पर लौट आएंगे।';

  @override
  String get unsavedProfileChangesLost =>
      'कोई भी बिना सहेजे प्रोफ़ाइल बदलाव खो जाएंगे।';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get edit => 'संपादित करें';

  @override
  String get save => 'सहेजें';

  @override
  String get personalInfo => 'व्यक्तिगत जानकारी';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get phone => 'फ़ोन';

  @override
  String get cannotBeChanged => 'बदला नहीं जा सकता';

  @override
  String get emergencyContact => 'आपातकालीन संपर्क';

  @override
  String get yourAccount => 'आपका खाता';

  @override
  String get role => 'भूमिका';

  @override
  String get owner => 'मालिक';

  @override
  String get tenant => 'किरायेदार';

  @override
  String get status => 'स्थिति';

  @override
  String get active => 'सक्रिय';

  @override
  String get appearance => 'दिखावट';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get useDarkAppearanceAcrossApp =>
      'पूरे ऐप में डार्क थीम का उपयोग करें';

  @override
  String get useDarkTheme => 'डार्क थीम का उपयोग करें';

  @override
  String get organization => 'संगठन';

  @override
  String get organizationDetails => 'संगठन विवरण';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get stayInfo => 'रहने की जानकारी';

  @override
  String get aadhaar => 'आधार';

  @override
  String get checkIn => 'चेक-इन';

  @override
  String get verified => 'सत्यापित';

  @override
  String get pending => 'लंबित';

  @override
  String get done => 'पूरा';

  @override
  String get inactive => 'निष्क्रिय';

  @override
  String get more => 'और';

  @override
  String get quickActions => 'त्वरित कार्य';

  @override
  String get addTenant => 'किरायेदार जोड़ें';

  @override
  String get addProperty => 'प्रॉपर्टी जोड़ें';

  @override
  String get kycReview => 'KYC समीक्षा';

  @override
  String get reminders => 'अनुस्मारक';

  @override
  String get noOrganizationSelected => 'कोई संगठन चयनित नहीं है';

  @override
  String get sendPaymentReminders => 'भुगतान अनुस्मारक भेजें';

  @override
  String get send => 'भेजें';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन',
      one: '1 दिन',
    );
    return '$_temp0';
  }

  @override
  String get optionalMessage => 'वैकल्पिक संदेश';

  @override
  String get remindersQueued => 'रिमाइंडर सफलतापूर्वक कतारबद्ध किए गए';

  @override
  String get notificationPreferences => 'सूचना प्राथमिकताएँ';

  @override
  String get languageAndRegion => 'भाषा और क्षेत्र';

  @override
  String get securityAndPassword => 'सुरक्षा और पासवर्ड';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get helpAndSupport => 'सहायता और समर्थन';

  @override
  String get about => 'जानकारी';

  @override
  String version(String version) {
    return 'संस्करण $version';
  }

  @override
  String get avatarUpdated => 'अवतार अपडेट किया गया!';

  @override
  String get photoUpdated => 'फ़ोटो अपडेट की गई!';

  @override
  String get profileUpdated => 'प्रोफ़ाइल अपडेट की गई!';

  @override
  String uploadFailed(String error) {
    return 'अपलोड विफल: $error';
  }

  @override
  String saveFailed(String error) {
    return 'सहेजना विफल: $error';
  }

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get chooseAppLanguage => 'ऐप की भाषा चुनें';

  @override
  String get systemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get currentLanguage => 'वर्तमान भाषा';

  @override
  String get english => 'अंग्रेज़ी';

  @override
  String get hindi => 'हिंदी';

  @override
  String get telugu => 'तेलुगु';

  @override
  String get languageSaved => 'भाषा सहेजी गई';

  @override
  String get verifyWithAadhaar => 'आधार से सत्यापित करें';

  @override
  String get uploadDocumentsFallback => 'दस्तावेज़ अपलोड करें (वैकल्पिक)';

  @override
  String get startNewVerification => 'नई सत्यापन प्रक्रिया शुरू करें';

  @override
  String get retryVerification => 'सत्यापन पुनः प्रयास करें';

  @override
  String get uploadDocuments => 'दस्तावेज़ अपलोड करें';

  @override
  String get submitForVerification => 'सत्यापन के लिए भेजें';

  @override
  String get takePhoto => 'फ़ोटो लें';

  @override
  String get chooseFromGallery => 'गैलरी से चुनें';

  @override
  String get flagged => 'चिह्नित';

  @override
  String get unflagged => 'अचिह्नित';

  @override
  String get previous => 'पिछला';

  @override
  String get next => 'अगला';

  @override
  String get approve => 'स्वीकृत करें';

  @override
  String get reject => 'अस्वीकार करें';

  @override
  String get viewDetails => 'विवरण देखें';

  @override
  String get assignBed => 'बेड असाइन करें';

  @override
  String get recordPayment => 'भुगतान दर्ज करें';

  @override
  String get downloadPdf => 'PDF डाउनलोड करें';

  @override
  String get generateInvoice => 'इनवॉइस बनाएं';

  @override
  String get successfullyQueued => 'सफलतापूर्वक कतारबद्ध';

  @override
  String get alreadySentToday => 'आज पहले ही भेजा जा चुका है';

  @override
  String get missingPhoneNo => 'फ़ोन नंबर मौजूद नहीं है';
}
