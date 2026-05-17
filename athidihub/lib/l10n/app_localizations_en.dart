// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Athidihub';

  @override
  String get home => 'Home';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get properties => 'Properties';

  @override
  String get tenants => 'Tenants';

  @override
  String get invoices => 'Invoices';

  @override
  String get payments => 'Payments';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get documents => 'Documents';

  @override
  String get errorLoadingDocuments => 'Error loading documents';

  @override
  String get uploadedDocuments => 'Uploaded Documents';

  @override
  String get verificationStatusTitle => 'Verification Status';

  @override
  String get statusNotStarted => 'Not Started';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusVerified => 'Verified';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusUnderReview => 'Under Review';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusRetryAvailable => 'Retry Available';

  @override
  String get completionProgress => 'Completion Progress';

  @override
  String get verificationInProgressTitle => 'Verification in Progress';

  @override
  String get verificationInProgressSubtitle =>
      'Please wait while we verify your Aadhaar. This may take a few minutes.';

  @override
  String get kycVerifiedSuccessfullyTitle => 'KYC Verified Successfully';

  @override
  String get kycVerifiedSuccessfullySubtitle =>
      'Your identity has been verified. You can now proceed with check-in.';

  @override
  String get verificationRejectedTitle => 'Verification Rejected';

  @override
  String get retryInitiated => 'Retry initiated';

  @override
  String get startKycVerificationButton => 'Start KYC Verification';

  @override
  String get openDocumentUploadButton => 'Open Document Upload';

  @override
  String get couldNotStartKyc => 'Could not start KYC verification.';

  @override
  String get invalidKycVerificationUrl => 'Invalid KYC verification URL.';

  @override
  String get couldNotOpenKycVerificationPage =>
      'Could not open KYC verification page.';

  @override
  String get couldNotOpenDocument => 'Could not open document';

  @override
  String verifiedWithScore(int score) {
    return 'Verified ($score%)';
  }

  @override
  String get pendingVerification => 'Pending verification';

  @override
  String get view => 'View';

  @override
  String get reupload => 'Re-upload';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusNotReady => 'Not Ready';

  @override
  String get aboutKycVerificationTitle => 'About KYC Verification';

  @override
  String get aboutKycVerificationParagraph =>
      '• KYC verification is required before check-in\n• We use secure Aadhaar verification for identity confirmation\n• Your data is encrypted and stored securely\n• Only the last 4 digits of Aadhaar are stored\n• Verification usually takes 5-10 minutes';

  @override
  String get profile => 'Profile';

  @override
  String get all => 'All';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get paidStatus => 'Paid';

  @override
  String get overdueStatus => 'Overdue';

  @override
  String get filtered => 'Filtered';

  @override
  String get filterByMonth => 'Filter by Month';

  @override
  String get clear => 'Clear';

  @override
  String get apply => 'Apply';

  @override
  String get searchInvoices => 'Search by tenant name, email, phone...';

  @override
  String get pleaseSelectOrganizationFirst =>
      'Please select an organization first';

  @override
  String get sendBulkReminders => 'Send Bulk Reminders';

  @override
  String get sendBulkCallReminders => 'Send Bulk Call Reminders';

  @override
  String get sendPersonalizedWhatsAppReminders =>
      'Send personalized WhatsApp reminders';

  @override
  String get sendPersonalizedCallReminders =>
      'Send personalized call reminders to all tenants with pending or overdue rent.';

  @override
  String get includeOverdue => 'Include overdue';

  @override
  String get remindForPastDueDates => 'Remind for past due dates';

  @override
  String get dueWindow => 'Due window';

  @override
  String dueWithinDays(int days) {
    return 'Due within $days days';
  }

  @override
  String get queuingWhatsAppMessages => 'Queuing WhatsApp messages';

  @override
  String get queuingCallReminders => 'Queuing call reminders...';

  @override
  String get thisMayTakeAMoment => 'This may take a moment';

  @override
  String get failedToSendReminders => 'Failed to send reminders';

  @override
  String get close => 'Close';

  @override
  String get sendNow => 'Send now';

  @override
  String get couldNotLoadInvoices => 'Could not load invoices';

  @override
  String get noInvoicesFound => 'No invoices found';

  @override
  String get tryDifferentSearchTerm => 'Try a different search term';

  @override
  String get invoicesWillAppearHere => 'Invoices will appear here';

  @override
  String get payNow => 'Pay Now';

  @override
  String get paid => 'Paid';

  @override
  String due(String dueDate) {
    return 'Due $dueDate';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get refreshing => 'Refreshing...';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get portfolioOverview => 'Here\'s your portfolio overview';

  @override
  String get occupancy => 'Occupancy';

  @override
  String get vacantBeds => 'Vacant Beds';

  @override
  String get revenueLastSixMonths => 'Revenue (6 months)';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get setUpYourOrganization => 'Set up your organization';

  @override
  String get createYourOrganizationDescription =>
      'Create your organization to unlock properties, rooms, tenants, billing, and analytics.';

  @override
  String get createOrganization => 'Create Organization';

  @override
  String get couldNotLoadDashboard => 'Could not load dashboard';

  @override
  String get monthlyRevenue => 'Monthly Revenue';

  @override
  String get fromLastMonth => '↑ 12% from last month';

  @override
  String get noRecentActivityYet => 'No recent activity yet.';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String pleaseWaitBeforeRefreshingAgain(int seconds) {
    return 'Please wait $seconds seconds before refreshing again';
  }

  @override
  String get dataRefreshedSuccessfully => 'Data refreshed successfully';

  @override
  String failedToRefresh(String error) {
    return 'Failed to refresh: $error';
  }

  @override
  String get webView => 'Web View';

  @override
  String get retry => 'Retry';

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get pressBackAgainToExitApp => 'Press back again to exit app';

  @override
  String get pressBackAgainToExitPortal => 'Press back again to exit';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutTitle => 'Sign Out';

  @override
  String get signOutMessage =>
      'You will be logged out of your account.\nAny unsaved changes will be lost.';

  @override
  String get tenantPortalSignOutTitle => 'Sign out of tenant portal?';

  @override
  String get tenantPortalSignOutMessage =>
      'You\'ll be logged out from this device and returned to the login screen.';

  @override
  String get unsavedProfileChangesLost =>
      'Any unsaved profile changes will be lost.';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get personalInfo => 'Personal Info';

  @override
  String get fullName => 'Full Name';

  @override
  String get phone => 'Phone';

  @override
  String get cannotBeChanged => 'Cannot be changed';

  @override
  String get emergencyContact => 'Emergency Contact';

  @override
  String get yourAccount => 'Your Account';

  @override
  String get role => 'Role';

  @override
  String get owner => 'Owner';

  @override
  String get tenant => 'Tenant';

  @override
  String get status => 'Status';

  @override
  String get active => 'Active';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get useDarkAppearanceAcrossApp =>
      'Use the dark appearance across the app';

  @override
  String get useDarkTheme => 'Use dark theme';

  @override
  String get organization => 'Organization';

  @override
  String get organizationDetails => 'Organization Details';

  @override
  String get settings => 'Settings';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get stayInfo => 'Stay Info';

  @override
  String get aadhaar => 'Aadhaar';

  @override
  String get checkIn => 'Check-In';

  @override
  String get verified => 'Verified';

  @override
  String get pending => 'Pending';

  @override
  String get done => 'Done';

  @override
  String get inactive => 'Inactive';

  @override
  String get more => 'More';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get addTenant => 'Add Tenant';

  @override
  String get addProperty => 'Add Property';

  @override
  String get kycReview => 'KYC Review';

  @override
  String get reminders => 'Reminders';

  @override
  String get noOrganizationSelected => 'No organization selected';

  @override
  String get sendPaymentReminders => 'Send Payment Reminders';

  @override
  String get send => 'Send';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get optionalMessage => 'Optional message';

  @override
  String get remindersQueued => 'Reminders queued successfully';

  @override
  String get notificationPreferences => 'Notification Preferences';

  @override
  String get languageAndRegion => 'Language & Region';

  @override
  String get securityAndPassword => 'Security & Password';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get about => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get avatarUpdated => 'Avatar updated!';

  @override
  String get photoUpdated => 'Photo updated!';

  @override
  String get profileUpdated => 'Profile updated!';

  @override
  String uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get selectLanguage => 'Select language';

  @override
  String get chooseAppLanguage => 'Choose the app language';

  @override
  String get systemDefault => 'System default';

  @override
  String get currentLanguage => 'Current language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get telugu => 'Telugu';

  @override
  String get languageSaved => 'Language saved';

  @override
  String get verifyWithAadhaar => 'Verify with Aadhaar';

  @override
  String get uploadDocumentsFallback => 'Upload Documents (Fallback)';

  @override
  String get startNewVerification => 'Start New Verification';

  @override
  String get retryVerification => 'Retry Verification';

  @override
  String get uploadDocuments => 'Upload Documents';

  @override
  String get submitForVerification => 'Submit for Verification';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get flagged => 'Flagged';

  @override
  String get unflagged => 'Unflagged';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get viewDetails => 'View Details';

  @override
  String get assignBed => 'Assign Bed';

  @override
  String get recordPayment => 'Record Payment';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get generateInvoice => 'Generate Invoice';

  @override
  String get callRemindersQueued => 'Call reminders queued successfully';

  @override
  String get successfullyQueued => 'Successfully queued';

  @override
  String get alreadySentToday => 'Already sent today';

  @override
  String get missingPhoneNo => 'Missing phone number';
}
