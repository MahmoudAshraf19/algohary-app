import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Al Gohary'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to our application!'**
  String get welcomeMessage;

  /// No description provided for @themeHint.
  ///
  /// In en, this message translates to:
  /// **'Notice how colors change with the theme.'**
  String get themeHint;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local Services. Trusted Professionals.'**
  String get splashSubtitle;

  /// No description provided for @onboarding1TitleTop.
  ///
  /// In en, this message translates to:
  /// **'Find the Right '**
  String get onboarding1TitleTop;

  /// No description provided for @onboarding1TitleAccent.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get onboarding1TitleAccent;

  /// No description provided for @onboarding1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Easily discover trusted local service providers for all your home and office needs.'**
  String get onboarding1Subtitle;

  /// No description provided for @onboarding2TitleTop.
  ///
  /// In en, this message translates to:
  /// **'Connect With '**
  String get onboarding2TitleTop;

  /// No description provided for @onboarding2TitleAccent.
  ///
  /// In en, this message translates to:
  /// **'Professionals'**
  String get onboarding2TitleAccent;

  /// No description provided for @onboarding2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat directly with service providers, ask questions and get all the details before booking.'**
  String get onboarding2Subtitle;

  /// No description provided for @onboarding3TitleTop.
  ///
  /// In en, this message translates to:
  /// **'Book When It '**
  String get onboarding3TitleTop;

  /// No description provided for @onboarding3TitleAccent.
  ///
  /// In en, this message translates to:
  /// **'Works for You'**
  String get onboarding3TitleAccent;

  /// No description provided for @onboarding3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a convenient date and time slot that fits your schedule.'**
  String get onboarding3Subtitle;

  /// No description provided for @btnNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get btnNext;

  /// No description provided for @btnSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get btnSkip;

  /// No description provided for @btnGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get btnGetStarted;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Get the Help You Need'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find trusted professionals for your everyday needs.'**
  String get welcomeSubtitle;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue'**
  String get loginSubtitle;

  /// No description provided for @loginEmailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or phone number'**
  String get loginEmailOrPhone;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// No description provided for @loginOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get loginOr;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get loginNoAccount;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get loginCreateAccount;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join us to get started'**
  String get signupSubtitle;

  /// No description provided for @signupFirstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get signupFirstName;

  /// No description provided for @signupLastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get signupLastName;

  /// No description provided for @signupEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get signupEmail;

  /// No description provided for @signupPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signupPassword;

  /// No description provided for @signupConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get signupConfirmPassword;

  /// No description provided for @signupButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signupButton;

  /// No description provided for @signupAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get signupAlreadyHaveAccount;

  /// No description provided for @signupLogin.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get signupLogin;

  /// No description provided for @signupPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get signupPasswordsDoNotMatch;

  /// No description provided for @errorRequiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get errorRequiredField;

  /// No description provided for @errorEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get errorEmailRequired;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get errorInvalidEmail;

  /// No description provided for @errorPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get errorPasswordRequired;

  /// No description provided for @errorPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get errorPasswordLength;

  /// No description provided for @errorConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm password'**
  String get errorConfirmPasswordRequired;

  /// No description provided for @errorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'Email already in use'**
  String get errorEmailAlreadyInUse;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, please try again later'**
  String get errorGeneric;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hi'**
  String get homeWelcome;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a service...'**
  String get homeSearchHint;

  /// No description provided for @homeLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating...'**
  String get homeLocating;

  /// No description provided for @homeLocationError.
  ///
  /// In en, this message translates to:
  /// **'Location not found'**
  String get homeLocationError;

  /// No description provided for @locationAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow Location Access'**
  String get locationAccessTitle;

  /// No description provided for @locationAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'We need your current location to show you nearby services and provide a better experience.'**
  String get locationAccessDesc;

  /// No description provided for @locationAccessAllowBtn.
  ///
  /// In en, this message translates to:
  /// **'Allow Location Access'**
  String get locationAccessAllowBtn;

  /// No description provided for @locationAccessMapBtn.
  ///
  /// In en, this message translates to:
  /// **'Choose on Map'**
  String get locationAccessMapBtn;

  /// No description provided for @locationAccessNotNowBtn.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get locationAccessNotNowBtn;

  /// No description provided for @mapSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a place...'**
  String get mapSearchHint;

  /// No description provided for @mapConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get mapConfirmBtn;

  /// No description provided for @homeBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Need a hand\nat home?'**
  String get homeBannerTitle;

  /// No description provided for @homeBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find trusted professionals\nnear you.'**
  String get homeBannerSubtitle;

  /// No description provided for @homeBannerButton.
  ///
  /// In en, this message translates to:
  /// **'Explore Services'**
  String get homeBannerButton;

  /// No description provided for @homePopularServices.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get homePopularServices;

  /// No description provided for @homePopularServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular Services'**
  String get homePopularServicesTitle;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get homeViewAll;

  /// No description provided for @providersForThisService.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get providersForThisService;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @noProvidersFound.
  ///
  /// In en, this message translates to:
  /// **'No providers found for this service'**
  String get noProvidersFound;

  /// No description provided for @verifiedProvider.
  ///
  /// In en, this message translates to:
  /// **'Verified Professional'**
  String get verifiedProvider;

  /// No description provided for @providerProfile.
  ///
  /// In en, this message translates to:
  /// **'Provider Profile'**
  String get providerProfile;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @chatNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Chat feature coming soon!'**
  String get chatNotImplemented;

  /// No description provided for @chatWithProvider.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatWithProvider;

  /// No description provided for @allCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategoriesTitle;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get noCategoriesFound;

  /// No description provided for @wizardRequestService.
  ///
  /// In en, this message translates to:
  /// **'Request Service'**
  String get wizardRequestService;

  /// No description provided for @wizardPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get wizardPrevious;

  /// No description provided for @wizardNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get wizardNext;

  /// No description provided for @wizardConfirmAndSubmit.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Submit'**
  String get wizardConfirmAndSubmit;

  /// No description provided for @wizardSelectAtLeastOneService.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one service'**
  String get wizardSelectAtLeastOneService;

  /// No description provided for @wizardSelectDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Please select date and time'**
  String get wizardSelectDateAndTime;

  /// No description provided for @wizardProvideLocation.
  ///
  /// In en, this message translates to:
  /// **'Please provide location details'**
  String get wizardProvideLocation;

  /// No description provided for @wizardConfirmContact.
  ///
  /// In en, this message translates to:
  /// **'Please confirm contacting the provider'**
  String get wizardConfirmContact;

  /// No description provided for @wizardEnterAgreedPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter agreed price'**
  String get wizardEnterAgreedPrice;

  /// No description provided for @wizardSubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request submitted successfully!'**
  String get wizardSubmitSuccess;

  /// No description provided for @wizardStep1Title.
  ///
  /// In en, this message translates to:
  /// **'What services do you need?'**
  String get wizardStep1Title;

  /// No description provided for @wizardStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the services you want to request from '**
  String get wizardStep1Subtitle;

  /// No description provided for @wizardNoServices.
  ///
  /// In en, this message translates to:
  /// **'This provider currently offers no services.'**
  String get wizardNoServices;

  /// No description provided for @wizardStep2Title.
  ///
  /// In en, this message translates to:
  /// **'When do you need the service?'**
  String get wizardStep2Title;

  /// No description provided for @wizardStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the suitable date and time'**
  String get wizardStep2Subtitle;

  /// No description provided for @wizardDateHint.
  ///
  /// In en, this message translates to:
  /// **'Date (e.g., 2026-09-30)'**
  String get wizardDateHint;

  /// No description provided for @wizardTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Time (e.g., 17:30)'**
  String get wizardTimeHint;

  /// No description provided for @wizardSaveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Save Schedule'**
  String get wizardSaveSchedule;

  /// No description provided for @wizardScheduleSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Schedule saved'**
  String get wizardScheduleSavedToast;

  /// No description provided for @wizardSavedScheduleText.
  ///
  /// In en, this message translates to:
  /// **'Saved Schedule: '**
  String get wizardSavedScheduleText;

  /// No description provided for @wizardStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Where do you need the service?'**
  String get wizardStep3Title;

  /// No description provided for @wizardStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your detailed address'**
  String get wizardStep3Subtitle;

  /// No description provided for @wizardAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Detailed Address (Street, Building, etc.)'**
  String get wizardAddressHint;

  /// No description provided for @wizardSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save Location'**
  String get wizardSaveLocation;

  /// No description provided for @wizardLocationSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Location saved'**
  String get wizardLocationSavedToast;

  /// No description provided for @wizardSavedLocationText.
  ///
  /// In en, this message translates to:
  /// **'Saved Location: '**
  String get wizardSavedLocationText;

  /// No description provided for @wizardStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Price & Agreement'**
  String get wizardStep4Title;

  /// No description provided for @wizardStep4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Please make sure you have contacted the provider to agree on the final price'**
  String get wizardStep4Subtitle;

  /// No description provided for @wizardContactNotice.
  ///
  /// In en, this message translates to:
  /// **'Note: Please contact the provider via chat before submitting the request to determine and confirm the price.'**
  String get wizardContactNotice;

  /// No description provided for @wizardContactCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I confirm that I have contacted the provider and agreed on the price.'**
  String get wizardContactCheckbox;

  /// No description provided for @wizardAgreedPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Agreed Price'**
  String get wizardAgreedPriceLabel;

  /// No description provided for @wizardStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Review Request'**
  String get wizardStep5Title;

  /// No description provided for @wizardStep5Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Please review your request details before submitting'**
  String get wizardStep5Subtitle;

  /// No description provided for @wizardSummaryServices.
  ///
  /// In en, this message translates to:
  /// **'Selected Services'**
  String get wizardSummaryServices;

  /// No description provided for @wizardSummarySchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get wizardSummarySchedule;

  /// No description provided for @wizardNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get wizardNotSpecified;

  /// No description provided for @wizardSummaryLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get wizardSummaryLocation;

  /// No description provided for @wizardSummaryPrice.
  ///
  /// In en, this message translates to:
  /// **'Agreed Price'**
  String get wizardSummaryPrice;

  /// No description provided for @aboutProvider.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutProvider;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @messageProvider.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageProvider;

  /// No description provided for @reportProvider.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportProvider;

  /// No description provided for @requestService.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get requestService;

  /// No description provided for @chatsNoChats.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get chatsNoChats;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settingsChangePassword;

  /// No description provided for @settingsEmailPreferences.
  ///
  /// In en, this message translates to:
  /// **'Email Preferences'**
  String get settingsEmailPreferences;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get settingsPushNotifications;

  /// No description provided for @settingsMessageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Message Notifications'**
  String get settingsMessageNotifications;

  /// No description provided for @settingsAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settingsAppSettings;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// No description provided for @settingsHelpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help and Support'**
  String get settingsHelpAndSupport;

  /// No description provided for @settingsAboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get settingsAboutApp;

  /// No description provided for @settingsSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settingsSelectLanguage;

  /// No description provided for @settingsEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsEnglish;

  /// No description provided for @settingsArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get settingsArabic;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @errorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect current password'**
  String get errorWrongPassword;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'The new password is too weak'**
  String get errorWeakPassword;

  /// No description provided for @errorRequiresRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please log out and log in again to perform this action'**
  String get errorRequiresRecentLogin;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
