import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
    Locale('hi'),
  ];

  /// No description provided for @aboutThisPlan.
  ///
  /// In en, this message translates to:
  /// **'About this Plan'**
  String get aboutThisPlan;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @acceptOrderConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to accept this order? You will be responsible for fulfilling it.'**
  String get acceptOrderConfirmation;

  /// No description provided for @acceptOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept Order'**
  String get acceptOrderTitle;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @accountAndUsers.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT & USERS'**
  String get accountAndUsers;

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account Created Successfully'**
  String get accountCreatedSuccess;

  /// No description provided for @accountHolderName.
  ///
  /// In en, this message translates to:
  /// **'Account Holder Name'**
  String get accountHolderName;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get accountNumber;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @active2.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get active2;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addAdditionalImages.
  ///
  /// In en, this message translates to:
  /// **'+ Add Additional Image'**
  String get addAdditionalImages;

  /// No description provided for @addAtLeastOneVariant.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one variant'**
  String get addAtLeastOneVariant;

  /// No description provided for @addAttribute.
  ///
  /// In en, this message translates to:
  /// **'Add Attribute'**
  String get addAttribute;

  /// No description provided for @addCustomFieldHelper.
  ///
  /// In en, this message translates to:
  /// **'Add any additional product information as key/value pairs.'**
  String get addCustomFieldHelper;

  /// No description provided for @addCustomSectionsWithFieldsUploadAnImage.
  ///
  /// In en, this message translates to:
  /// **'Add custom sections with fields. Upload an image for each field if needed.'**
  String get addCustomSectionsWithFieldsUploadAnImage;

  /// No description provided for @addFaq.
  ///
  /// In en, this message translates to:
  /// **'Add FAQ'**
  String get addFaq;

  /// No description provided for @addField.
  ///
  /// In en, this message translates to:
  /// **'Add Field'**
  String get addField;

  /// No description provided for @addForAccountAndEarnedPayments.
  ///
  /// In en, this message translates to:
  /// **'Add for account & earned payments'**
  String get addForAccountAndEarnedPayments;

  /// No description provided for @addMoreValues.
  ///
  /// In en, this message translates to:
  /// **'+ Add More Values'**
  String get addMoreValues;

  /// No description provided for @addMoreValues2.
  ///
  /// In en, this message translates to:
  /// **'Add More Values'**
  String get addMoreValues2;

  /// No description provided for @addNewProduct.
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get addNewProduct;

  /// No description provided for @addNewRole.
  ///
  /// In en, this message translates to:
  /// **'Add New Role'**
  String get addNewRole;

  /// No description provided for @addNewRole2.
  ///
  /// In en, this message translates to:
  /// **'Add new role'**
  String get addNewRole2;

  /// No description provided for @addNewUser.
  ///
  /// In en, this message translates to:
  /// **'Add New User'**
  String get addNewUser;

  /// No description provided for @addPermission.
  ///
  /// In en, this message translates to:
  /// **'Add Permissions'**
  String get addPermission;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @addProductsProcess.
  ///
  /// In en, this message translates to:
  /// **'Add Products Process'**
  String get addProductsProcess;

  /// No description provided for @addRole.
  ///
  /// In en, this message translates to:
  /// **'Add Role'**
  String get addRole;

  /// No description provided for @addSection.
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get addSection;

  /// No description provided for @addStore.
  ///
  /// In en, this message translates to:
  /// **'Add Store'**
  String get addStore;

  /// No description provided for @addValue.
  ///
  /// In en, this message translates to:
  /// **'Add Value'**
  String get addValue;

  /// No description provided for @addValue2.
  ///
  /// In en, this message translates to:
  /// **'Add value'**
  String get addValue2;

  /// No description provided for @addValues.
  ///
  /// In en, this message translates to:
  /// **'Add Values'**
  String get addValues;

  /// No description provided for @addedOn.
  ///
  /// In en, this message translates to:
  /// **'Added on'**
  String get addedOn;

  /// No description provided for @additionalImage.
  ///
  /// In en, this message translates to:
  /// **'Additional Image'**
  String get additionalImage;

  /// No description provided for @additionalImages.
  ///
  /// In en, this message translates to:
  /// **'Additional Images'**
  String get additionalImages;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addressProof.
  ///
  /// In en, this message translates to:
  /// **'Address Proof'**
  String get addressProof;

  /// No description provided for @administratorEditorEtc.
  ///
  /// In en, this message translates to:
  /// **'Administrator, Editor, etc.'**
  String get administratorEditorEtc;

  /// No description provided for @allVariantsMustHaveName.
  ///
  /// In en, this message translates to:
  /// **'All variants must have a variant name'**
  String get allVariantsMustHaveName;

  /// No description provided for @amountToWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Amount to Withdraw'**
  String get amountToWithdraw;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @answerLabel.
  ///
  /// In en, this message translates to:
  /// **'Answer:'**
  String get answerLabel;

  /// No description provided for @appUnderMaintenance.
  ///
  /// In en, this message translates to:
  /// **'App Under Maintenance'**
  String get appUnderMaintenance;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @articlesOfIncorporation.
  ///
  /// In en, this message translates to:
  /// **'Articles of Incorporation'**
  String get articlesOfIncorporation;

  /// No description provided for @attachmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachmentLabel;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @attribute.
  ///
  /// In en, this message translates to:
  /// **'Attribute'**
  String get attribute;

  /// No description provided for @attributeName.
  ///
  /// In en, this message translates to:
  /// **'Attribute Name'**
  String get attributeName;

  /// No description provided for @attributeValues.
  ///
  /// In en, this message translates to:
  /// **'Attribute Values'**
  String get attributeValues;

  /// No description provided for @attributes.
  ///
  /// In en, this message translates to:
  /// **'Attributes'**
  String get attributes;

  /// No description provided for @attributesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Product attributes'**
  String get attributesSubtitle;

  /// No description provided for @authorizedSignature.
  ///
  /// In en, this message translates to:
  /// **'Authorized Signature'**
  String get authorizedSignature;

  /// No description provided for @autoFetch.
  ///
  /// In en, this message translates to:
  /// **'Auto Fetch'**
  String get autoFetch;

  /// No description provided for @autoVerifiedSuccessfullyMessage.
  ///
  /// In en, this message translates to:
  /// **'Auto verified successfully'**
  String get autoVerifiedSuccessfullyMessage;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @availableForWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Available for Withdraw'**
  String get availableForWithdraw;

  /// No description provided for @averageTimetoPrepareanorderinminutes.
  ///
  /// In en, this message translates to:
  /// **'Average Time to Prepare an order (In minutes)'**
  String get averageTimetoPrepareanorderinminutes;

  /// No description provided for @awaitingStoreResponse.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Store Response'**
  String get awaitingStoreResponse;

  /// No description provided for @awaiting_store_response.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Store Response'**
  String get awaiting_store_response;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @badgeRecommended.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get badgeRecommended;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance: '**
  String get balance;

  /// No description provided for @bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bank;

  /// No description provided for @bankAccountType.
  ///
  /// In en, this message translates to:
  /// **'Bank Account Type'**
  String get bankAccountType;

  /// No description provided for @bankBranchCode.
  ///
  /// In en, this message translates to:
  /// **'Bank Branch Code'**
  String get bankBranchCode;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankName;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @barcodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Barcode is required'**
  String get barcodeRequired;

  /// No description provided for @barcodeRequiredForAllVariants.
  ///
  /// In en, this message translates to:
  /// **'Barcode is required for all variants'**
  String get barcodeRequiredForAllVariants;

  /// No description provided for @basePrepTime.
  ///
  /// In en, this message translates to:
  /// **'Base Prep Time'**
  String get basePrepTime;

  /// No description provided for @basePrepTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'Base preparation time is required'**
  String get basePrepTimeRequired;

  /// No description provided for @basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basic;

  /// No description provided for @bhuj.
  ///
  /// In en, this message translates to:
  /// **'Bhuj'**
  String get bhuj;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @brandCreated.
  ///
  /// In en, this message translates to:
  /// **'Created:'**
  String get brandCreated;

  /// No description provided for @brandProducts.
  ///
  /// In en, this message translates to:
  /// **'Products:'**
  String get brandProducts;

  /// No description provided for @brands.
  ///
  /// In en, this message translates to:
  /// **'Brands'**
  String get brands;

  /// No description provided for @brandsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add and manage brands'**
  String get brandsSubtitle;

  /// No description provided for @breadth.
  ///
  /// In en, this message translates to:
  /// **'Breadth'**
  String get breadth;

  /// No description provided for @breadthRequired.
  ///
  /// In en, this message translates to:
  /// **'Breadth is required'**
  String get breadthRequired;

  /// No description provided for @breadthRequiredForAllVariants.
  ///
  /// In en, this message translates to:
  /// **'Breadth is required for all variants'**
  String get breadthRequiredForAllVariants;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @businessLicense.
  ///
  /// In en, this message translates to:
  /// **'Business License'**
  String get businessLicense;

  /// No description provided for @buttonActivateThisPlan.
  ///
  /// In en, this message translates to:
  /// **'Activate This Plan'**
  String get buttonActivateThisPlan;

  /// No description provided for @buttonChoosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Plan'**
  String get buttonChoosePlan;

  /// No description provided for @buyPlan.
  ///
  /// In en, this message translates to:
  /// **'Buy Plan'**
  String get buyPlan;

  /// No description provided for @byDefaultMinimumQuantity.
  ///
  /// In en, this message translates to:
  /// **'By Default Minimum Quantity is 1'**
  String get byDefaultMinimumQuantity;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cancelableLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelable'**
  String get cancelableLabel;

  /// No description provided for @cancelableTill.
  ///
  /// In en, this message translates to:
  /// **'Cancelable Till'**
  String get cancelableTill;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @categoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage product categories'**
  String get categoriesSubtitle;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changing.
  ///
  /// In en, this message translates to:
  /// **'Changing...'**
  String get changing;

  /// No description provided for @checkAvailability.
  ///
  /// In en, this message translates to:
  /// **'Check Availability'**
  String get checkAvailability;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get checking;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collected;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'color'**
  String get color;

  /// No description provided for @completePreviousSteps.
  ///
  /// In en, this message translates to:
  /// **'Please complete the previous steps first'**
  String get completePreviousSteps;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmYourNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new password'**
  String get confirmYourNewPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @confirmYourPassword2.
  ///
  /// In en, this message translates to:
  /// **'Confirm Your Password'**
  String get confirmYourPassword2;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact Email'**
  String get contactEmail;

  /// No description provided for @contain.
  ///
  /// In en, this message translates to:
  /// **'Contain'**
  String get contain;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get continueText;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @costRequiredForStore.
  ///
  /// In en, this message translates to:
  /// **'Cost is required for store: {store}'**
  String costRequiredForStore(Object store);

  /// No description provided for @costRequiredForStoreVariant.
  ///
  /// In en, this message translates to:
  /// **'Cost is required for store {store} (Variant: {variant})'**
  String costRequiredForStoreVariant(Object store, Object variant);

  /// No description provided for @couldNotFindLocationWithQuery.
  ///
  /// In en, this message translates to:
  /// **'Could not find location: {query}'**
  String couldNotFindLocationWithQuery(Object query);

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @cover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cover;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get createNewAccount;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @customFields.
  ///
  /// In en, this message translates to:
  /// **'Custom Fields'**
  String get customFields;

  /// No description provided for @customProductSections.
  ///
  /// In en, this message translates to:
  /// **'Custom Product Sections'**
  String get customProductSections;

  /// No description provided for @customerInformation.
  ///
  /// In en, this message translates to:
  /// **'Customer Information'**
  String get customerInformation;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name :'**
  String get customerName;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @darkMessage.
  ///
  /// In en, this message translates to:
  /// **'Gentle on eyes in low light'**
  String get darkMessage;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(Object count);

  /// No description provided for @daysShort.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String daysShort(Object count);

  /// No description provided for @defaultLbl.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLbl;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAttribute.
  ///
  /// In en, this message translates to:
  /// **'Delete Attribute'**
  String get deleteAttribute;

  /// No description provided for @deleteAttributeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this attribute?'**
  String get deleteAttributeConfirmation;

  /// No description provided for @deleteAttributeValueConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this attribute value?'**
  String get deleteAttributeValueConfirmation;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @deleteProductConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this product?'**
  String get deleteProductConfirmation;

  /// No description provided for @deleteStore.
  ///
  /// In en, this message translates to:
  /// **'Delete Store'**
  String get deleteStore;

  /// No description provided for @deleteStoreButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteStoreButton;

  /// No description provided for @deleteStoreConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this store?'**
  String get deleteStoreConfirmation;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @deliveryType.
  ///
  /// In en, this message translates to:
  /// **'Delivery Type: '**
  String get deliveryType;

  /// No description provided for @deliveryTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Type :'**
  String get deliveryTypeLabel;

  /// No description provided for @deliveryZones.
  ///
  /// In en, this message translates to:
  /// **'Delivery Zones'**
  String get deliveryZones;

  /// No description provided for @deliveryZonesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your service coverage areas'**
  String get deliveryZonesSubtitle;

  /// No description provided for @dimensionsRequired.
  ///
  /// In en, this message translates to:
  /// **'Dimensions are required'**
  String get dimensionsRequired;

  /// No description provided for @disableLabel.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disableLabel;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have Account?'**
  String get dontHaveAccount;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @dragAndDropHint.
  ///
  /// In en, this message translates to:
  /// **'Drag & Drop your files or Browse'**
  String get dragAndDropHint;

  /// No description provided for @durationPerXDays.
  ///
  /// In en, this message translates to:
  /// **'/ {days} days'**
  String durationPerXDays(Object days);

  /// No description provided for @durationUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get durationUnlimited;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @earningsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View commissions & settlements'**
  String get earningsSubtitle;

  /// No description provided for @editAttribute.
  ///
  /// In en, this message translates to:
  /// **'Edit Attribute'**
  String get editAttribute;

  /// No description provided for @editLbl.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLbl;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @editRole.
  ///
  /// In en, this message translates to:
  /// **'Edit Role'**
  String get editRole;

  /// No description provided for @editStore.
  ///
  /// In en, this message translates to:
  /// **'Edit Store'**
  String get editStore;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @eg123ShreeComplexStationRoad.
  ///
  /// In en, this message translates to:
  /// **'e.g. 123, Shree Complex, Station Road'**
  String get eg123ShreeComplexStationRoad;

  /// No description provided for @eg23241999.
  ///
  /// In en, this message translates to:
  /// **'e.g. 23.241999'**
  String get eg23241999;

  /// No description provided for @eg370001.
  ///
  /// In en, this message translates to:
  /// **'e.g. 370001'**
  String get eg370001;

  /// No description provided for @eg69666881.
  ///
  /// In en, this message translates to:
  /// **'e.g. 69.666881'**
  String get eg69666881;

  /// No description provided for @eg7.
  ///
  /// In en, this message translates to:
  /// **'Eg. 7'**
  String get eg7;

  /// No description provided for @egAbcde1234f.
  ///
  /// In en, this message translates to:
  /// **'Eg. ABCDE1234F'**
  String get egAbcde1234f;

  /// No description provided for @egBhuj.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bhuj'**
  String get egBhuj;

  /// No description provided for @egFf0000.
  ///
  /// In en, this message translates to:
  /// **'e.g., #FF0000'**
  String get egFf0000;

  /// No description provided for @egGujarat.
  ///
  /// In en, this message translates to:
  /// **'e.g. Gujarat'**
  String get egGujarat;

  /// No description provided for @egIndia.
  ///
  /// In en, this message translates to:
  /// **'e.g. India'**
  String get egIndia;

  /// No description provided for @egNearBusStand.
  ///
  /// In en, this message translates to:
  /// **'e.g. Near Bus Stand'**
  String get egNearBusStand;

  /// No description provided for @egPan.
  ///
  /// In en, this message translates to:
  /// **'Eg. PAN'**
  String get egPan;

  /// No description provided for @egRed.
  ///
  /// In en, this message translates to:
  /// **'e.g., Red'**
  String get egRed;

  /// No description provided for @eligibleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account meets all requirements for this plan upgrade.'**
  String get eligibleSubtitle;

  /// No description provided for @eligibleTitle.
  ///
  /// In en, this message translates to:
  /// **'You are eligible!'**
  String get eligibleTitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @emailCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Email address cannot be changed'**
  String get emailCannotBeChanged;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email :'**
  String get emailLabel;

  /// No description provided for @enableLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enableLabel;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter Address'**
  String get enterAddress;

  /// No description provided for @enterAnswer.
  ///
  /// In en, this message translates to:
  /// **'Enter answer'**
  String get enterAnswer;

  /// No description provided for @enterBarcode.
  ///
  /// In en, this message translates to:
  /// **'Enter Barcode'**
  String get enterBarcode;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get enterCurrentPassword;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescription;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter Email'**
  String get enterEmail;

  /// No description provided for @enterEmail2.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get enterEmail2;

  /// No description provided for @enterHsnCode.
  ///
  /// In en, this message translates to:
  /// **'Enter HSN Code'**
  String get enterHsnCode;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter mobile number'**
  String get enterMobileNumber;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterName;

  /// No description provided for @enterName2.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName2;

  /// No description provided for @enterNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter Name (Optional)'**
  String get enterNameOptional;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @enterNickName.
  ///
  /// In en, this message translates to:
  /// **'Enter Nickname'**
  String get enterNickName;

  /// No description provided for @enterOrderPreparationTimeInMinutes.
  ///
  /// In en, this message translates to:
  /// **'Enter Order Preparation time in minutes'**
  String get enterOrderPreparationTimeInMinutes;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @enterOtpButton.
  ///
  /// In en, this message translates to:
  /// **'ENTER OTP'**
  String get enterOtpButton;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @enterPassword2.
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get enterPassword2;

  /// No description provided for @enterProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Product Title'**
  String get enterProductTitle;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter Quantity'**
  String get enterQuantity;

  /// No description provided for @enterQuestion.
  ///
  /// In en, this message translates to:
  /// **'Enter question'**
  String get enterQuestion;

  /// No description provided for @enterSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter section description'**
  String get enterSectionDescription;

  /// No description provided for @enterSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter section title'**
  String get enterSectionTitle;

  /// No description provided for @enterShortDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter short description'**
  String get enterShortDescription;

  /// No description provided for @enterSwatch.
  ///
  /// In en, this message translates to:
  /// **'Enter swatch'**
  String get enterSwatch;

  /// No description provided for @enterTags.
  ///
  /// In en, this message translates to:
  /// **'Enter tags'**
  String get enterTags;

  /// No description provided for @enterTimeInMinutes.
  ///
  /// In en, this message translates to:
  /// **'Enter time in minutes'**
  String get enterTimeInMinutes;

  /// No description provided for @enterTimingEgMonfri9am6pm.
  ///
  /// In en, this message translates to:
  /// **'Enter timing e.g. Mon-Fri 9am-6pm'**
  String get enterTimingEgMonfri9am6pm;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter title'**
  String get enterTitle;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @enterVisitingEgHi.
  ///
  /// In en, this message translates to:
  /// **'Enter Visiting e.g. Hi'**
  String get enterVisitingEgHi;

  /// No description provided for @enterWritingEgHi.
  ///
  /// In en, this message translates to:
  /// **'Enter Writing e.g. Hi'**
  String get enterWritingEgHi;

  /// No description provided for @enterYourCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get enterYourCurrentPassword;

  /// No description provided for @enterYourEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterYourEmailAddress;

  /// No description provided for @enterYourEmailAddress2.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Email Address'**
  String get enterYourEmailAddress2;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @enterYourMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get enterYourMobileNumber;

  /// No description provided for @enterYourNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get enterYourNewPassword;

  /// No description provided for @enterYoutubeUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter Youtube URL'**
  String get enterYoutubeUrl;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @errorLoadLocation.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load location'**
  String get errorLoadLocation;

  /// No description provided for @errorLoadLocationWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load location: {error}'**
  String errorLoadLocationWithDetail(Object error);

  /// No description provided for @errorWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetail(Object error);

  /// No description provided for @exampleemailcom.
  ///
  /// In en, this message translates to:
  /// **'example@email.com'**
  String get exampleemailcom;

  /// No description provided for @exception.
  ///
  /// In en, this message translates to:
  /// **'Exception: '**
  String get exception;

  /// No description provided for @exclusive.
  ///
  /// In en, this message translates to:
  /// **'Exclusive'**
  String get exclusive;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @failedToGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location:'**
  String get failedToGetLocation;

  /// No description provided for @failedToGetLocationWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location: {error}'**
  String failedToGetLocationWithDetail(Object error);

  /// No description provided for @failedToPurchaseSubscription.
  ///
  /// In en, this message translates to:
  /// **'Failed to purchase subscription'**
  String get failedToPurchaseSubscription;

  /// No description provided for @failedToRefreshProduct.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh product details'**
  String get failedToRefreshProduct;

  /// No description provided for @faqSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your product questions & answers'**
  String get faqSubtitle;

  /// No description provided for @faqsLabel.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get faqsLabel;

  /// No description provided for @featureProductCatalog.
  ///
  /// In en, this message translates to:
  /// **'Product Catalog'**
  String get featureProductCatalog;

  /// No description provided for @featureProducts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No products allowed} =1{Add 1 product} other{Add up to {count} products}}'**
  String featureProducts(num count);

  /// No description provided for @featureProductsUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Add unlimited products'**
  String get featureProductsUnlimited;

  /// No description provided for @featureRoles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No custom roles allowed} =1{Define 1 custom role} other{Define up to {count} roles}}'**
  String featureRoles(num count);

  /// No description provided for @featureRolesPermissions.
  ///
  /// In en, this message translates to:
  /// **'Roles & Permissions'**
  String get featureRolesPermissions;

  /// No description provided for @featureRolesUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Define unlimited roles'**
  String get featureRolesUnlimited;

  /// No description provided for @featureStoreManagement.
  ///
  /// In en, this message translates to:
  /// **'Store Management'**
  String get featureStoreManagement;

  /// No description provided for @featureStores.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No active stores allowed} =1{Manage 1 active store} other{Manage up to {count} active stores}}'**
  String featureStores(num count);

  /// No description provided for @featureStoresUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Manage unlimited stores'**
  String get featureStoresUnlimited;

  /// No description provided for @featureSystemUsers.
  ///
  /// In en, this message translates to:
  /// **'System Users'**
  String get featureSystemUsers;

  /// No description provided for @featureUsers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No system users allowed} =1{Collaborate with 1 user} other{Add up to {count} system users}}'**
  String featureUsers(num count);

  /// No description provided for @featureUsersUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Create unlimited system users'**
  String get featureUsersUnlimited;

  /// No description provided for @featureVariantProducts.
  ///
  /// In en, this message translates to:
  /// **'Variant Products'**
  String get featureVariantProducts;

  /// No description provided for @featureVariants.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No variant product allowed} =1{1 variant product} other{Up to {count} variant products}}'**
  String featureVariants(num count);

  /// No description provided for @featureVariantsUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited variant products'**
  String get featureVariantsUnlimited;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @featuredLabel.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featuredLabel;

  /// No description provided for @featuredProduct.
  ///
  /// In en, this message translates to:
  /// **'Featured Product'**
  String get featuredProduct;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Field name'**
  String get fieldName;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @fields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get fields;

  /// No description provided for @fillAllPasswordFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all password fields'**
  String get fillAllPasswordFields;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'FINANCE'**
  String get finance;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @fromMap.
  ///
  /// In en, this message translates to:
  /// **'From Map'**
  String get fromMap;

  /// No description provided for @fullDescriptionCompulsory.
  ///
  /// In en, this message translates to:
  /// **'Full description is compulsory'**
  String get fullDescriptionCompulsory;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @goOffline.
  ///
  /// In en, this message translates to:
  /// **'Go Offline'**
  String get goOffline;

  /// No description provided for @goOnline.
  ///
  /// In en, this message translates to:
  /// **'Go Online'**
  String get goOnline;

  /// No description provided for @growYourStoreOnline.
  ///
  /// In en, this message translates to:
  /// **'Grow Your Store Online'**
  String get growYourStoreOnline;

  /// No description provided for @guaranteeLabel.
  ///
  /// In en, this message translates to:
  /// **'Guarantee'**
  String get guaranteeLabel;

  /// No description provided for @guaranteePeriod.
  ///
  /// In en, this message translates to:
  /// **'Guarantee Period'**
  String get guaranteePeriod;

  /// No description provided for @guardName.
  ///
  /// In en, this message translates to:
  /// **'Guard Name: '**
  String get guardName;

  /// No description provided for @gujarat.
  ///
  /// In en, this message translates to:
  /// **'Gujarat'**
  String get gujarat;

  /// No description provided for @hdfcBank.
  ///
  /// In en, this message translates to:
  /// **'HDFC BANK'**
  String get hdfcBank;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @heightRequired.
  ///
  /// In en, this message translates to:
  /// **'Height is required'**
  String get heightRequired;

  /// No description provided for @heightRequiredForAllVariants.
  ///
  /// In en, this message translates to:
  /// **'Height is required for all variants'**
  String get heightRequiredForAllVariants;

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello World'**
  String get helloWorld;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(Object count);

  /// No description provided for @hsnCode.
  ///
  /// In en, this message translates to:
  /// **'HSN Code'**
  String get hsnCode;

  /// No description provided for @hyperLocal.
  ///
  /// In en, this message translates to:
  /// **'HYPER LOCAL'**
  String get hyperLocal;

  /// No description provided for @iWantMyMoney.
  ///
  /// In en, this message translates to:
  /// **'I want my money'**
  String get iWantMyMoney;

  /// No description provided for @identity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get identity;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @imageFit.
  ///
  /// In en, this message translates to:
  /// **'Image Fit'**
  String get imageFit;

  /// No description provided for @inStockCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock'**
  String inStockCount(Object count);

  /// No description provided for @inclusive.
  ///
  /// In en, this message translates to:
  /// **'Inclusive'**
  String get inclusive;

  /// No description provided for @india.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get india;

  /// No description provided for @indicator.
  ///
  /// In en, this message translates to:
  /// **'Indicator'**
  String get indicator;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @invalidPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid password'**
  String get invalidPasswordError;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @isAttachmentRequired.
  ///
  /// In en, this message translates to:
  /// **'Is Attachment Required'**
  String get isAttachmentRequired;

  /// No description provided for @isCancelable.
  ///
  /// In en, this message translates to:
  /// **'Is Cancelable'**
  String get isCancelable;

  /// No description provided for @isFor.
  ///
  /// In en, this message translates to:
  /// **'is for'**
  String get isFor;

  /// No description provided for @isReturnable.
  ///
  /// In en, this message translates to:
  /// **'Is Returnable'**
  String get isReturnable;

  /// No description provided for @johnDoe.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get johnDoe;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @landmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get landmark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @last_1_day.
  ///
  /// In en, this message translates to:
  /// **'Last 1 Day'**
  String get last_1_day;

  /// No description provided for @last_1_hour.
  ///
  /// In en, this message translates to:
  /// **'Last 1 Hour'**
  String get last_1_hour;

  /// No description provided for @last_30_days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last_30_days;

  /// No description provided for @last_30_minutes.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Minutes'**
  String get last_30_minutes;

  /// No description provided for @last_365_days.
  ///
  /// In en, this message translates to:
  /// **'Last 365 Days'**
  String get last_365_days;

  /// No description provided for @last_5_hours.
  ///
  /// In en, this message translates to:
  /// **'Last 5 Hours'**
  String get last_5_hours;

  /// No description provided for @last_7_days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last_7_days;

  /// No description provided for @lat.
  ///
  /// In en, this message translates to:
  /// **'Lat'**
  String get lat;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @leaveEmptyForUnlimitedQuantity.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for unlimited quantity'**
  String get leaveEmptyForUnlimitedQuantity;

  /// No description provided for @leaveEmptyForZeroTax.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for zero tax'**
  String get leaveEmptyForZeroTax;

  /// No description provided for @leftCount.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String leftCount(Object count);

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @length.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// No description provided for @lengthRequired.
  ///
  /// In en, this message translates to:
  /// **'Length is required'**
  String get lengthRequired;

  /// No description provided for @lengthRequiredForAllVariants.
  ///
  /// In en, this message translates to:
  /// **'Length is required for all variants'**
  String get lengthRequiredForAllVariants;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @lightMessage.
  ///
  /// In en, this message translates to:
  /// **'Classic bright theme'**
  String get lightMessage;

  /// No description provided for @limitReached.
  ///
  /// In en, this message translates to:
  /// **'You have reached your plan limit'**
  String get limitReached;

  /// No description provided for @limitUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get limitUnlimited;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @locationFetchedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Location fetched successfully!'**
  String get locationFetchedSuccess;

  /// No description provided for @locationFetchedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Location fetched successfully!'**
  String get locationFetchedSuccessfully;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Using default location.\nYou can still tap on map to choose.'**
  String get locationPermissionDeniedMessage;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login Successful'**
  String get loginSuccessful;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get logoutCancelButton;

  /// No description provided for @logoutConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Yes, Logout'**
  String get logoutConfirmButton;

  /// No description provided for @logoutConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out from your account?'**
  String get logoutConfirmationMessage;

  /// No description provided for @logoutConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmationTitle;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get logoutMessage;

  /// No description provided for @logoutSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Logout successful'**
  String get logoutSuccessful;

  /// No description provided for @long.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get long;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @low_stock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get low_stock;

  /// No description provided for @madeIn.
  ///
  /// In en, this message translates to:
  /// **'Made In'**
  String get madeIn;

  /// No description provided for @madeInLabel.
  ///
  /// In en, this message translates to:
  /// **'Made In'**
  String get madeInLabel;

  /// No description provided for @mainImage.
  ///
  /// In en, this message translates to:
  /// **'Main Image'**
  String get mainImage;

  /// No description provided for @mainProductImageCompulsory.
  ///
  /// In en, this message translates to:
  /// **'Main product image is compulsory'**
  String get mainProductImageCompulsory;

  /// No description provided for @maintenanceMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'re currently performing scheduled maintenance. Please check back soon.'**
  String get maintenanceMessage;

  /// No description provided for @manageOrdersSeamlessly.
  ///
  /// In en, this message translates to:
  /// **'Manage Orders Seamlessly'**
  String get manageOrdersSeamlessly;

  /// No description provided for @manageProduct.
  ///
  /// In en, this message translates to:
  /// **'Manage Product'**
  String get manageProduct;

  /// No description provided for @manageProductSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add, edit, and organize products'**
  String get manageProductSubtitle;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get markAllRead;

  /// No description provided for @markAsPrepared.
  ///
  /// In en, this message translates to:
  /// **'Mark as Prepared'**
  String get markAsPrepared;

  /// No description provided for @markAsPreparedConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirm that the order is ready for pickup. Delivery partner will be notified to collect the order.'**
  String get markAsPreparedConfirmation;

  /// No description provided for @markAsPreparedTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as Prepared'**
  String get markAsPreparedTitle;

  /// No description provided for @markAsPreparing.
  ///
  /// In en, this message translates to:
  /// **'Mark as Preparing'**
  String get markAsPreparing;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark Read'**
  String get markRead;

  /// No description provided for @markUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark Unread'**
  String get markUnread;

  /// No description provided for @minOrderQtyDivisibleByStep.
  ///
  /// In en, this message translates to:
  /// **'Minimum order quantity must be divisible by quantity step size'**
  String get minOrderQtyDivisibleByStep;

  /// No description provided for @minOrderQtyPositive.
  ///
  /// In en, this message translates to:
  /// **'Minimum order quantity must be a positive integer'**
  String get minOrderQtyPositive;

  /// No description provided for @minOrderShort.
  ///
  /// In en, this message translates to:
  /// **'Min Order'**
  String get minOrderShort;

  /// No description provided for @minShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minShort(Object count);

  /// No description provided for @minimumOrderQuantity.
  ///
  /// In en, this message translates to:
  /// **'Minimum Order Quantity'**
  String get minimumOrderQuantity;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(Object count);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minutesShort;

  /// No description provided for @mobileCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Mobile number cannot be changed'**
  String get mobileCannotBeChanged;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @mustContainAtLeast8Char.
  ///
  /// In en, this message translates to:
  /// **'Must Contain at least 8 Characters'**
  String get mustContainAtLeast8Char;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @nationalIdCard.
  ///
  /// In en, this message translates to:
  /// **'National ID Card'**
  String get nationalIdCard;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noAttributeValuesAddedYet.
  ///
  /// In en, this message translates to:
  /// **'You have not added any attribute value yet'**
  String get noAttributeValuesAddedYet;

  /// No description provided for @noAttributeValuesFound.
  ///
  /// In en, this message translates to:
  /// **'No attribute value found'**
  String get noAttributeValuesFound;

  /// No description provided for @noAttributesAddedYet.
  ///
  /// In en, this message translates to:
  /// **'You have not added any attribute yet'**
  String get noAttributesAddedYet;

  /// No description provided for @noAttributesFound.
  ///
  /// In en, this message translates to:
  /// **'No attribute found'**
  String get noAttributesFound;

  /// No description provided for @noBrandsAvailable.
  ///
  /// In en, this message translates to:
  /// **'There is not any brand available.'**
  String get noBrandsAvailable;

  /// No description provided for @noBrandsFound.
  ///
  /// In en, this message translates to:
  /// **'No brands found'**
  String get noBrandsFound;

  /// No description provided for @noCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'There is not any category available.'**
  String get noCategoriesAvailable;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No Categories Found'**
  String get noCategoriesFound;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get noData;

  /// No description provided for @noDeliveryZonesFound.
  ///
  /// In en, this message translates to:
  /// **'No delivery zones found'**
  String get noDeliveryZonesFound;

  /// No description provided for @noEarningsFound.
  ///
  /// In en, this message translates to:
  /// **'No earnings found'**
  String get noEarningsFound;

  /// No description provided for @noEarningsYet.
  ///
  /// In en, this message translates to:
  /// **'You have not any earnings yet'**
  String get noEarningsYet;

  /// No description provided for @noFAQsYet.
  ///
  /// In en, this message translates to:
  /// **'No FAQs yet'**
  String get noFAQsYet;

  /// No description provided for @noFaqsAddedYet.
  ///
  /// In en, this message translates to:
  /// **'You have not added any faq yet.'**
  String get noFaqsAddedYet;

  /// No description provided for @noFaqsFound.
  ///
  /// In en, this message translates to:
  /// **'No FAQs Found'**
  String get noFaqsFound;

  /// No description provided for @noFaqsMessage.
  ///
  /// In en, this message translates to:
  /// **'You have not added any FAQs yet.'**
  String get noFaqsMessage;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// No description provided for @noInternetMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get noInternetMessage;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No Orders Found'**
  String get noOrdersFound;

  /// No description provided for @noOrdersMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any orders yet.'**
  String get noOrdersMessage;

  /// No description provided for @noPendingUrlFoundPleaseTryPurchasingAgai.
  ///
  /// In en, this message translates to:
  /// **'No pending URL found. Please try purchasing again.'**
  String get noPendingUrlFoundPleaseTryPurchasingAgai;

  /// No description provided for @noPermissionAddFaq.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to add product FAQs'**
  String get noPermissionAddFaq;

  /// No description provided for @noPermissionAddProduct.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to add product'**
  String get noPermissionAddProduct;

  /// No description provided for @noPermissionCreateAttribute.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to create attributes.'**
  String get noPermissionCreateAttribute;

  /// No description provided for @noPermissionCreateNotification.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to create notifications.'**
  String get noPermissionCreateNotification;

  /// No description provided for @noPermissionCreateProduct.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to create products.'**
  String get noPermissionCreateProduct;

  /// No description provided for @noPermissionCreateProductCondition.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to create product conditions.'**
  String get noPermissionCreateProductCondition;

  /// No description provided for @noPermissionCreateProductFAQ.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to create product FAQs.'**
  String get noPermissionCreateProductFAQ;

  /// No description provided for @noPermissionCreateRole.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to create roles.'**
  String get noPermissionCreateRole;

  /// No description provided for @noPermissionCreateStore.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to create stores.'**
  String get noPermissionCreateStore;

  /// No description provided for @noPermissionCreateSystemUser.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to create system users.'**
  String get noPermissionCreateSystemUser;

  /// No description provided for @noPermissionCreateTaxRate.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to create tax rates.'**
  String get noPermissionCreateTaxRate;

  /// No description provided for @noPermissionDecideReturn.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to decide on returns.'**
  String get noPermissionDecideReturn;

  /// No description provided for @noPermissionDeleteAttribute.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to delete attributes.'**
  String get noPermissionDeleteAttribute;

  /// No description provided for @noPermissionDeleteFaq.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to delete product FAQs'**
  String get noPermissionDeleteFaq;

  /// No description provided for @noPermissionDeleteNotification.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to delete notifications.'**
  String get noPermissionDeleteNotification;

  /// No description provided for @noPermissionDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to delete this product'**
  String get noPermissionDeleteProduct;

  /// No description provided for @noPermissionDeleteProductCondition.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to delete product conditions.'**
  String get noPermissionDeleteProductCondition;

  /// No description provided for @noPermissionDeleteProductFAQ.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to delete product FAQs.'**
  String get noPermissionDeleteProductFAQ;

  /// No description provided for @noPermissionDeleteRole.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to delete roles.'**
  String get noPermissionDeleteRole;

  /// No description provided for @noPermissionDeleteStore.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to delete stores.'**
  String get noPermissionDeleteStore;

  /// No description provided for @noPermissionDeleteSystemUser.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to delete system users.'**
  String get noPermissionDeleteSystemUser;

  /// No description provided for @noPermissionDeleteTaxRate.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to delete tax rates.'**
  String get noPermissionDeleteTaxRate;

  /// No description provided for @noPermissionEditAttribute.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to edit attributes.'**
  String get noPermissionEditAttribute;

  /// No description provided for @noPermissionEditFaq.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to edit product FAQs'**
  String get noPermissionEditFaq;

  /// No description provided for @noPermissionEditNotification.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to edit notifications.'**
  String get noPermissionEditNotification;

  /// No description provided for @noPermissionEditOrder.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to edit orders.'**
  String get noPermissionEditOrder;

  /// No description provided for @noPermissionEditProduct.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to edit this product'**
  String get noPermissionEditProduct;

  /// No description provided for @noPermissionEditProductCondition.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to edit product conditions.'**
  String get noPermissionEditProductCondition;

  /// No description provided for @noPermissionEditProductFAQ.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to edit product FAQs.'**
  String get noPermissionEditProductFAQ;

  /// No description provided for @noPermissionEditRole.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to edit roles.'**
  String get noPermissionEditRole;

  /// No description provided for @noPermissionEditRolePermissions.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to edit role permissions.'**
  String get noPermissionEditRolePermissions;

  /// No description provided for @noPermissionEditStore.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to edit stores.'**
  String get noPermissionEditStore;

  /// No description provided for @noPermissionEditSystemUser.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to edit system users.'**
  String get noPermissionEditSystemUser;

  /// No description provided for @noPermissionEditTaxRate.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to edit tax rates.'**
  String get noPermissionEditTaxRate;

  /// No description provided for @noPermissionMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to mark all as read'**
  String get noPermissionMarkAllRead;

  /// No description provided for @noPermissionMarkAsRead.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to mark as read'**
  String get noPermissionMarkAsRead;

  /// No description provided for @noPermissionMarkAsUnRead.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to mark as unread'**
  String get noPermissionMarkAsUnRead;

  /// No description provided for @noPermissionRequestWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to request withdrawal'**
  String get noPermissionRequestWithdrawal;

  /// No description provided for @noPermissionToDelete.
  ///
  /// In en, this message translates to:
  /// **'No permission to delete'**
  String get noPermissionToDelete;

  /// No description provided for @noPermissionToEdit.
  ///
  /// In en, this message translates to:
  /// **'No permission to edit'**
  String get noPermissionToEdit;

  /// No description provided for @noPermissionUpdateOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to update order status.'**
  String get noPermissionUpdateOrderStatus;

  /// No description provided for @noPermissionViewAttributes.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view attributes.'**
  String get noPermissionViewAttributes;

  /// No description provided for @noPermissionViewBrands.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view brands.'**
  String get noPermissionViewBrands;

  /// No description provided for @noPermissionViewCategories.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view categories.'**
  String get noPermissionViewCategories;

  /// No description provided for @noPermissionViewDashboard.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view the dashboard.'**
  String get noPermissionViewDashboard;

  /// No description provided for @noPermissionViewEarnings.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view earnings.'**
  String get noPermissionViewEarnings;

  /// No description provided for @noPermissionViewNotification.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view notifications.'**
  String get noPermissionViewNotification;

  /// No description provided for @noPermissionViewOrders.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view orders.'**
  String get noPermissionViewOrders;

  /// No description provided for @noPermissionViewProductFAQs.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view product FAQs.'**
  String get noPermissionViewProductFAQs;

  /// No description provided for @noPermissionViewProducts.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view products.'**
  String get noPermissionViewProducts;

  /// No description provided for @noPermissionViewReturns.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view returns.'**
  String get noPermissionViewReturns;

  /// No description provided for @noPermissionViewRolePermissions.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view role permissions.'**
  String get noPermissionViewRolePermissions;

  /// No description provided for @noPermissionViewRoles.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view roles.'**
  String get noPermissionViewRoles;

  /// No description provided for @noPermissionViewRolesAndPermissions.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view roles and permissions.'**
  String get noPermissionViewRolesAndPermissions;

  /// No description provided for @noPermissionViewStores.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view stores.'**
  String get noPermissionViewStores;

  /// No description provided for @noPermissionViewSystemUsers.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view system users.'**
  String get noPermissionViewSystemUsers;

  /// No description provided for @noPermissionViewTaxRates.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view tax rates.'**
  String get noPermissionViewTaxRates;

  /// No description provided for @noPermissionViewWallet.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view your wallet.'**
  String get noPermissionViewWallet;

  /// No description provided for @noPermissionViewWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view withdrawals.'**
  String get noPermissionViewWithdrawals;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No Products Found'**
  String get noProductsFound;

  /// No description provided for @noProductsMessage.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any products yet.'**
  String get noProductsMessage;

  /// No description provided for @noRolesFound.
  ///
  /// In en, this message translates to:
  /// **'No roles found'**
  String get noRolesFound;

  /// No description provided for @noSearchMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find anything matching your search.'**
  String get noSearchMessage;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No Search Results'**
  String get noSearchResults;

  /// No description provided for @noActiveStore.
  ///
  /// In en, this message translates to:
  /// **'No active store'**
  String get noActiveStore;

  /// No description provided for @noStoreFound.
  ///
  /// In en, this message translates to:
  /// **'No Store Found'**
  String get noStoreFound;

  /// No description provided for @noStoresAddedYet.
  ///
  /// In en, this message translates to:
  /// **'You have not added any store yet.'**
  String get noStoresAddedYet;

  /// No description provided for @noStoresFound.
  ///
  /// In en, this message translates to:
  /// **'No stores found'**
  String get noStoresFound;

  /// No description provided for @noSystemUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No system users found'**
  String get noSystemUsersFound;

  /// No description provided for @noSystemUsersMessage.
  ///
  /// In en, this message translates to:
  /// **'You have not have any system users yet.'**
  String get noSystemUsersMessage;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @nonVeg.
  ///
  /// In en, this message translates to:
  /// **'Non-Veg'**
  String get nonVeg;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @notEligibleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Some requirements are not met for this plan.'**
  String get notEligibleSubtitle;

  /// No description provided for @notEligibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Not eligible for this plan'**
  String get notEligibleTitle;

  /// No description provided for @not_approved.
  ///
  /// In en, this message translates to:
  /// **'Not Approved'**
  String get not_approved;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @offPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off'**
  String offPercent(Object percent);

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @onSale.
  ///
  /// In en, this message translates to:
  /// **'ON SALE'**
  String get onSale;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @operationCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Operation completed successfully'**
  String get operationCompletedSuccessfully;

  /// No description provided for @operationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Operation successful'**
  String get operationSuccessful;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @orderAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order accepted.'**
  String get orderAccepted;

  /// No description provided for @orderDate.
  ///
  /// In en, this message translates to:
  /// **'Order Date :'**
  String get orderDate;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @orderEarnings.
  ///
  /// In en, this message translates to:
  /// **'Order Earnings'**
  String get orderEarnings;

  /// No description provided for @orderItems.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get orderItems;

  /// No description provided for @orderMarkedAsPrepared.
  ///
  /// In en, this message translates to:
  /// **'Order marked as prepared.'**
  String get orderMarkedAsPrepared;

  /// No description provided for @orderNote.
  ///
  /// In en, this message translates to:
  /// **'Order Note :'**
  String get orderNote;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order Number :'**
  String get orderNumber;

  /// No description provided for @orderRejected.
  ///
  /// In en, this message translates to:
  /// **'Order rejected.'**
  String get orderRejected;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @ordersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage and track customer orders'**
  String get ordersSubtitle;

  /// No description provided for @otpLabel.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get otpLabel;

  /// No description provided for @otpSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'OTP sent successfully'**
  String get otpSentSuccess;

  /// No description provided for @out_of_stock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get out_of_stock;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method :'**
  String get paymentMethod;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get paymentPending;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status :'**
  String get paymentStatus;

  /// No description provided for @paymentType.
  ///
  /// In en, this message translates to:
  /// **'Payment Type'**
  String get paymentType;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @pendingOrders.
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pendingOrders;

  /// No description provided for @pending_verification.
  ///
  /// In en, this message translates to:
  /// **'Pending Verification'**
  String get pending_verification;

  /// No description provided for @permission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get permission;

  /// No description provided for @permissionFor.
  ///
  /// In en, this message translates to:
  /// **'Permission for: {role}'**
  String permissionFor(Object role);

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone :'**
  String get phoneLabel;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @planDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan Details'**
  String get planDetailsTitle;

  /// No description provided for @pleaseAddStoreToStartBusiness.
  ///
  /// In en, this message translates to:
  /// **'Please add a store to start managing your business.'**
  String get pleaseAddStoreToStartBusiness;

  /// No description provided for @pleaseCompleteCurrentStep.
  ///
  /// In en, this message translates to:
  /// **'Please complete the current step first'**
  String get pleaseCompleteCurrentStep;

  /// No description provided for @pleaseCompleteallRequiredFieldsInPreviousSteps.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required fields in previous steps'**
  String get pleaseCompleteallRequiredFieldsInPreviousSteps;

  /// No description provided for @pleaseEnterAnswer.
  ///
  /// In en, this message translates to:
  /// **'Please enter an answer'**
  String get pleaseEnterAnswer;

  /// No description provided for @pleaseEnterQuestion.
  ///
  /// In en, this message translates to:
  /// **'Please enter a question'**
  String get pleaseEnterQuestion;

  /// No description provided for @pleaseSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a file'**
  String get pleaseSelectFile;

  /// No description provided for @pleaseSelectOneRole.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one role'**
  String get pleaseSelectOneRole;

  /// No description provided for @pleaseSelectProduct.
  ///
  /// In en, this message translates to:
  /// **'Please select a product'**
  String get pleaseSelectProduct;

  /// No description provided for @policiesAndFeatures.
  ///
  /// In en, this message translates to:
  /// **'Policies & Features'**
  String get policiesAndFeatures;

  /// No description provided for @prepTimeShort.
  ///
  /// In en, this message translates to:
  /// **'Prep Time'**
  String get prepTimeShort;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @pressAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press again to exit'**
  String get pressAgainToExit;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @priceRequiredForStore.
  ///
  /// In en, this message translates to:
  /// **'Price is required for store: {store}'**
  String priceRequiredForStore(Object store);

  /// No description provided for @priceRequiredForStoreVariant.
  ///
  /// In en, this message translates to:
  /// **'Price is required for store {store} (Variant: {variant})'**
  String priceRequiredForStoreVariant(Object store, Object variant);

  /// No description provided for @pricingAndTaxes.
  ///
  /// In en, this message translates to:
  /// **'Pricing & Taxes'**
  String get pricingAndTaxes;

  /// No description provided for @pricingNotSetForStore.
  ///
  /// In en, this message translates to:
  /// **'Pricing not set for store: {store}'**
  String pricingNotSetForStore(Object store);

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @proceedToPay.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Pay'**
  String get proceedToPay;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @productAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully!'**
  String get productAddedSuccessfully;

  /// No description provided for @productDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get productDescription;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @productDetailsOnSale.
  ///
  /// In en, this message translates to:
  /// **'ON SALE'**
  String get productDetailsOnSale;

  /// No description provided for @productDetailsPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productDetailsPrice;

  /// No description provided for @productDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Details Title'**
  String get productDetailsTitle;

  /// No description provided for @productFaqSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your product questions & answers'**
  String get productFaqSubtitle;

  /// No description provided for @productFaqs.
  ///
  /// In en, this message translates to:
  /// **'Product FAQs'**
  String get productFaqs;

  /// No description provided for @productFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Filter'**
  String get productFilterLabel;

  /// No description provided for @productImages.
  ///
  /// In en, this message translates to:
  /// **'Product Images'**
  String get productImages;

  /// No description provided for @productInformation.
  ///
  /// In en, this message translates to:
  /// **'Product Information'**
  String get productInformation;

  /// No description provided for @productTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Product title is required'**
  String get productTitleRequired;

  /// No description provided for @productType.
  ///
  /// In en, this message translates to:
  /// **'Product Type'**
  String get productType;

  /// No description provided for @productTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get productTypeLabel;

  /// No description provided for @productVariants.
  ///
  /// In en, this message translates to:
  /// **'Product Variants'**
  String get productVariants;

  /// No description provided for @productVariation.
  ///
  /// In en, this message translates to:
  /// **'Product Variation'**
  String get productVariation;

  /// No description provided for @productVideo.
  ///
  /// In en, this message translates to:
  /// **'Product Video'**
  String get productVideo;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @productsDescription.
  ///
  /// In en, this message translates to:
  /// **'Products Description'**
  String get productsDescription;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Profile Edit'**
  String get profileEdit;

  /// No description provided for @qtyAmount.
  ///
  /// In en, this message translates to:
  /// **'{count} qty'**
  String qtyAmount(Object count);

  /// No description provided for @qtyStepSizePositive.
  ///
  /// In en, this message translates to:
  /// **'Quantity step size must be a positive integer'**
  String get qtyStepSizePositive;

  /// No description provided for @qtyWithCount.
  ///
  /// In en, this message translates to:
  /// **'Qty: {count}'**
  String qtyWithCount(Object count);

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @quantityStepSize.
  ///
  /// In en, this message translates to:
  /// **'Quantity Step Size'**
  String get quantityStepSize;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate:'**
  String get rate;

  /// No description provided for @readPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get readPrivacyPolicy;

  /// No description provided for @readTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Read our terms and conditions'**
  String get readTermsAndConditions;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refunded;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejectOrderConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this order? This action cannot be undone.'**
  String get rejectOrderConfirmation;

  /// No description provided for @rejectOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrderTitle;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @replaceVideoOptional.
  ///
  /// In en, this message translates to:
  /// **'Replace video (optional)'**
  String get replaceVideoOptional;

  /// No description provided for @requestWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Request Withdraw'**
  String get requestWithdraw;

  /// No description provided for @requiredIfReturnable.
  ///
  /// In en, this message translates to:
  /// **'Required if Product is returnable'**
  String get requiredIfReturnable;

  /// No description provided for @requiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredLabel;

  /// No description provided for @requiredOtp.
  ///
  /// In en, this message translates to:
  /// **'Required OTP'**
  String get requiredOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @resendOtpIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in'**
  String get resendOtpIn;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link has been sent to your email'**
  String get resetLinkSent;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you instructions to reset your password'**
  String get resetPasswordSubtitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @returnText.
  ///
  /// In en, this message translates to:
  /// **'return'**
  String get returnText;

  /// No description provided for @returnableDays.
  ///
  /// In en, this message translates to:
  /// **'Returnable Days'**
  String get returnableDays;

  /// No description provided for @returnableLabel.
  ///
  /// In en, this message translates to:
  /// **'Returnable'**
  String get returnableLabel;

  /// No description provided for @returned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returned;

  /// No description provided for @returnsLabel.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get returnsLabel;

  /// No description provided for @reviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{review} other{reviews}}'**
  String reviewCount(num count);

  /// No description provided for @roleName.
  ///
  /// In en, this message translates to:
  /// **'Role Name'**
  String get roleName;

  /// No description provided for @roleNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter role name'**
  String get roleNameRequired;

  /// No description provided for @roles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get roles;

  /// No description provided for @rolesAndPermissions.
  ///
  /// In en, this message translates to:
  /// **'Roles & Permissions'**
  String get rolesAndPermissions;

  /// No description provided for @rolesAndPermissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'User access control'**
  String get rolesAndPermissionsSubtitle;

  /// No description provided for @routingNumber.
  ///
  /// In en, this message translates to:
  /// **'Routing Number'**
  String get routingNumber;

  /// No description provided for @rushDelivery.
  ///
  /// In en, this message translates to:
  /// **'Rush Delivery'**
  String get rushDelivery;

  /// No description provided for @saveUser.
  ///
  /// In en, this message translates to:
  /// **'Save User'**
  String get saveUser;

  /// No description provided for @savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchAndSelectStores.
  ///
  /// In en, this message translates to:
  /// **'Search and select stores'**
  String get searchAndSelectStores;

  /// No description provided for @searchBrand.
  ///
  /// In en, this message translates to:
  /// **'Search Brand...'**
  String get searchBrand;

  /// No description provided for @searchCategory.
  ///
  /// In en, this message translates to:
  /// **'Search Category'**
  String get searchCategory;

  /// No description provided for @searchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country'**
  String get searchCountry;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchLabel;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search location...'**
  String get searchLocation;

  /// No description provided for @searchProduct.
  ///
  /// In en, this message translates to:
  /// **'Search Products'**
  String get searchProduct;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @searchStores.
  ///
  /// In en, this message translates to:
  /// **'Search stores...'**
  String get searchStores;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @selectAtLeastOneCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one category'**
  String get selectAtLeastOneCategory;

  /// No description provided for @selectAtLeastOneDefaultVariant.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one default variant'**
  String get selectAtLeastOneDefaultVariant;

  /// No description provided for @selectAtLeastOneStore.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one store'**
  String get selectAtLeastOneStore;

  /// No description provided for @selectAttribute.
  ///
  /// In en, this message translates to:
  /// **'Select Attribute'**
  String get selectAttribute;

  /// No description provided for @selectBrand.
  ///
  /// In en, this message translates to:
  /// **'Select Brand'**
  String get selectBrand;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColor;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @selectFilter.
  ///
  /// In en, this message translates to:
  /// **'Select Filter'**
  String get selectFilter;

  /// No description provided for @selectImageFit.
  ///
  /// In en, this message translates to:
  /// **'Select Image Fit'**
  String get selectImageFit;

  /// No description provided for @selectIndicator.
  ///
  /// In en, this message translates to:
  /// **'Select Indicator'**
  String get selectIndicator;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @selectOption.
  ///
  /// In en, this message translates to:
  /// **'Select Option'**
  String get selectOption;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select product'**
  String get selectProduct;

  /// No description provided for @selectStatus.
  ///
  /// In en, this message translates to:
  /// **'Select Status'**
  String get selectStatus;

  /// No description provided for @selectStatus2.
  ///
  /// In en, this message translates to:
  /// **'Select status'**
  String get selectStatus2;

  /// No description provided for @selectStore.
  ///
  /// In en, this message translates to:
  /// **'Select Store'**
  String get selectStore;

  /// No description provided for @selectStores.
  ///
  /// In en, this message translates to:
  /// **'Select Stores'**
  String get selectStores;

  /// No description provided for @selectSwatchImage.
  ///
  /// In en, this message translates to:
  /// **'Select Swatch Image'**
  String get selectSwatchImage;

  /// No description provided for @selectTags.
  ///
  /// In en, this message translates to:
  /// **'Select Tags'**
  String get selectTags;

  /// No description provided for @selectTaxGroup.
  ///
  /// In en, this message translates to:
  /// **'Select Tax Group'**
  String get selectTaxGroup;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @selectThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred theme'**
  String get selectThemeSubtitle;

  /// No description provided for @selectVideoType.
  ///
  /// In en, this message translates to:
  /// **'Select Video Type'**
  String get selectVideoType;

  /// No description provided for @selectYourPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get selectYourPreferredLanguage;

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected Location'**
  String get selectedLocation;

  /// No description provided for @selfHosted.
  ///
  /// In en, this message translates to:
  /// **'Self Hosted'**
  String get selfHosted;

  /// No description provided for @seller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get seller;

  /// No description provided for @sellerName.
  ///
  /// In en, this message translates to:
  /// **'Seller Name'**
  String get sellerName;

  /// No description provided for @sendOTP.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOTP;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @setAsDefaultVariant.
  ///
  /// In en, this message translates to:
  /// **'Set as default Variant'**
  String get setAsDefaultVariant;

  /// No description provided for @setPricingForEachStore.
  ///
  /// In en, this message translates to:
  /// **'Set pricing for each store'**
  String get setPricingForEachStore;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @shippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get shippingAddress;

  /// No description provided for @shortDescription.
  ///
  /// In en, this message translates to:
  /// **'Short Description'**
  String get shortDescription;

  /// No description provided for @shortDescriptionCompulsory.
  ///
  /// In en, this message translates to:
  /// **'Short description is compulsory'**
  String get shortDescriptionCompulsory;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account to continue'**
  String get signInToContinue;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @simple.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get simple;

  /// No description provided for @simpleProduct.
  ///
  /// In en, this message translates to:
  /// **'Simple Product'**
  String get simpleProduct;

  /// No description provided for @simpleVariantTitle.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get simpleVariantTitle;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// No description provided for @skuRequiredForStore.
  ///
  /// In en, this message translates to:
  /// **'SKU is required for store: {store}'**
  String skuRequiredForStore(Object store);

  /// No description provided for @skuRequiredForStoreVariant.
  ///
  /// In en, this message translates to:
  /// **'SKU is required for store {store} (Variant: {variant})'**
  String skuRequiredForStoreVariant(Object store, Object variant);

  /// No description provided for @space.
  ///
  /// In en, this message translates to:
  /// **'space'**
  String get space;

  /// No description provided for @specialPrice.
  ///
  /// In en, this message translates to:
  /// **'Special Price'**
  String get specialPrice;

  /// No description provided for @specialPriceGreaterError.
  ///
  /// In en, this message translates to:
  /// **'Special price cannot be greater than regular price for store: {store}'**
  String specialPriceGreaterError(Object store);

  /// No description provided for @specialPriceGreaterErrorVariant.
  ///
  /// In en, this message translates to:
  /// **'Special price cannot be greater than regular price for store {store} (Variant: {variant})'**
  String specialPriceGreaterErrorVariant(Object store, Object variant);

  /// No description provided for @specificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get specificationsLabel;

  /// No description provided for @standardDelivery.
  ///
  /// In en, this message translates to:
  /// **'Standard Delivery'**
  String get standardDelivery;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status :'**
  String get statusLabel;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get statusUpdated;

  /// No description provided for @stepCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get stepCompleted;

  /// No description provided for @stepCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current step'**
  String get stepCurrent;

  /// No description provided for @stepMustBeCompletedBeforeJumping.
  ///
  /// In en, this message translates to:
  /// **'Step {step} must be completed before jumping ahead'**
  String stepMustBeCompletedBeforeJumping(Object step);

  /// No description provided for @stepPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get stepPending;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @stockRequiredForStore.
  ///
  /// In en, this message translates to:
  /// **'Stock is required for store: {store}'**
  String stockRequiredForStore(Object store);

  /// No description provided for @stockRequiredForStoreVariant.
  ///
  /// In en, this message translates to:
  /// **'Stock is required for store {store} (Variant: {variant})'**
  String stockRequiredForStoreVariant(Object store, Object variant);

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @storeBanner.
  ///
  /// In en, this message translates to:
  /// **'Store Banner'**
  String get storeBanner;

  /// No description provided for @storeConfig.
  ///
  /// In en, this message translates to:
  /// **'Store Config'**
  String get storeConfig;

  /// No description provided for @storeInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Store Info'**
  String get storeInfoLabel;

  /// No description provided for @storeIsClosed.
  ///
  /// In en, this message translates to:
  /// **'Store is Closed'**
  String get storeIsClosed;

  /// No description provided for @storeIsOpen.
  ///
  /// In en, this message translates to:
  /// **'Store is Open'**
  String get storeIsOpen;

  /// No description provided for @storeLogo.
  ///
  /// In en, this message translates to:
  /// **'Store Logo'**
  String get storeLogo;

  /// No description provided for @storeManagement.
  ///
  /// In en, this message translates to:
  /// **'STORE MANAGEMENT'**
  String get storeManagement;

  /// No description provided for @storeName.
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get storeName;

  /// No description provided for @storePricing.
  ///
  /// In en, this message translates to:
  /// **'Store Pricing'**
  String get storePricing;

  /// No description provided for @stores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get stores;

  /// No description provided for @storesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage multiple stores'**
  String get storesSubtitle;

  /// No description provided for @subcategories.
  ///
  /// In en, this message translates to:
  /// **'Subcategories'**
  String get subcategories;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @subscriptionPaymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Subscription payment successful!'**
  String get subscriptionPaymentSuccessful;

  /// No description provided for @subscriptionPlansDescription.
  ///
  /// In en, this message translates to:
  /// **'By subscribing to this plan, you will get access to the following features :'**
  String get subscriptionPlansDescription;

  /// No description provided for @subscriptionPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plans'**
  String get subscriptionPlansTitle;

  /// No description provided for @subscriptionPurchasedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Subscription purchased successfully'**
  String get subscriptionPurchasedSuccessfully;

  /// No description provided for @subscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View subscription plans'**
  String get subscriptionSubtitle;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @swatchType.
  ///
  /// In en, this message translates to:
  /// **'Swatch Type'**
  String get swatchType;

  /// No description provided for @swatchValue.
  ///
  /// In en, this message translates to:
  /// **'Swatch Value'**
  String get swatchValue;

  /// No description provided for @switchStore.
  ///
  /// In en, this message translates to:
  /// **'Switch Store'**
  String get switchStore;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @systemMessage.
  ///
  /// In en, this message translates to:
  /// **'Matches your device settings'**
  String get systemMessage;

  /// No description provided for @systemUsers.
  ///
  /// In en, this message translates to:
  /// **'System Users'**
  String get systemUsers;

  /// No description provided for @systemUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Team members'**
  String get systemUsersSubtitle;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tapOnMapToSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap on map to select location'**
  String get tapOnMapToSelectLocation;

  /// No description provided for @taxGroup.
  ///
  /// In en, this message translates to:
  /// **'Tax Group'**
  String get taxGroup;

  /// No description provided for @taxGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View tax groups'**
  String get taxGroupSubtitle;

  /// No description provided for @taxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taxLabel;

  /// No description provided for @taxName.
  ///
  /// In en, this message translates to:
  /// **'Tax Name'**
  String get taxName;

  /// No description provided for @taxNumber.
  ///
  /// In en, this message translates to:
  /// **'Tax Number'**
  String get taxNumber;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Condition'**
  String get termsAndConditions;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @topSellingProducts.
  ///
  /// In en, this message translates to:
  /// **'Top-Selling Products'**
  String get topSellingProducts;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @totalAllowedQtyMinOrderConflict.
  ///
  /// In en, this message translates to:
  /// **'Total allowed quantity must be greater than or equal to minimum order quantity (or leave empty)'**
  String get totalAllowedQtyMinOrderConflict;

  /// No description provided for @totalAllowedQtyPositive.
  ///
  /// In en, this message translates to:
  /// **'Total allowed quantity must be positive (or leave empty for no limit)'**
  String get totalAllowedQtyPositive;

  /// No description provided for @totalAllowedQuantity.
  ///
  /// In en, this message translates to:
  /// **'Total Allowed Quantity'**
  String get totalAllowedQuantity;

  /// No description provided for @totalAttributesWithCount.
  ///
  /// In en, this message translates to:
  /// **'Total Attributes ({count})'**
  String totalAttributesWithCount(Object count);

  /// No description provided for @totalOrdersWithCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Order} other{Orders}}'**
  String totalOrdersWithCount(num count);

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price :'**
  String get totalPrice;

  /// No description provided for @totalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProducts;

  /// No description provided for @totalProductsWithCount.
  ///
  /// In en, this message translates to:
  /// **'Total Products ({count})'**
  String totalProductsWithCount(Object count);

  /// No description provided for @totalRoles.
  ///
  /// In en, this message translates to:
  /// **'Total Roles'**
  String get totalRoles;

  /// No description provided for @totalRolesWithCount.
  ///
  /// In en, this message translates to:
  /// **'Total Roles ({count} Roles)'**
  String totalRolesWithCount(Object count);

  /// No description provided for @totalStoresWithCount.
  ///
  /// In en, this message translates to:
  /// **'Total Stores ({count})'**
  String totalStoresWithCount(Object count);

  /// No description provided for @totalSystemUsers.
  ///
  /// In en, this message translates to:
  /// **'Total System Users'**
  String get totalSystemUsers;

  /// No description provided for @totalSystemUsersWithCount.
  ///
  /// In en, this message translates to:
  /// **'Total System Users ({count})'**
  String totalSystemUsersWithCount(Object count);

  /// No description provided for @trackEarningsGetPaid.
  ///
  /// In en, this message translates to:
  /// **'Track Earnings & Get Paid'**
  String get trackEarningsGetPaid;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @unnamedGuard.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Guard'**
  String get unnamedGuard;

  /// No description provided for @unsettled.
  ///
  /// In en, this message translates to:
  /// **'Unsettled'**
  String get unsettled;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @updateFaq.
  ///
  /// In en, this message translates to:
  /// **'Update FAQ'**
  String get updateFaq;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'UPDATE PASSWORD'**
  String get updatePassword;

  /// No description provided for @updateRole.
  ///
  /// In en, this message translates to:
  /// **'Update Role'**
  String get updateRole;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'+ Upload Image'**
  String get uploadImage;

  /// No description provided for @uploadVariantImage.
  ///
  /// In en, this message translates to:
  /// **'+ Upload Variant Image'**
  String get uploadVariantImage;

  /// No description provided for @uploadVideo.
  ///
  /// In en, this message translates to:
  /// **'+ Upload Video'**
  String get uploadVideo;

  /// No description provided for @userPreference.
  ///
  /// In en, this message translates to:
  /// **'User Preference'**
  String get userPreference;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @valueCount.
  ///
  /// In en, this message translates to:
  /// **'Values count:'**
  String get valueCount;

  /// No description provided for @values.
  ///
  /// In en, this message translates to:
  /// **'Values'**
  String get values;

  /// No description provided for @variableProduct.
  ///
  /// In en, this message translates to:
  /// **'Variable Product'**
  String get variableProduct;

  /// No description provided for @variant.
  ///
  /// In en, this message translates to:
  /// **'Variant'**
  String get variant;

  /// No description provided for @variantImage.
  ///
  /// In en, this message translates to:
  /// **'Variant Image'**
  String get variantImage;

  /// No description provided for @variantName.
  ///
  /// In en, this message translates to:
  /// **'Variant Name'**
  String get variantName;

  /// No description provided for @variantsAndAvailability.
  ///
  /// In en, this message translates to:
  /// **'Variants & Availability'**
  String get variantsAndAvailability;

  /// No description provided for @variantsImage.
  ///
  /// In en, this message translates to:
  /// **'Variant Image'**
  String get variantsImage;

  /// No description provided for @veg.
  ///
  /// In en, this message translates to:
  /// **'Veg'**
  String get veg;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get verificationStatus;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'VERIFY OTP'**
  String get verifyOtp;

  /// No description provided for @videoLink.
  ///
  /// In en, this message translates to:
  /// **'Video Link'**
  String get videoLink;

  /// No description provided for @videoType.
  ///
  /// In en, this message translates to:
  /// **'Video Type'**
  String get videoType;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @viewOrders.
  ///
  /// In en, this message translates to:
  /// **'View Orders'**
  String get viewOrders;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @visible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get visible;

  /// No description provided for @voidedCheck.
  ///
  /// In en, this message translates to:
  /// **'Voided Check'**
  String get voidedCheck;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @walletSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Seller\'s wallet balance & transactions'**
  String get walletSubtitle;

  /// No description provided for @warrantyLabel.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get warrantyLabel;

  /// No description provided for @warrantyPeriod.
  ///
  /// In en, this message translates to:
  /// **'Warranty Period'**
  String get warrantyPeriod;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @weightRequired.
  ///
  /// In en, this message translates to:
  /// **'Weight is required'**
  String get weightRequired;

  /// No description provided for @weightRequiredForAllVariants.
  ///
  /// In en, this message translates to:
  /// **'Weight is required for all variants'**
  String get weightRequiredForAllVariants;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @whatsIncluded.
  ///
  /// In en, this message translates to:
  /// **'What\'s Included'**
  String get whatsIncluded;

  /// No description provided for @withdrawRequest.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Request'**
  String get withdrawRequest;

  /// No description provided for @withdrawRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit withdrawal request'**
  String get withdrawRequestFailed;

  /// No description provided for @withdrawRequestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal request submitted successfully'**
  String get withdrawRequestSuccess;

  /// No description provided for @withdrawalHistory.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal History'**
  String get withdrawalHistory;

  /// No description provided for @xyzArea.
  ///
  /// In en, this message translates to:
  /// **'XYZ Area'**
  String get xyzArea;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get years;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @yesTillTime.
  ///
  /// In en, this message translates to:
  /// **'Yes (till {time})'**
  String yesTillTime(Object time);

  /// No description provided for @yesWithDays.
  ///
  /// In en, this message translates to:
  /// **'Yes — {days} days'**
  String yesWithDays(Object days);

  /// No description provided for @youCanSelectMultipleImagesByClickingAddButton.
  ///
  /// In en, this message translates to:
  /// **'You can select multiple images by clicking add button'**
  String get youCanSelectMultipleImagesByClickingAddButton;

  /// No description provided for @youCanSelectMultipleTags.
  ///
  /// In en, this message translates to:
  /// **'You can select multiple tags'**
  String get youCanSelectMultipleTags;

  /// No description provided for @youDoNotHavePermissionToDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to delete product.'**
  String get youDoNotHavePermissionToDeleteProduct;

  /// No description provided for @youDoNotHavePermissionToEditProducts.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to edit products.'**
  String get youDoNotHavePermissionToEditProducts;

  /// No description provided for @youDoNotHavePermissionToRequestWithdrawa.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to request withdrawal.'**
  String get youDoNotHavePermissionToRequestWithdrawa;

  /// No description provided for @youDoNotHavePermissionToViewWithdrawalHi.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view withdrawal history.'**
  String get youDoNotHavePermissionToViewWithdrawalHi;

  /// No description provided for @youDontHavePermissionToAddAttributes.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to add attributes'**
  String get youDontHavePermissionToAddAttributes;

  /// No description provided for @youDontHavePermissionToAddSystemUsers.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to add system users'**
  String get youDontHavePermissionToAddSystemUsers;

  /// No description provided for @youDontHavePermissionToCreateRoles.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to create roles'**
  String get youDontHavePermissionToCreateRoles;

  /// No description provided for @youDontHavePermissionToCreateStores.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to create stores'**
  String get youDontHavePermissionToCreateStores;

  /// No description provided for @youDontHavePermissionToDeleteAttributes.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to delete attributes'**
  String get youDontHavePermissionToDeleteAttributes;

  /// No description provided for @youDontHavePermissionToDeleteRoles.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to delete roles'**
  String get youDontHavePermissionToDeleteRoles;

  /// No description provided for @youDontHavePermissionToDeleteStores.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to delete stores'**
  String get youDontHavePermissionToDeleteStores;

  /// No description provided for @youDontHavePermissionToDeleteThisUser.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to delete this user'**
  String get youDontHavePermissionToDeleteThisUser;

  /// No description provided for @youDontHavePermissionToEditAttributes.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to edit attributes'**
  String get youDontHavePermissionToEditAttributes;

  /// No description provided for @youDontHavePermissionToEditRoles.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to edit roles'**
  String get youDontHavePermissionToEditRoles;

  /// No description provided for @youDontHavePermissionToEditStores.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to edit stores'**
  String get youDontHavePermissionToEditStores;

  /// No description provided for @youDontHavePermissionToEditSystemUsers.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to edit system users'**
  String get youDontHavePermissionToEditSystemUsers;

  /// No description provided for @youDontHavePermissionToModifyRolePermiss.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to modify role permissions'**
  String get youDontHavePermissionToModifyRolePermiss;

  /// No description provided for @youDontHavePermissionToUpdateOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to update order status'**
  String get youDontHavePermissionToUpdateOrderStatus;

  /// No description provided for @youDontHavePermissionToUpdateStoreStatus.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to update store status'**
  String get youDontHavePermissionToUpdateStoreStatus;

  /// No description provided for @youtube.
  ///
  /// In en, this message translates to:
  /// **'Youtube'**
  String get youtube;

  /// No description provided for @zipCode.
  ///
  /// In en, this message translates to:
  /// **'Zip code'**
  String get zipCode;

  /// No description provided for @zonesAvailableWithCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Zones Available'**
  String zonesAvailableWithCount(Object count);

  /// No description provided for @someLimitsExceeded.
  ///
  /// In en, this message translates to:
  /// **'Some limits have been exceeded.'**
  String get someLimitsExceeded;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'CURRENT PLAN'**
  String get currentPlan;

  /// No description provided for @resumePayment.
  ///
  /// In en, this message translates to:
  /// **'RESUME PAYMENT'**
  String get resumePayment;

  /// No description provided for @viewPlan.
  ///
  /// In en, this message translates to:
  /// **'View Plan'**
  String get viewPlan;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @anotherPlanActive.
  ///
  /// In en, this message translates to:
  /// **'ANOTHER PLAN ACTIVE'**
  String get anotherPlanActive;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @threeMonths.
  ///
  /// In en, this message translates to:
  /// **'3 Months'**
  String get threeMonths;

  /// No description provided for @subscriptionReminder.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get subscriptionReminder;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Expires Today} =1{1 Day Left} other{{days} Days Left}}'**
  String daysLeft(num days);

  /// No description provided for @subscriptionExpiring.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expiring'**
  String get subscriptionExpiring;

  /// No description provided for @daysRemain.
  ///
  /// In en, this message translates to:
  /// **'DAYS REMAINING'**
  String get daysRemain;

  /// No description provided for @activePlan.
  ///
  /// In en, this message translates to:
  /// **'Active Plan'**
  String get activePlan;

  /// No description provided for @renewNow.
  ///
  /// In en, this message translates to:
  /// **'Renew Now'**
  String get renewNow;

  /// No description provided for @remindMeLater.
  ///
  /// In en, this message translates to:
  /// **'Remind Me Later'**
  String get remindMeLater;

  /// No description provided for @subHistory.
  ///
  /// In en, this message translates to:
  /// **'Subscription History'**
  String get subHistory;

  /// No description provided for @subscriptionExpiringMessage.
  ///
  /// In en, this message translates to:
  /// **'Your subscription will expire soon.\nPlease renew to continue using seller\nservices and maintain access to your\ndashboard.'**
  String get subscriptionExpiringMessage;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @editProductFaq.
  ///
  /// In en, this message translates to:
  /// **'Edit Product FAQ'**
  String get editProductFaq;

  /// No description provided for @addProductFaq.
  ///
  /// In en, this message translates to:
  /// **'Add Product FAQ'**
  String get addProductFaq;

  /// No description provided for @noSubHistory.
  ///
  /// In en, this message translates to:
  /// **'No subscription history found'**
  String get noSubHistory;

  /// No description provided for @noSubHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Seems like you haven\'t subscribed to any subscription yet'**
  String get noSubHistorySubtitle;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get tryAgainLater;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @noNotificationsMessage.
  ///
  /// In en, this message translates to:
  /// **'You have not received any notifications yet.'**
  String get noNotificationsMessage;

  /// No description provided for @noBrandsAddedYet.
  ///
  /// In en, this message translates to:
  /// **'You have not added any brands yet'**
  String get noBrandsAddedYet;

  /// No description provided for @noRolesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have not added any roles yet.'**
  String get noRolesMessage;

  /// No description provided for @noSubscriptionPlansFound.
  ///
  /// In en, this message translates to:
  /// **'No Subscription Plans Found!'**
  String get noSubscriptionPlansFound;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactionsFound;

  /// No description provided for @noTransactionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have not performed any transactions yet'**
  String get noTransactionsSubtitle;

  /// No description provided for @noWithdrawHistory.
  ///
  /// In en, this message translates to:
  /// **'No withdraw history found'**
  String get noWithdrawHistory;

  /// No description provided for @noWithdrawHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'You have not made any withdrawal requests yet.'**
  String get noWithdrawHistoryMessage;
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
      <String>['ar', 'en', 'hi'].contains(locale.languageCode);

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
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
