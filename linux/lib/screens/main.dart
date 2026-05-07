import 'dart:developer';
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
import 'splash_screen.dart';

const storage = FlutterSecureStorage();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await FirebaseMessaging.instance.requestPermission();
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
  String? _token;

  @override
  void initState() {
    super.initState();
    // Retrieve the token on app start up
    _getToken();
    // Listen for incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
      }
    });
  }

  void _getToken() async {
    try {
      _token = await FirebaseMessaging.instance.getToken();
      log('Token: $_token');
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
      theme: ThemeData(fontFamily: 'Segoe UI'),
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
