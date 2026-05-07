// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `English`
  String get title {
    return Intl.message(
      'English',
      name: 'title',
      desc: '',
      args: [],
    );
  }

  /// `Ar`
  String get languageSwitchButton {
    return Intl.message(
      'Ar',
      name: 'languageSwitchButton',
      desc: '',
      args: [],
    );
  }

  /// `Navigator`
  String get navigator {
    return Intl.message(
      'Navigator',
      name: 'navigator',
      desc: '',
      args: [],
    );
  }

  /// `Homepage`
  String get homepage {
    return Intl.message(
      'Homepage',
      name: 'homepage',
      desc: '',
      args: [],
    );
  }

  /// `Title Register`
  String get titleRegister {
    return Intl.message(
      'Title Register',
      name: 'titleRegister',
      desc: '',
      args: [],
    );
  }

  /// `Transaction Tracking`
  String get transactionTracking {
    return Intl.message(
      'Transaction Tracking',
      name: 'transactionTracking',
      desc: '',
      args: [],
    );
  }

  /// `Fees Simulation`
  String get feesSimulation {
    return Intl.message(
      'Fees Simulation',
      name: 'feesSimulation',
      desc: '',
      args: [],
    );
  }

  /// `Title Register Changes`
  String get titleRegisterChanges {
    return Intl.message(
      'Title Register Changes',
      name: 'titleRegisterChanges',
      desc: '',
      args: [],
    );
  }

  /// `Ownership Req. Tracking`
  String get ownershipReqTracking {
    return Intl.message(
      'Ownership Req. Tracking',
      name: 'ownershipReqTracking',
      desc: '',
      args: [],
    );
  }

  /// `Paid Invoices`
  String get paidInvoices {
    return Intl.message(
      'Paid Invoices',
      name: 'paidInvoices',
      desc: '',
      args: [],
    );
  }

  /// `Title Registration`
  String get titleRegistration {
    return Intl.message(
      'Title Registration',
      name: 'titleRegistration',
      desc: '',
      args: [],
    );
  }

  /// `Select Province`
  String get selectProvince {
    return Intl.message(
      'Select Province',
      name: 'selectProvince',
      desc: '',
      args: [],
    );
  }

  /// `Select Caza`
  String get selectCaza {
    return Intl.message(
      'Select Caza',
      name: 'selectCaza',
      desc: '',
      args: [],
    );
  }

  /// `Select Cadastral Zone`
  String get selectCadastralZone {
    return Intl.message(
      'Select Cadastral Zone',
      name: 'selectCadastralZone',
      desc: '',
      args: [],
    );
  }

  /// `Property is valid`
  String get propertyValid {
    return Intl.message(
      'Property is valid',
      name: 'propertyValid',
      desc: '',
      args: [],
    );
  }

  /// `Property is not valid`
  String get propertyNotValid {
    return Intl.message(
      'Property is not valid',
      name: 'propertyNotValid',
      desc: '',
      args: [],
    );
  }

  /// `sale`
  String get sale {
    return Intl.message(
      'sale',
      name: 'sale',
      desc: '',
      args: [],
    );
  }

  /// `construction`
  String get construction {
    return Intl.message(
      'construction',
      name: 'construction',
      desc: '',
      args: [],
    );
  }

  /// `construction and subdivisions`
  String get constructionAndSubdivisions {
    return Intl.message(
      'construction and subdivisions',
      name: 'constructionAndSubdivisions',
      desc: '',
      args: [],
    );
  }

  /// `subdivisions into unit`
  String get subdivisionsIntoUnit {
    return Intl.message(
      'subdivisions into unit',
      name: 'subdivisionsIntoUnit',
      desc: '',
      args: [],
    );
  }

  /// `lien`
  String get lien {
    return Intl.message(
      'lien',
      name: 'lien',
      desc: '',
      args: [],
    );
  }

  /// `lien removal`
  String get lienRemoval {
    return Intl.message(
      'lien removal',
      name: 'lienRemoval',
      desc: '',
      args: [],
    );
  }

  /// `easement`
  String get easement {
    return Intl.message(
      'easement',
      name: 'easement',
      desc: '',
      args: [],
    );
  }

  /// `inheritance`
  String get inheritance {
    return Intl.message(
      'inheritance',
      name: 'inheritance',
      desc: '',
      args: [],
    );
  }

  /// `notation`
  String get notation {
    return Intl.message(
      'notation',
      name: 'notation',
      desc: '',
      args: [],
    );
  }

  /// `This transaction does not require a value`
  String get thisTransactionDoesNotRequireAvalue {
    return Intl.message(
      'This transaction does not require a value',
      name: 'thisTransactionDoesNotRequireAvalue',
      desc: '',
      args: [],
    );
  }

  /// `If you have the rental value only, multiply it by 30 and enter the result in the amount field above`
  String get ifYouHaveTheRentalValueOnlyMultiplyIt {
    return Intl.message(
      'If you have the rental value only, multiply it by 30 and enter the result in the amount field above',
      name: 'ifYouHaveTheRentalValueOnlyMultiplyIt',
      desc: '',
      args: [],
    );
  }

  /// `Transaction Type`
  String get transactionType {
    return Intl.message(
      'Transaction Type',
      name: 'transactionType',
      desc: '',
      args: [],
    );
  }

  /// `Select Transaction Type`
  String get selectTransactionType {
    return Intl.message(
      'Select Transaction Type',
      name: 'selectTransactionType',
      desc: '',
      args: [],
    );
  }

  /// `Value L.L`
  String get valueL {
    return Intl.message(
      'Value L.L',
      name: 'valueL',
      desc: '',
      args: [],
    );
  }

  /// `Enter value in L.L`
  String get enterValueInL {
    return Intl.message(
      'Enter value in L.L',
      name: 'enterValueInL',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get reset {
    return Intl.message(
      'Reset',
      name: 'reset',
      desc: '',
      args: [],
    );
  }

  /// `Fees Calculation`
  String get feesCalculation {
    return Intl.message(
      'Fees Calculation',
      name: 'feesCalculation',
      desc: '',
      args: [],
    );
  }

  /// `Request Type`
  String get requestType {
    return Intl.message(
      'Request Type',
      name: 'requestType',
      desc: '',
      args: [],
    );
  }

  /// `Select Request Type`
  String get selectRequestType {
    return Intl.message(
      'Select Request Type',
      name: 'selectRequestType',
      desc: '',
      args: [],
    );
  }

  /// `First Name`
  String get firstName {
    return Intl.message(
      'First Name',
      name: 'firstName',
      desc: '',
      args: [],
    );
  }

  /// `Enter your first name`
  String get enterYourFirstName {
    return Intl.message(
      'Enter your first name',
      name: 'enterYourFirstName',
      desc: '',
      args: [],
    );
  }

  /// `First Name is required`
  String get firstNameIsRequired {
    return Intl.message(
      'First Name is required',
      name: 'firstNameIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Last Name`
  String get lastName {
    return Intl.message(
      'Last Name',
      name: 'lastName',
      desc: '',
      args: [],
    );
  }

  /// `Enter your last name`
  String get enterYourlastName {
    return Intl.message(
      'Enter your last name',
      name: 'enterYourlastName',
      desc: '',
      args: [],
    );
  }

  /// `Last Name is required`
  String get lastNameIsRequired {
    return Intl.message(
      'Last Name is required',
      name: 'lastNameIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Telephone`
  String get telephone {
    return Intl.message(
      'Telephone',
      name: 'telephone',
      desc: '',
      args: [],
    );
  }

  /// `Enter your telephone number`
  String get enterYourTelephoneNumber {
    return Intl.message(
      'Enter your telephone number',
      name: 'enterYourTelephoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Telephone is required`
  String get telephoneIsRequired {
    return Intl.message(
      'Telephone is required',
      name: 'telephoneIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message(
      'Email',
      name: 'email',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email address`
  String get enterYourEmailAddress {
    return Intl.message(
      'Enter your email address',
      name: 'enterYourEmailAddress',
      desc: '',
      args: [],
    );
  }

  /// `Email is required`
  String get emailIsRequired {
    return Intl.message(
      'Email is required',
      name: 'emailIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Invalid email address`
  String get invalidEmailAddress {
    return Intl.message(
      'Invalid email address',
      name: 'invalidEmailAddress',
      desc: '',
      args: [],
    );
  }

  /// `Confirm Email`
  String get confirmEmail {
    return Intl.message(
      'Confirm Email',
      name: 'confirmEmail',
      desc: '',
      args: [],
    );
  }

  /// `Confirm your email address`
  String get confirmYourEmailAddress {
    return Intl.message(
      'Confirm your email address',
      name: 'confirmYourEmailAddress',
      desc: '',
      args: [],
    );
  }

  /// `Confirm Email is required`
  String get confirmEmailIsRequired {
    return Intl.message(
      'Confirm Email is required',
      name: 'confirmEmailIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `City`
  String get city {
    return Intl.message(
      'City',
      name: 'city',
      desc: '',
      args: [],
    );
  }

  /// `Enter your city`
  String get enterYourCity {
    return Intl.message(
      'Enter your city',
      name: 'enterYourCity',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get address {
    return Intl.message(
      'Address',
      name: 'address',
      desc: '',
      args: [],
    );
  }

  /// `Enter your address`
  String get enterYourAddress {
    return Intl.message(
      'Enter your address',
      name: 'enterYourAddress',
      desc: '',
      args: [],
    );
  }

  /// `Proceed`
  String get proceed {
    return Intl.message(
      'Proceed',
      name: 'proceed',
      desc: '',
      args: [],
    );
  }

  /// `Province`
  String get province {
    return Intl.message(
      'Province',
      name: 'province',
      desc: '',
      args: [],
    );
  }

  /// `Province is required`
  String get provinceIsRequired {
    return Intl.message(
      'Province is required',
      name: 'provinceIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Caza`
  String get caza {
    return Intl.message(
      'Caza',
      name: 'caza',
      desc: '',
      args: [],
    );
  }

  /// `Caza is required`
  String get cazaIsRequired {
    return Intl.message(
      'Caza is required',
      name: 'cazaIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Cadastral Zone`
  String get cadastralZone {
    return Intl.message(
      'Cadastral Zone',
      name: 'cadastralZone',
      desc: '',
      args: [],
    );
  }

  /// `Cadastral Zone is required`
  String get cadastralZoneIsRequired {
    return Intl.message(
      'Cadastral Zone is required',
      name: 'cadastralZoneIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Parcel No`
  String get parcelNo {
    return Intl.message(
      'Parcel No',
      name: 'parcelNo',
      desc: '',
      args: [],
    );
  }

  /// `Parcel No is required`
  String get parcelNoIsRequired {
    return Intl.message(
      'Parcel No is required',
      name: 'parcelNoIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Unit No`
  String get unitNo {
    return Intl.message(
      'Unit No',
      name: 'unitNo',
      desc: '',
      args: [],
    );
  }

  /// `Enter Unit No`
  String get enterUnitNo {
    return Intl.message(
      'Enter Unit No',
      name: 'enterUnitNo',
      desc: '',
      args: [],
    );
  }

  /// `Block No`
  String get blockNo {
    return Intl.message(
      'Block No',
      name: 'blockNo',
      desc: '',
      args: [],
    );
  }

  /// `Enter Block No`
  String get enterBlockNo {
    return Intl.message(
      'Enter Block No',
      name: 'enterBlockNo',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get add {
    return Intl.message(
      'Add',
      name: 'add',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Retrieve`
  String get retrieve {
    return Intl.message(
      'Retrieve',
      name: 'retrieve',
      desc: '',
      args: [],
    );
  }

  /// `Cost`
  String get cost {
    return Intl.message(
      'Cost',
      name: 'cost',
      desc: '',
      args: [],
    );
  }

  /// `Total`
  String get total {
    return Intl.message(
      'Total',
      name: 'total',
      desc: '',
      args: [],
    );
  }

  /// `Area Office`
  String get areaOffice {
    return Intl.message(
      'Area Office',
      name: 'areaOffice',
      desc: '',
      args: [],
    );
  }

  /// `Select Area Office`
  String get selectAreaOffice {
    return Intl.message(
      'Select Area Office',
      name: 'selectAreaOffice',
      desc: '',
      args: [],
    );
  }

  /// `Application Date`
  String get applicationDate {
    return Intl.message(
      'Application Date',
      name: 'applicationDate',
      desc: '',
      args: [],
    );
  }

  /// `Application No`
  String get applicationNo {
    return Intl.message(
      'Application No',
      name: 'applicationNo',
      desc: '',
      args: [],
    );
  }

  /// `The application did not reach this stage`
  String get theApplicationDidNotReachThisStage {
    return Intl.message(
      'The application did not reach this stage',
      name: 'theApplicationDidNotReachThisStage',
      desc: '',
      args: [],
    );
  }

  /// `The application is not fully completed`
  String get theApplicationIsNotFullyCompleted {
    return Intl.message(
      'The application is not fully completed',
      name: 'theApplicationIsNotFullyCompleted',
      desc: '',
      args: [],
    );
  }

  /// `The application is completed`
  String get theApplicationIsCompleted {
    return Intl.message(
      'The application is completed',
      name: 'theApplicationIsCompleted',
      desc: '',
      args: [],
    );
  }

  /// `Show result`
  String get showResult {
    return Intl.message(
      'Show result',
      name: 'showResult',
      desc: '',
      args: [],
    );
  }

  /// `Action Date`
  String get actionDate {
    return Intl.message(
      'Action Date',
      name: 'actionDate',
      desc: '',
      args: [],
    );
  }

  /// `Staff`
  String get staff {
    return Intl.message(
      'Staff',
      name: 'staff',
      desc: '',
      args: [],
    );
  }

  /// `Status Description`
  String get statusDescription {
    return Intl.message(
      'Status Description',
      name: 'statusDescription',
      desc: '',
      args: [],
    );
  }

  /// `Area Officer`
  String get areaOfficer {
    return Intl.message(
      'Area Officer',
      name: 'areaOfficer',
      desc: '',
      args: [],
    );
  }

  /// `Registrar`
  String get registrar {
    return Intl.message(
      'Registrar',
      name: 'registrar',
      desc: '',
      args: [],
    );
  }

  /// `Recorder`
  String get recorder {
    return Intl.message(
      'Recorder',
      name: 'recorder',
      desc: '',
      args: [],
    );
  }

  /// `Assistant Registrar`
  String get assistantRegistrar {
    return Intl.message(
      'Assistant Registrar',
      name: 'assistantRegistrar',
      desc: '',
      args: [],
    );
  }

  /// `Transaction already added`
  String get transactionAlreadyAdded {
    return Intl.message(
      'Transaction already added',
      name: 'transactionAlreadyAdded',
      desc: '',
      args: [],
    );
  }

  /// `Please select a province`
  String get pleaseSelectaProvince {
    return Intl.message(
      'Please select a province',
      name: 'pleaseSelectaProvince',
      desc: '',
      args: [],
    );
  }

  /// `Please select a caza`
  String get pleaseSelectCaza {
    return Intl.message(
      'Please select a caza',
      name: 'pleaseSelectCaza',
      desc: '',
      args: [],
    );
  }

  /// `Please select a cadastral zone`
  String get pleaseSelectCadastralZone {
    return Intl.message(
      'Please select a cadastral zone',
      name: 'pleaseSelectCadastralZone',
      desc: '',
      args: [],
    );
  }

  /// `Confirm Remove`
  String get confirmRemove {
    return Intl.message(
      'Confirm Remove',
      name: 'confirmRemove',
      desc: '',
      args: [],
    );
  }

  /// `Are You Sure You Want To Remove The Transaction ?`
  String get areYouSureYouWantToRemoveTheTransaction {
    return Intl.message(
      'Are You Sure You Want To Remove The Transaction ?',
      name: 'areYouSureYouWantToRemoveTheTransaction',
      desc: '',
      args: [],
    );
  }

  /// `Select date`
  String get selectDate {
    return Intl.message(
      'Select date',
      name: 'selectDate',
      desc: '',
      args: [],
    );
  }

  /// `Daily Registered Number`
  String get dailyRegisteredNumber {
    return Intl.message(
      'Daily Registered Number',
      name: 'dailyRegisteredNumber',
      desc: '',
      args: [],
    );
  }

  /// `Enter daily registered number`
  String get enterDailyRegisteredNumber {
    return Intl.message(
      'Enter daily registered number',
      name: 'enterDailyRegisteredNumber',
      desc: '',
      args: [],
    );
  }

  /// `Submit`
  String get submit {
    return Intl.message(
      'Submit',
      name: 'submit',
      desc: '',
      args: [],
    );
  }

  /// `Personal Information`
  String get personalInformation {
    return Intl.message(
      'Personal Information',
      name: 'personalInformation',
      desc: '',
      args: [],
    );
  }

  /// `Sales Fee %`
  String get salesFee {
    return Intl.message(
      'Sales Fee %',
      name: 'salesFee',
      desc: '',
      args: [],
    );
  }

  /// `Deed fee`
  String get deedFee {
    return Intl.message(
      'Deed fee',
      name: 'deedFee',
      desc: '',
      args: [],
    );
  }

  /// `Contract fee`
  String get contractFee {
    return Intl.message(
      'Contract fee',
      name: 'contractFee',
      desc: '',
      args: [],
    );
  }

  /// `New deed fee (deed exchange)`
  String get newDeedFee {
    return Intl.message(
      'New deed fee (deed exchange)',
      name: 'newDeedFee',
      desc: '',
      args: [],
    );
  }

  /// `Municipality fee 5% of the total amount`
  String get municipalityFee {
    return Intl.message(
      'Municipality fee 5% of the total amount',
      name: 'municipalityFee',
      desc: '',
      args: [],
    );
  }

  /// `Contract stamp fee`
  String get contractStampFee {
    return Intl.message(
      'Contract stamp fee',
      name: 'contractStampFee',
      desc: '',
      args: [],
    );
  }

  /// `Stamp fee 4 per thousand of the amount`
  String get stampFee {
    return Intl.message(
      'Stamp fee 4 per thousand of the amount',
      name: 'stampFee',
      desc: '',
      args: [],
    );
  }

  /// `Lawyers syndicate fee 1 per thousand of the amount`
  String get lawyersFee {
    return Intl.message(
      'Lawyers syndicate fee 1 per thousand of the amount',
      name: 'lawyersFee',
      desc: '',
      args: [],
    );
  }

  /// `Deed stamp fee`
  String get deedStampFee {
    return Intl.message(
      'Deed stamp fee',
      name: 'deedStampFee',
      desc: '',
      args: [],
    );
  }

  /// `Construction fee 1%`
  String get constructionFee {
    return Intl.message(
      'Construction fee 1%',
      name: 'constructionFee',
      desc: '',
      args: [],
    );
  }

  /// `Advance topographic fee`
  String get advanceTopographicFee {
    return Intl.message(
      'Advance topographic fee',
      name: 'advanceTopographicFee',
      desc: '',
      args: [],
    );
  }

  /// `Recording fee`
  String get recordingFee {
    return Intl.message(
      'Recording fee',
      name: 'recordingFee',
      desc: '',
      args: [],
    );
  }

  /// `Construction and subdivision fee 1%`
  String get constructionAndSubdivisionfee {
    return Intl.message(
      'Construction and subdivision fee 1%',
      name: 'constructionAndSubdivisionfee',
      desc: '',
      args: [],
    );
  }

  /// `Deed fee - for each non-common unit`
  String get deedFeeUunit {
    return Intl.message(
      'Deed fee - for each non-common unit',
      name: 'deedFeeUunit',
      desc: '',
      args: [],
    );
  }

  /// `Recording fee for each unit`
  String get recordingFeeUnit {
    return Intl.message(
      'Recording fee for each unit',
      name: 'recordingFeeUnit',
      desc: '',
      args: [],
    );
  }

  /// `Topographic fee 1%`
  String get topographicFee {
    return Intl.message(
      'Topographic fee 1%',
      name: 'topographicFee',
      desc: '',
      args: [],
    );
  }

  /// `Lien fee 1%`
  String get lienFee {
    return Intl.message(
      'Lien fee 1%',
      name: 'lienFee',
      desc: '',
      args: [],
    );
  }

  /// `Photocopy fee - on each page of the lien contract`
  String get photocopyFee {
    return Intl.message(
      'Photocopy fee - on each page of the lien contract',
      name: 'photocopyFee',
      desc: '',
      args: [],
    );
  }

  /// `Stamp fee 4 per thousand of the amount`
  String get stampFeePerThousand {
    return Intl.message(
      'Stamp fee 4 per thousand of the amount',
      name: 'stampFeePerThousand',
      desc: '',
      args: [],
    );
  }

  /// `Lien removal fee 1%`
  String get lienRemovalFee {
    return Intl.message(
      'Lien removal fee 1%',
      name: 'lienRemovalFee',
      desc: '',
      args: [],
    );
  }

  /// `Fee 5 %`
  String get fee5 {
    return Intl.message(
      'Fee 5 %',
      name: 'fee5',
      desc: '',
      args: [],
    );
  }

  /// `Recording fee 7500 L.L. for each property`
  String get recordingFeeProperty {
    return Intl.message(
      'Recording fee 7500 L.L. for each property',
      name: 'recordingFeeProperty',
      desc: '',
      args: [],
    );
  }

  /// `Deed fee (3750 * no of owners)`
  String get deedFeeOwners {
    return Intl.message(
      'Deed fee (3750 * no of owners)',
      name: 'deedFeeOwners',
      desc: '',
      args: [],
    );
  }

  /// `Application fee`
  String get applicationFee {
    return Intl.message(
      'Application fee',
      name: 'applicationFee',
      desc: '',
      args: [],
    );
  }

  /// `Data is updated Until`
  String get dataIsUpdatedUntil {
    return Intl.message(
      'Data is updated Until',
      name: 'dataIsUpdatedUntil',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get username {
    return Intl.message(
      'Username',
      name: 'username',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message(
      'Password',
      name: 'password',
      desc: '',
      args: [],
    );
  }

  /// `Forget Password`
  String get forgerPassword {
    return Intl.message(
      'Forget Password',
      name: 'forgerPassword',
      desc: '',
      args: [],
    );
  }

  /// `Register`
  String get register {
    return Intl.message(
      'Register',
      name: 'register',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message(
      'Login',
      name: 'login',
      desc: '',
      args: [],
    );
  }

  /// `Request Date`
  String get requestDate {
    return Intl.message(
      'Request Date',
      name: 'requestDate',
      desc: '',
      args: [],
    );
  }

  /// `Request No`
  String get requestNo {
    return Intl.message(
      'Request No',
      name: 'requestNo',
      desc: '',
      args: [],
    );
  }

  /// `Stage`
  String get stage {
    return Intl.message(
      'Stage',
      name: 'stage',
      desc: '',
      args: [],
    );
  }

  /// `Stage Description`
  String get stageDescription {
    return Intl.message(
      'Stage Description',
      name: 'stageDescription',
      desc: '',
      args: [],
    );
  }

  /// `Request Certication`
  String get requestCertication {
    return Intl.message(
      'Request Certication',
      name: 'requestCertication',
      desc: '',
      args: [],
    );
  }

  /// `Request Approval`
  String get requestApproval {
    return Intl.message(
      'Request Approval',
      name: 'requestApproval',
      desc: '',
      args: [],
    );
  }

  /// `Ownership Query`
  String get ownershipQuery {
    return Intl.message(
      'Ownership Query',
      name: 'ownershipQuery',
      desc: '',
      args: [],
    );
  }

  /// `Request Receipt`
  String get requestReceipt {
    return Intl.message(
      'Request Receipt',
      name: 'requestReceipt',
      desc: '',
      args: [],
    );
  }

  /// `Moral Entity`
  String get moralEntity {
    return Intl.message(
      'Moral Entity',
      name: 'moralEntity',
      desc: '',
      args: [],
    );
  }

  /// `Year Of Birth`
  String get yearOfBirth {
    return Intl.message(
      'Year Of Birth',
      name: 'yearOfBirth',
      desc: '',
      args: [],
    );
  }

  /// `Registration Place`
  String get registrationPlace {
    return Intl.message(
      'Registration Place',
      name: 'registrationPlace',
      desc: '',
      args: [],
    );
  }

  /// `Registration No`
  String get registrationNo {
    return Intl.message(
      'Registration No',
      name: 'registrationNo',
      desc: '',
      args: [],
    );
  }

  /// `Party`
  String get part {
    return Intl.message(
      'Party',
      name: 'part',
      desc: '',
      args: [],
    );
  }

  /// `The Invoice Of The Last Transaction Will Be Displayed`
  String get theInvoiceOfTheLastTransactionWillBeDisplayed {
    return Intl.message(
      'The Invoice Of The Last Transaction Will Be Displayed',
      name: 'theInvoiceOfTheLastTransactionWillBeDisplayed',
      desc: '',
      args: [],
    );
  }

  /// `Invoice Details For Applications No`
  String get invoicesDetailsForApplicationNo {
    return Intl.message(
      'Invoice Details For Applications No',
      name: 'invoicesDetailsForApplicationNo',
      desc: '',
      args: [],
    );
  }

  /// `Date`
  String get date {
    return Intl.message(
      'Date',
      name: 'date',
      desc: '',
      args: [],
    );
  }

  /// `Show Details`
  String get showDetails {
    return Intl.message(
      'Show Details',
      name: 'showDetails',
      desc: '',
      args: [],
    );
  }

  /// `Hide Details`
  String get hideDetails {
    return Intl.message(
      'Hide Details',
      name: 'hideDetails',
      desc: '',
      args: [],
    );
  }

  /// `Required`
  String get required {
    return Intl.message(
      'Required',
      name: 'required',
      desc: '',
      args: [],
    );
  }

  /// `Invoice Date`
  String get invoiceDate {
    return Intl.message(
      'Invoice Date',
      name: 'invoiceDate',
      desc: '',
      args: [],
    );
  }

  /// `Invoice No`
  String get invoiceNo {
    return Intl.message(
      'Invoice No',
      name: 'invoiceNo',
      desc: '',
      args: [],
    );
  }

  /// `Invoice Amount`
  String get invoiceAmount {
    return Intl.message(
      'Invoice Amount',
      name: 'invoiceAmount',
      desc: '',
      args: [],
    );
  }

  /// `Invoice Status`
  String get invoiceStatus {
    return Intl.message(
      'Invoice Status',
      name: 'invoiceStatus',
      desc: '',
      args: [],
    );
  }

  /// `Payment Date`
  String get paymentDate {
    return Intl.message(
      'Payment Date',
      name: 'paymentDate',
      desc: '',
      args: [],
    );
  }

  /// `NoticationDate`
  String get notificationDate {
    return Intl.message(
      'NoticationDate',
      name: 'notificationDate',
      desc: '',
      args: [],
    );
  }

  /// `Area Office Is Required`
  String get areaOfficeIsRequired {
    return Intl.message(
      'Area Office Is Required',
      name: 'areaOfficeIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Request Type Is Required`
  String get requestTypeIsRequired {
    return Intl.message(
      'Request Type Is Required',
      name: 'requestTypeIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Date Is Required`
  String get dateIsRequired {
    return Intl.message(
      'Date Is Required',
      name: 'dateIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Network error. Please check your connection and try again`
  String get networkError {
    return Intl.message(
      'Network error. Please check your connection and try again',
      name: 'networkError',
      desc: '',
      args: [],
    );
  }

  /// `Authentication failed. Please log in again`
  String get authenticationError {
    return Intl.message(
      'Authentication failed. Please log in again',
      name: 'authenticationError',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load data. Please try again later`
  String get dataFetchingError {
    return Intl.message(
      'Failed to load data. Please try again later',
      name: 'dataFetchingError',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong. Please try again`
  String get unexpectedError {
    return Intl.message(
      'Something went wrong. Please try again',
      name: 'unexpectedError',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
