/// Single source of truth for the backend hosts.
///
/// The app talks to TWO different backends:
///   - [ws]  — the e-services API (payments, title register, accounts,
///             fee simulation, notifications, the /service/* tracking flow).
///             This is the CadasterOracleApi project.
///   - [lrc] — the transaction/invoice tracking API (books, areaoffices,
///             drtrack, nattrack, invctracking/*). A different team's system.
///
/// PRODUCTION (live, real database) — current values below.
///
/// The previous TEST environment, kept here for rollback:
///   ws  -> https:// test-app.lrc.gov.lb /api
///   lrc -> https:// nirs.lrc.gov.lb /api
/// (spaced out on purpose so a global find/replace over the codebase can't
/// silently rewrite this note.)
///
/// Every endpoint in the app is built as '${Api.ws}/...' or '${Api.lrc}/...',
/// so changing these two constants moves the whole app between environments.
class Api {
  Api._();

  /// e-services API — was the test-app host.
  static const String ws = 'https://api.lrc.gov.lb/ws_api/api';

  /// Tracking / invoices API — was the nirs host.
  static const String lrc = 'https://api.lrc.gov.lb/lrc_api/api';
}
