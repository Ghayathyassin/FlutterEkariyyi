import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_application_1/models/drawer_state.dart';
import 'package:flutter_application_1/models/payment_provider.dart';
import 'package:flutter_application_1/screens/fee_simulation.dart';
import 'package:flutter_application_1/screens/index.dart';
import 'package:flutter_application_1/screens/ownership_tracking.dart';
import 'package:flutter_application_1/screens/paid_invoices.dart';
import 'package:flutter_application_1/screens/title_register_change.dart';
import 'package:flutter_application_1/screens/title_register.dart';
import 'package:flutter_application_1/screens/transaction_tracking.dart';
import 'package:flutter_application_1/widgets/error_snackbar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../generated/l10n.dart';
import '../services/notification_service.dart';
import '../services/push_token_service.dart';
import '../theme/app_theme.dart';
import 'splash_screen.dart';

/// Global navigator key so push-notification taps can navigate without a
/// BuildContext (the tap arrives outside the widget tree).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Handles a push delivered while the app is in the background or terminated.
/// Runs in its own isolate, so Firebase must be initialised here. Notification-
/// payload messages are shown by the OS automatically; this exists so data-only
/// messages don't get dropped (and gives us a hook for future handling).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Levantine (Lebanese) month names, used instead of intl's default Arabic
/// (يناير، فبراير…). Applied to the shared `ar` DateSymbols so every Arabic
/// DateFormat AND the Material calendar picker use them.
const List<String> _levantineArabicMonths = [
  'كانون الثاني', // January
  'شباط', // February
  'آذار', // March
  'نيسان', // April
  'أيار', // May
  'حزيران', // June
  'تموز', // July
  'آب', // August
  'أيلول', // September
  'تشرين الأول', // October
  'تشرين الثاني', // November
  'كانون الأول', // December
];

/// Overwrites the cached Arabic month names with the Levantine ones.
/// Must run AFTER the locale's symbols are loaded (i.e. after
/// GlobalMaterialLocalizations.load), otherwise that load replaces them with
/// intl's defaults again — which is exactly why the date picker kept showing
/// يناير/فبراير. The custom delegate below calls this on every `ar` load.
void _applyLevantineArabicMonths() {
  try {
    // `dateSymbols` returns the shared, cached DateSymbols for the locale;
    // its month lists are mutable, so this changes them app-wide (text + the
    // Material date-picker, which formats lazily through the same symbols).
    final symbols = DateFormat('MMMM', 'ar').dateSymbols;
    symbols.MONTHS = List<String>.from(_levantineArabicMonths);
    symbols.STANDALONEMONTHS = List<String>.from(_levantineArabicMonths);
    symbols.SHORTMONTHS = List<String>.from(_levantineArabicMonths);
    symbols.STANDALONESHORTMONTHS = List<String>.from(_levantineArabicMonths);
  } catch (e) {
    log('Levantine month init failed: $e');
  }
}

/// Wraps [GlobalMaterialLocalizations] so we can re-apply the Levantine month
/// override every time the `ar` Material localizations (re)load. Placed BEFORE
/// GlobalMaterialLocalizations.delegate in the delegates list so it wins for
/// Arabic; English falls through to the global delegate.
class _LevantineMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _LevantineMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ar';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    final localizations =
        await GlobalMaterialLocalizations.delegate.load(locale);
    // Symbols are now loaded for this locale; stamp our months on top.
    _applyLevantineArabicMonths();
    return localizations;
  }

  @override
  bool shouldReload(_LevantineMaterialLocalizationsDelegate old) => false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Paint the system status bar (clock / wifi / battery strip) with the brand
  // green, with light icons, on every screen.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppColors.primary,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  try {
    await Firebase.initializeApp();
    // Must be registered before runApp so background/terminated pushes are
    // routed to our handler.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission();
    // iOS: make sure foreground pushes surface as banners/sounds too.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await NotificationService.init();
  } catch (e) {
    log('Initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DrawerState()),
        ChangeNotifierProvider(create: (_) => PaymentProvider())
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    // Restore the language the user picked on a previous launch (if any) so the
    // whole app comes up in it.
    _loadSavedLocale();
    // Retrieve the token on app start up
    _getToken();
    _setupPushHandlers();
  }

  void _setupPushHandlers() {
    // Foreground: Android doesn't show pushes while the app is open, so display
    // them ourselves via the local-notifications plugin.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      if (n != null) {
        NotificationService.showRemote(
          title: n.title ?? '',
          body: n.body ?? '',
          payload: jsonEncode(message.data),
        );
      }
    });

    // Tapped while the app was in the background.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Tapped while the app was terminated (cold start from a notification).
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleMessageTap(message);
    });

    // Re-register the token with the backend when FCM rotates it.
    FirebaseMessaging.instance.onTokenRefresh.listen(PushTokenService.handleRefresh);
  }

  // Known named routes a notification is allowed to deep-link to. The backend
  // sends the target as `data: { "route": "/paidInvoices" }`; anything not in
  // this set is ignored (the app simply opens). Extend as the data contract
  // with the backend is finalized.
  static const Set<String> _pushRoutes = {
    '/index',
    '/titleRegister',
    '/transactionTracking',
    '/titleRegisterChange',
    '/feesSimulation',
    '/ownershipTracking',
    '/paidInvoices',
  };

  void _handleMessageTap(RemoteMessage message) {
    final route = message.data['route'];
    if (route is String && _pushRoutes.contains(route)) {
      navigatorKey.currentState?.pushNamed(route);
    }
  }

  void _getToken() async {
    try {
      // Fetched so Firebase provisions a push token for this install. The value
      // itself is a secret-ish identifier, so it is never logged.
      await FirebaseMessaging.instance.getToken();
      if (kDebugMode) log('FCM token acquired');
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context: context,
          message: S.of(context).unexpectedError,
        );
      }
    }
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('locale');
    if ((saved == 'en' || saved == 'ar') && mounted) {
      setState(() => _locale = Locale(saved!));
    }
  }

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    // Persist the choice so the language is remembered across launches (the
    // splash screen uses this to skip the picker once a language is set).
    _persistLocale(locale);
  }

  Future<void> _persistLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(isArabic: _locale.languageCode == 'ar'),
      routes: {
        '/index': (context) => Index(
              onLocaleChange: _setLocale,
            ),
        '/titleRegister': (context) =>
            TitleRegister(onLocaleChange: _setLocale),
        '/transactionTracking': (context) => TransactionTracking(
              onLocaleChange: _setLocale,
            ),
        '/titleRegisterChange': (context) => TitleRegisterChange(
              onLocaleChange: _setLocale,
            ),
        '/feesSimulation': (context) => FeesSimulation(
              onLocaleChange: _setLocale,
            ),
        '/ownershipTracking': (context) => OwnershipTracking(
              onLocaleChange: _setLocale,
            ),
        '/paidInvoices': (context) => PaidInvoices(
              onLocaleChange: _setLocale,
            ),

        // '/personalInformation': (context) => PersonalInformation(
        //       onLocaleChange: _setLocale,
        //       cartCount: 0,
        //       transactions: const [],
        //     ),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Index(
            onLocaleChange: _setLocale,
          ),
        );
      },
      title: 'Localizations',
      locale: _locale,
      localizationsDelegates: const [
        S.delegate,
        // Must come before GlobalMaterialLocalizations.delegate so it wins for
        // Arabic and re-applies the Levantine month names after each load.
        _LevantineMaterialLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      home: SplashScreen(
        onLocaleChange: _setLocale,
      ),
    );
  }
}
