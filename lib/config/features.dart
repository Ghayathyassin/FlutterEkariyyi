import 'package:flutter/foundation.dart';

/// Platform-driven feature switches.
///
/// Keep every such switch here rather than at the call sites, so the home grid,
/// the drawer and the push deep-link allowlist can never drift out of sync.
class Features {
  Features._();

  /// Whether the **Title Register** purchase flow is available.
  ///
  /// Disabled on iOS. `title_register.dart` is the sole entry point to the
  /// checkout screens (`PersonalInformation` -> `PaymentDetails`) and to
  /// `PendingPaymentScreen`, so turning it off here takes the whole card-payment
  /// flow off iOS — deliberate, pending the App Store payment-policy question
  /// (see CLAUDE.md, iOS section). Android is unaffected.
  ///
  /// Uses `defaultTargetPlatform` rather than `dart:io`'s `Platform.isIOS` so
  /// the check is safe on web/desktop too (`dart:io` is unavailable on web).
  static bool get titleRegister =>
      defaultTargetPlatform != TargetPlatform.iOS;
}
