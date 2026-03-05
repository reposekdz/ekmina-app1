import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

class RwMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const RwMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'rw';

  @override
  Future<MaterialLocalizations> load(Locale locale) => SynchronousFuture<MaterialLocalizations>(
        _RwMaterialLocalizations(
          fullYearFormat: intl.DateFormat('yyyy', 'rw'),
          compactDateFormat: intl.DateFormat('yMd', 'rw'),
          shortDateFormat: intl.DateFormat('yMMMd', 'rw'),
          mediumDateFormat: intl.DateFormat('yMMMEd', 'rw'),
          longDateFormat: intl.DateFormat('yMMMMd', 'rw'),
          yearMonthFormat: intl.DateFormat('yMMMM', 'rw'),
          shortMonthDayFormat: intl.DateFormat('MMMd', 'rw'),
          decimalFormat: intl.NumberFormat.decimalPattern('rw'),
          twoDigitZeroPaddedFormat: intl.NumberFormat('00', 'rw'),
        ),
      );

  @override
  bool shouldReload(RwMaterialLocalizationsDelegate old) => false;
}

class _RwMaterialLocalizations extends GlobalMaterialLocalizations {
  const _RwMaterialLocalizations({
    required intl.DateFormat fullYearFormat,
    required intl.DateFormat compactDateFormat,
    required intl.DateFormat shortDateFormat,
    required intl.DateFormat mediumDateFormat,
    required intl.DateFormat longDateFormat,
    required intl.DateFormat yearMonthFormat,
    required intl.DateFormat shortMonthDayFormat,
    required intl.NumberFormat decimalFormat,
    required intl.NumberFormat twoDigitZeroPaddedFormat,
  }) : super(
          fullYearFormat: fullYearFormat,
          compactDateFormat: compactDateFormat,
          shortDateFormat: shortDateFormat,
          mediumDateFormat: mediumDateFormat,
          longDateFormat: longDateFormat,
          yearMonthFormat: yearMonthFormat,
          shortMonthDayFormat: shortMonthDayFormat,
          decimalFormat: decimalFormat,
          twoDigitZeroPaddedFormat: twoDigitZeroPaddedFormat,
        );

  @override
  String get aboutListTileTitleRaw => 'Ibijyanye na \$applicationName';

  @override
  String get alertDialogLabel => 'Iteguza';

  @override
  String get anteMeridiemAbbreviation => 'AM';

  @override
  String get backButtonTooltip => 'Gusubira inyuma';

  @override
  String get calendarModeButtonLabel => 'Guhindura kuri kalendari';

  @override
  String get cancelButtonLabel => 'Guhagarika';

  @override
  String get closeButtonLabel => 'Funga';

  @override
  String get closeButtonTooltip => 'Funga';

  @override
  String get collapsedIconTapHint => 'Kwerekana byose';

  @override
  String get continueButtonLabel => 'Komeza';

  @override
  String get copyButtonLabel => 'Kopi';

  @override
  String get cutButtonLabel => 'Gukata';

  @override
  String get deleteButtonTooltip => 'Siba';

  @override
  String get dialogLabel => 'Iteguza';

  @override
  String get drawerLabel => 'Ibikubiyemo';

  @override
  String get expandedIconTapHint => 'Guhisha';

  @override
  String get hideAccountsLabel => 'Hisha konti';

  @override
  String get licensesPageTitle => 'Impushya';

  @override
  String get modalBarrierDismissLabel => 'Kuraho';

  @override
  String get nextMonthTooltip => 'Ukwezi gutaha';

  @override
  String get nextPageTooltip => 'Ipaji ikurikira';

  @override
  String get okButtonLabel => 'Yego';

  @override
  String get openAppDrawerTooltip => 'Gufungura ibikubiyemo';

  @override
  String get pageRowsInfoTitleRaw => '\$firstRow–\$lastRow kuri \$rowCount';

  @override
  String get pageRowsInfoTitleApproximateRaw => '\$firstRow–\$lastRow kuri \$rowCount hafi';

  @override
  String get pasteButtonLabel => 'Komeka';

  @override
  String get popupMenuLabel => 'Ibikubiyemo byihuse';

  @override
  String get postMeridiemAbbreviation => 'PM';

  @override
  String get previousMonthTooltip => 'Ukwezi gushize';

  @override
  String get previousPageTooltip => 'Ipaji ishize';

  @override
  String get refreshIndicatorSemanticLabel => 'Ongera ufungure';

  @override
  String get remainingTextFieldCharacterCountZero => 'Nta nyuguti zisigaye';

  @override
  String get remainingTextFieldCharacterCountOne => 'Inyuguti 1 isigaye';

  @override
  String get remainingTextFieldCharacterCountOther => 'Inyuguti \$remainingCount zisigaye';

  @override
  String get rowsPerPageTitle => 'Imirongo ku ipaji:';

  @override
  String get saveButtonLabel => 'Bika';

  @override
  ScriptCategory get scriptCategory => ScriptCategory.englishLike;

  @override
  String get searchFieldLabel => 'Shakisha';

  @override
  String get selectAllButtonLabel => 'Hitamo byose';

  @override
  String get selectYearSemanticsLabel => 'Hitamo umwaka';

  @override
  String get showAccountsLabel => 'Erekana konti';

  @override
  String get showMenuTooltip => 'Erekana ibikubiyemo';

  @override
  String get signedInLabel => 'Winjiye';

  @override
  String get tabLabelRaw => 'Tab \$tabIndex kuri \$tabCount';

  @override
  TimeOfDayFormat get timeOfDayFormatRaw => TimeOfDayFormat.h_mm_a;

  @override
  String get timePickerHourModeAnnouncement => 'Hitamo amasaha';

  @override
  String get timePickerMinuteModeAnnouncement => 'Hitamo iminota';

  @override
  String get viewLicensesButtonLabel => 'Reba impushya';

  @override
  String get reorderItemToStart => 'Gushira ku ntangiriro';

  @override
  String get reorderItemToEnd => 'Gushira ku mpera';

  @override
  String get reorderItemUp => 'Kuzamura';

  @override
  String get reorderItemDown => 'Kumanura';

  @override
  String get reorderItemLeft => 'Gushira ibumoso';

  @override
  String get reorderItemRight => 'Gushira iburyo';

  @override
  String get expandedHint => 'Hishuwe';

  @override
  String get collapsedHint => 'Byagutse';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyAltGraph => 'AltGr';

  @override
  String get keyboardKeyBackspace => 'Backspace';

  @override
  String get keyboardKeyCapsLock => 'Caps Lock';

  @override
  String get keyboardKeyControl => 'Ctrl';

  @override
  String get keyboardKeyDelete => 'Del';

  @override
  String get keyboardKeyEscape => 'Esc';

  @override
  String get keyboardKeyHome => 'Home';

  @override
  String get keyboardKeyInsert => 'Ins';

  @override
  String get keyboardKeyMeta => 'Meta';

  @override
  String get keyboardKeyNumLock => 'Num Lock';

  @override
  String get keyboardKeyPageDown => 'PgDn';

  @override
  String get keyboardKeyPageUp => 'PgUp';

  @override
  String get keyboardKeyPrintScreen => 'PrtSc';

  @override
  String get keyboardKeyScrollLock => 'Scroll Lock';

  @override
  String get keyboardKeySelect => 'Select';

  @override
  String get keyboardKeySpace => 'Space';

  @override
  String get keyboardKeyShift => 'Shift';

  @override
  String get menuBarMenuLabel => 'Ibikubiyemo';

  @override
  String get bottomSheetLabel => 'Sheet yo hasi';

  @override
  String get currentDateLabel => 'Uyu munsi';

  @override
  String get dateHelpText => 'mm/dd/yyyy';

  @override
  String get dateInputLabel => 'Injiza itariki';

  @override
  String get dateOutOfRangeLabel => 'Itariki iri hanze y\'igihe cyemewe.';

  @override
  String get datePickerHelpText => 'HITAMO ITARIKI';

  @override
  String get dateRangeEndDateLabel => 'Itariki isoza';

  @override
  String get dateRangeEndErrorText => 'Itariki idahuye.';

  @override
  String get dateRangePickerHelpText => 'HITAMO IGIHE';

  @override
  String get dateRangeStartDateLabel => 'Itariki itangira';

  @override
  String get dateRangeStartErrorText => 'Itariki idahuye.';

  @override
  String get dateSeparator => '/';

  @override
  String get dialModeButtonLabel => 'Guhindura kuri dial';

  @override
  String get inputDateModeButtonLabel => 'Guhindura kuri input';

  @override
  String get inputTimeModeButtonLabel => 'Guhindura kuri text input';

  @override
  String get invalidDateFormatLabel => 'Itariki ntabwo yemewe.';

  @override
  String get invalidDateRangeLabel => 'Igihe ntabwo cyemewe.';

  @override
  String get invalidTimeLabel => 'Isaha ntabwo yemewe.';

  @override
  String get firstPageTooltip => 'Ipaji ya mbere';

  @override
  String get lastPageTooltip => 'Ipaji ya nyuma';

  @override
  String get lookUpButtonLabel => 'Shakisha';

  @override
  String get menuDismissLabel => 'Kuraho menu';

  @override
  String get moreButtonTooltip => 'Ibindi';

  @override
  String get scrimLabel => 'Hisha';

  @override
  String get scrimOnTapHintRaw => 'Kuraho \$modalRouteContentName';

  @override
  String get searchWebButtonLabel => 'Shakisha kuri internet';

  @override
  String get selectYearTooltip => 'Hitamo umwaka';

  @override
  String get shareButtonLabel => 'Sangiza';

  @override
  String get timePickerDialHelpText => 'HITAMO ISAHA';

  @override
  String get timePickerHourLabel => 'Isaha';

  @override
  String get timePickerInputHelpText => 'INJIZA ISAHA';

  @override
  String get timePickerMinuteLabel => 'Umunota';

  @override
  String get unspecifiedDate => 'Itariki';

  @override
  String get unspecifiedDateRange => 'Igihe';

  @override
  String get keyboardKeyMetaMacOs => 'Command';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get clearButtonTooltip => 'Gusiba';

  @override
  String get dateRangeEndDateSemanticLabelRaw => 'Itariki isoza \$fullDate';

  @override
  String get dateRangeStartDateSemanticLabelRaw => 'Itariki itangira \$fullDate';

  @override
  String get dateRangeEndLabel => 'Itariki isoza';

  @override
  String get dateRangeStartLabel => 'Itariki itangira';

  @override
  String get expansionTileCollapsedHint => 'Kanda kabiri kugira ngo wagure';

  @override
  String get expansionTileCollapsedTapHint => 'Wagura kugira ngo ubone andi makuru';

  @override
  String get expansionTileExpandedHint => 'Kanda kabiri kugira ngo ugabanye';

  @override
  String get expansionTileExpandedTapHint => 'Gabanya';

  @override
  String get keyboardKeyChannelDown => 'Channel Down';

  @override
  String get keyboardKeyChannelUp => 'Channel Up';

  @override
  String get keyboardKeyEject => 'Eject';

  @override
  String get keyboardKeyEnd => 'End';

  @override
  String get keyboardKeyFn => 'Fn';

  @override
  String get keyboardKeyNumpad0 => 'Num 0';

  @override
  String get keyboardKeyNumpad1 => 'Num 1';

  @override
  String get keyboardKeyNumpad2 => 'Num 2';

  @override
  String get keyboardKeyNumpad3 => 'Num 3';

  @override
  String get keyboardKeyNumpad4 => 'Num 4';

  @override
  String get keyboardKeyNumpad5 => 'Num 5';

  @override
  String get keyboardKeyNumpad6 => 'Num 6';

  @override
  String get keyboardKeyNumpad7 => 'Num 7';

  @override
  String get keyboardKeyNumpad8 => 'Num 8';

  @override
  String get keyboardKeyNumpad9 => 'Num 9';

  @override
  String get keyboardKeyNumpadAdd => 'Num +';

  @override
  String get keyboardKeyNumpadComma => 'Num ,';

  @override
  String get keyboardKeyNumpadDecimal => 'Num .';

  @override
  String get keyboardKeyNumpadDivide => 'Num /';

  @override
  String get keyboardKeyNumpadEnter => 'Num Enter';

  @override
  String get keyboardKeyNumpadEqual => 'Num =';

  @override
  String get keyboardKeyNumpadMultiply => 'Num *';

  @override
  String get keyboardKeyNumpadParenLeft => 'Num (';

  @override
  String get keyboardKeyNumpadParenRight => 'Num )';

  @override
  String get keyboardKeyNumpadSubtract => 'Num -';

  @override
  String get keyboardKeyPower => 'Power';

  @override
  String get keyboardKeyPowerOff => 'Power Off';

  @override
  String get licensesPackageDetailTextOther => '\$licenseCount impushya';

  @override
  String get scanTextButtonLabel => 'Scan text';

  @override
  String get selectedDateLabel => 'Itariki yatoranyijwe';

  @override
  String get selectedRowCountTitleOther => 'Ibisubizo \$selectedRowCount byatoranyijwe';
}

class RwCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const RwCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'rw';

  @override
  Future<CupertinoLocalizations> load(Locale locale) => SynchronousFuture<CupertinoLocalizations>(
        _RwCupertinoLocalizations(
          fullYearFormat: intl.DateFormat('yyyy', 'rw'),
          dayFormat: intl.DateFormat('d', 'rw'),
          mediumDateFormat: intl.DateFormat('EEE, MMM d', 'rw'),
          singleDigitHourFormat: intl.DateFormat('H', 'rw'),
          singleDigitMinuteFormat: intl.DateFormat('m', 'rw'),
          doubleDigitMinuteFormat: intl.DateFormat('mm', 'rw'),
          singleDigitSecondFormat: intl.DateFormat('s', 'rw'),
          decimalFormat: intl.NumberFormat.decimalPattern('rw'),
        ),
      );

  @override
  bool shouldReload(RwCupertinoLocalizationsDelegate old) => false;
}

class _RwCupertinoLocalizations extends GlobalCupertinoLocalizations {
  const _RwCupertinoLocalizations({
    required intl.DateFormat fullYearFormat,
    required intl.DateFormat dayFormat,
    required intl.DateFormat mediumDateFormat,
    required intl.DateFormat singleDigitHourFormat,
    required intl.DateFormat singleDigitMinuteFormat,
    required intl.DateFormat doubleDigitMinuteFormat,
    required intl.DateFormat singleDigitSecondFormat,
    required intl.NumberFormat decimalFormat,
  }) : super(
          fullYearFormat: fullYearFormat,
          dayFormat: dayFormat,
          mediumDateFormat: mediumDateFormat,
          singleDigitHourFormat: singleDigitHourFormat,
          singleDigitMinuteFormat: singleDigitMinuteFormat,
          doubleDigitMinuteFormat: doubleDigitMinuteFormat,
          singleDigitSecondFormat: singleDigitSecondFormat,
          decimalFormat: decimalFormat,
        );

  @override
  String get alertDialogLabel => 'Iteguza';

  @override
  String get anteMeridiemAbbreviation => 'AM';

  @override
  String get copyButtonLabel => 'Kopi';

  @override
  String get cutButtonLabel => 'Gukata';

  @override
  String get datePickerDateOrderRaw => 'mdy';

  @override
  String get datePickerDateTimeOrderRaw => 'date_time_dayPeriod';

  @override
  String get datePickerHourSemanticsLabelOne => 'Isaha 1';

  @override
  String get datePickerHourSemanticsLabelOther => 'Amasaha \$hour';

  @override
  String get datePickerMinuteSemanticsLabelOne => 'Umunota 1';

  @override
  String get datePickerMinuteSemanticsLabelOther => 'Iminota \$minute';

  @override
  String get datePickerMonthSemanticsLabelOne => 'Ukwezi 1';

  @override
  String get datePickerMonthSemanticsLabelOther => 'Amezi \$month';

  @override
  String get datePickerYearSemanticsLabelOne => 'Umwaka 1';

  @override
  String get datePickerYearSemanticsLabelOther => 'Imyaka \$year';

  @override
  String get pasteButtonLabel => 'Komeka';

  @override
  String get postMeridiemAbbreviation => 'PM';

  @override
  String get selectAllButtonLabel => 'Hitamo byose';

  @override
  String get tabSemanticsLabelRaw => 'Tab \$tabIndex kuri \$tabCount';

  @override
  String get timerPickerHourLabelOne => 'isaha';

  @override
  String get timerPickerHourLabelOther => 'amasaha';

  @override
  String get timerPickerMinuteLabelOne => 'mun.';

  @override
  String get timerPickerMinuteLabelOther => 'min.';

  @override
  String get timerPickerSecondLabelOne => 'iseg.';

  @override
  String get timerPickerSecondLabelOther => 'iseg.';

  @override
  String get todayLabel => 'Uyu munsi';

  @override
  String get lookUpButtonLabel => 'Shakisha';

  @override
  String get menuDismissLabel => 'Kuraho';

  @override
  String get searchTextFieldPlaceholderLabel => 'Shakisha';

  @override
  String get shareButtonLabel => 'Sangiza';

  @override
  String get noSpellCheckReplacementsLabel => 'Nta kintu cyabonetse';

  @override
  String get backButtonLabel => 'Inyuma';

  @override
  String get cancelButtonLabel => 'Hagarika';

  @override
  String get clearButtonLabel => 'Siba';

  @override
  String get collapsedHint => 'Byagutse';

  @override
  String get expandedHint => 'Hishuwe';

  @override
  String get expansionTileCollapsedHint => 'Kanda kabiri kugira ngo wagure';

  @override
  String get expansionTileCollapsedTapHint => 'Wagura kugira ngo ubone andi makuru';

  @override
  String get expansionTileExpandedHint => 'Kanda kabiri kugira ngo ugabanye';

  @override
  String get expansionTileExpandedTapHint => 'Gabanya';

  @override
  String get modalBarrierDismissLabel => 'Kuraho';

  @override
  String get searchWebButtonLabel => 'Shakisha kuri internet';

  @override
  String get datePickerDateOrderString => 'mdy';

  @override
  String get datePickerDateTimeOrderString => 'date_time_dayPeriod';
}
