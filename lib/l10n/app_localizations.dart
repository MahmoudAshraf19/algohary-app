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
