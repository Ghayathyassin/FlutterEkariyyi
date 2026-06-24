import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'splash_screen.dart';

const storage = FlutterSecureStorage();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await FirebaseMessaging.instance.requestPermission();
    await NotificationService.init();
    await dotenv.load(fileName: ".env");
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
    // Retrieve the token on app start up
    _getToken();
    // Listen for incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null && kDebugMode) {
        log('Foreground push received');
      }
    });
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

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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
