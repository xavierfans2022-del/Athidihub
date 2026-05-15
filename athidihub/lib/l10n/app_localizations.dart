import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('te'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Athidihub'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @properties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// No description provided for @tenants.
  ///
  /// In en, this message translates to:
  /// **'Tenants'**
  String get tenants;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @errorLoadingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Error loading documents'**
  String get errorLoadingDocuments;

  /// No description provided for @uploadedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Uploaded Documents'**
  String get uploadedDocuments;

  /// No description provided for @verificationStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get verificationStatusTitle;

  /// No description provided for @statusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get statusNotStarted;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get statusVerified;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get statusUnderReview;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusRetryAvailable.
  ///
  /// In en, this message translates to:
  /// **'Retry Available'**
  String get statusRetryAvailable;

  /// No description provided for @completionProgress.
  ///
  /// In en, this message translates to:
  /// **'Completion Progress'**
  String get completionProgress;

  /// No description provided for @verificationInProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification in Progress'**
  String get verificationInProgressTitle;

  /// No description provided for @verificationInProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we verify your Aadhaar. This may take a few minutes.'**
  String get verificationInProgressSubtitle;

  /// No description provided for @kycVerifiedSuccessfullyTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC Verified Successfully'**
  String get kycVerifiedSuccessfullyTitle;

  /// No description provided for @kycVerifiedSuccessfullySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your identity has been verified. You can now proceed with check-in.'**
  String get kycVerifiedSuccessfullySubtitle;

  /// No description provided for @verificationRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Rejected'**
  String get verificationRejectedTitle;

  /// No description provided for @retryInitiated.
  ///
  /// In en, this message translates to:
  /// **'Retry initiated'**
  String get retryInitiated;

  /// No description provided for @startKycVerificationButton.
  ///
  /// In en, this message translates to:
  /// **'Start KYC Verification'**
  String get startKycVerificationButton;

  /// No description provided for @openDocumentUploadButton.
  ///
  /// In en, this message translates to:
  /// **'Open Document Upload'**
  String get openDocumentUploadButton;

  /// No description provided for @couldNotStartKyc.
  ///
  /// In en, this message translates to:
  /// **'Could not start KYC verification.'**
  String get couldNotStartKyc;

  /// No description provided for @invalidKycVerificationUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid KYC verification URL.'**
  String get invalidKycVerificationUrl;

  /// No description provided for @couldNotOpenKycVerificationPage.
  ///
  /// In en, this message translates to:
  /// **'Could not open KYC verification page.'**
  String get couldNotOpenKycVerificationPage;

  /// No description provided for @couldNotOpenDocument.
  ///
  /// In en, this message translates to:
  /// **'Could not open document'**
  String get couldNotOpenDocument;

  /// No description provided for @verifiedWithScore.
  ///
  /// In en, this message translates to:
  /// **'Verified ({score}%)'**
  String verifiedWithScore(int score);

  /// No description provided for @pendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Pending verification'**
  String get pendingVerification;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @reupload.
  ///
  /// In en, this message translates to:
  /// **'Re-upload'**
  String get reupload;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not Ready'**
  String get statusNotReady;

  /// No description provided for @aboutKycVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'About KYC Verification'**
  String get aboutKycVerificationTitle;

  /// No description provided for @aboutKycVerificationParagraph.
  ///
  /// In en, this message translates to:
  /// **'• KYC verification is required before check-in\n• We use secure Aadhaar verification for identity confirmation\n• Your data is encrypted and stored securely\n• Only the last 4 digits of Aadhaar are stored\n• Verification usually takes 5-10 minutes'**
  String get aboutKycVerificationParagraph;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @paidStatus.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidStatus;

  /// No description provided for @overdueStatus.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueStatus;

  /// No description provided for @filtered.
  ///
  /// In en, this message translates to:
  /// **'Filtered'**
  String get filtered;

  /// No description provided for @filterByMonth.
  ///
  /// In en, this message translates to:
  /// **'Filter by Month'**
  String get filterByMonth;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @searchInvoices.
  ///
  /// In en, this message translates to:
  /// **'Search by tenant name, email, phone...'**
  String get searchInvoices;

  /// No description provided for @pleaseSelectOrganizationFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select an organization first'**
  String get pleaseSelectOrganizationFirst;

  /// No description provided for @sendBulkReminders.
  ///
  /// In en, this message translates to:
  /// **'Send Bulk Reminders'**
  String get sendBulkReminders;

  /// No description provided for @sendPersonalizedWhatsAppReminders.
  ///
  /// In en, this message translates to:
  /// **'Send personalized WhatsApp reminders'**
  String get sendPersonalizedWhatsAppReminders;

  /// No description provided for @includeOverdue.
  ///
  /// In en, this message translates to:
  /// **'Include overdue'**
  String get includeOverdue;

  /// No description provided for @remindForPastDueDates.
  ///
  /// In en, this message translates to:
  /// **'Remind for past due dates'**
  String get remindForPastDueDates;

  /// No description provided for @dueWindow.
  ///
  /// In en, this message translates to:
  /// **'Due window'**
  String get dueWindow;

  /// No description provided for @dueWithinDays.
  ///
  /// In en, this message translates to:
  /// **'Due within {days} days'**
  String dueWithinDays(int days);

  /// No description provided for @queuingWhatsAppMessages.
  ///
  /// In en, this message translates to:
  /// **'Queuing WhatsApp messages'**
  String get queuingWhatsAppMessages;

  /// No description provided for @thisMayTakeAMoment.
  ///
  /// In en, this message translates to:
  /// **'This may take a moment'**
  String get thisMayTakeAMoment;

  /// No description provided for @failedToSendReminders.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reminders'**
  String get failedToSendReminders;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @sendNow.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get sendNow;

  /// No description provided for @couldNotLoadInvoices.
  ///
  /// In en, this message translates to:
  /// **'Could not load invoices'**
  String get couldNotLoadInvoices;

  /// No description provided for @noInvoicesFound.
  ///
  /// In en, this message translates to:
  /// **'No invoices found'**
  String get noInvoicesFound;

  /// No description provided for @tryDifferentSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearchTerm;

  /// No description provided for @invoicesWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Invoices will appear here'**
  String get invoicesWillAppearHere;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due {dueDate}'**
  String due(String dueDate);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @portfolioOverview.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your portfolio overview'**
  String get portfolioOverview;

  /// No description provided for @occupancy.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get occupancy;

  /// No description provided for @vacantBeds.
  ///
  /// In en, this message translates to:
  /// **'Vacant Beds'**
  String get vacantBeds;

  /// No description provided for @revenueLastSixMonths.
  ///
  /// In en, this message translates to:
  /// **'Revenue (6 months)'**
  String get revenueLastSixMonths;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @setUpYourOrganization.
  ///
  /// In en, this message translates to:
  /// **'Set up your organization'**
  String get setUpYourOrganization;

  /// No description provided for @createYourOrganizationDescription.
  ///
  /// In en, this message translates to:
  /// **'Create your organization to unlock properties, rooms, tenants, billing, and analytics.'**
  String get createYourOrganizationDescription;

  /// No description provided for @createOrganization.
  ///
  /// In en, this message translates to:
  /// **'Create Organization'**
  String get createOrganization;

  /// No description provided for @couldNotLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Could not load dashboard'**
  String get couldNotLoadDashboard;

  /// No description provided for @monthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue'**
  String get monthlyRevenue;

  /// No description provided for @fromLastMonth.
  ///
  /// In en, this message translates to:
  /// **'↑ 12% from last month'**
  String get fromLastMonth;

  /// No description provided for @noRecentActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No recent activity yet.'**
  String get noRecentActivityYet;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @pleaseWaitBeforeRefreshingAgain.
  ///
  /// In en, this message translates to:
  /// **'Please wait {seconds} seconds before refreshing again'**
  String pleaseWaitBeforeRefreshingAgain(int seconds);

  /// No description provided for @dataRefreshedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Data refreshed successfully'**
  String get dataRefreshedSuccessfully;

  /// No description provided for @failedToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh: {error}'**
  String failedToRefresh(String error);

  /// No description provided for @webView.
  ///
  /// In en, this message translates to:
  /// **'Web View'**
  String get webView;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorPrefix(String message);

  /// No description provided for @pressBackAgainToExitApp.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit app'**
  String get pressBackAgainToExitApp;

  /// No description provided for @pressBackAgainToExitPortal.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExitPortal;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutTitle;

  /// No description provided for @signOutMessage.
  ///
  /// In en, this message translates to:
  /// **'You will be logged out of your account.\nAny unsaved changes will be lost.'**
  String get signOutMessage;

  /// No description provided for @tenantPortalSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of tenant portal?'**
  String get tenantPortalSignOutTitle;

  /// No description provided for @tenantPortalSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be logged out from this device and returned to the login screen.'**
  String get tenantPortalSignOutMessage;

  /// No description provided for @unsavedProfileChangesLost.
  ///
  /// In en, this message translates to:
  /// **'Any unsaved profile changes will be lost.'**
  String get unsavedProfileChangesLost;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @cannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Cannot be changed'**
  String get cannotBeChanged;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContact;

  /// No description provided for @yourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your Account'**
  String get yourAccount;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @tenant.
  ///
  /// In en, this message translates to:
  /// **'Tenant'**
  String get tenant;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @useDarkAppearanceAcrossApp.
  ///
  /// In en, this message translates to:
  /// **'Use the dark appearance across the app'**
  String get useDarkAppearanceAcrossApp;

  /// No description provided for @useDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get useDarkTheme;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// No description provided for @organizationDetails.
  ///
  /// In en, this message translates to:
  /// **'Organization Details'**
  String get organizationDetails;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @stayInfo.
  ///
  /// In en, this message translates to:
  /// **'Stay Info'**
  String get stayInfo;

  /// No description provided for @aadhaar.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar'**
  String get aadhaar;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-In'**
  String get checkIn;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @addTenant.
  ///
  /// In en, this message translates to:
  /// **'Add Tenant'**
  String get addTenant;

  /// No description provided for @addProperty.
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get addProperty;

  /// No description provided for @kycReview.
  ///
  /// In en, this message translates to:
  /// **'KYC Review'**
  String get kycReview;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @noOrganizationSelected.
  ///
  /// In en, this message translates to:
  /// **'No organization selected'**
  String get noOrganizationSelected;

  /// No description provided for @sendPaymentReminders.
  ///
  /// In en, this message translates to:
  /// **'Send Payment Reminders'**
  String get sendPaymentReminders;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// No description provided for @optionalMessage.
  ///
  /// In en, this message translates to:
  /// **'Optional message'**
  String get optionalMessage;

  /// No description provided for @remindersQueued.
  ///
  /// In en, this message translates to:
  /// **'Reminders queued successfully'**
  String get remindersQueued;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// No description provided for @languageAndRegion.
  ///
  /// In en, this message translates to:
  /// **'Language & Region'**
  String get languageAndRegion;

  /// No description provided for @securityAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Security & Password'**
  String get securityAndPassword;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated!'**
  String get avatarUpdated;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated!'**
  String get photoUpdated;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileUpdated;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailed(String error);

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(String error);

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @chooseAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language'**
  String get chooseAppLanguage;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @currentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Current language'**
  String get currentLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @telugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get telugu;

  /// No description provided for @languageSaved.
  ///
  /// In en, this message translates to:
  /// **'Language saved'**
  String get languageSaved;

  /// No description provided for @verifyWithAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Verify with Aadhaar'**
  String get verifyWithAadhaar;

  /// No description provided for @uploadDocumentsFallback.
  ///
  /// In en, this message translates to:
  /// **'Upload Documents (Fallback)'**
  String get uploadDocumentsFallback;

  /// No description provided for @startNewVerification.
  ///
  /// In en, this message translates to:
  /// **'Start New Verification'**
  String get startNewVerification;

  /// No description provided for @retryVerification.
  ///
  /// In en, this message translates to:
  /// **'Retry Verification'**
  String get retryVerification;

  /// No description provided for @uploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload Documents'**
  String get uploadDocuments;

  /// No description provided for @submitForVerification.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get submitForVerification;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @flagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get flagged;

  /// No description provided for @unflagged.
  ///
  /// In en, this message translates to:
  /// **'Unflagged'**
  String get unflagged;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @assignBed.
  ///
  /// In en, this message translates to:
  /// **'Assign Bed'**
  String get assignBed;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @generateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Generate Invoice'**
  String get generateInvoice;

  /// No description provided for @successfullyQueued.
  ///
  /// In en, this message translates to:
  /// **'Successfully queued'**
  String get successfullyQueued;

  /// No description provided for @alreadySentToday.
  ///
  /// In en, this message translates to:
  /// **'Already sent today'**
  String get alreadySentToday;

  /// No description provided for @missingPhoneNo.
  ///
  /// In en, this message translates to:
  /// **'Missing phone number'**
  String get missingPhoneNo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
