// Drives the app through the screens shown on the App Store listing.
//
// Run by .github/workflows/ios-store-screenshots.yml on iOS simulators. The
// test does not capture anything itself: at each screen it prints a
// `STORE_SHOT:<name>` marker and holds still while the workflow grabs the
// simulator screen with `xcrun simctl io screenshot`, which gives the exact
// pixel sizes App Store Connect asks for (status bar included).
//
// It mirrors main() in lib/screens/main.dart minus the permission prompts
// (requestPermission / NotificationService.init), which would otherwise put a
// system dialog on top of every screenshot.
//
// Language: --dart-define=SHOT_LANG=ar|en (default ar).

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/drawer_state.dart';
import 'package:flutter_application_1/models/payment_provider.dart';
import 'package:flutter_application_1/screens/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _lang = String.fromEnvironment('SHOT_LANG', defaultValue: 'ar');

/// Lets the screen finish loading, then signals the workflow and holds still
/// long enough for the screenshot to be taken.
Future<void> _shot(WidgetTester tester, String name) async {
  await _settle(tester, const Duration(seconds: 4));
  // ignore: avoid_print
  print('STORE_SHOT:$name');
  await _settle(tester, const Duration(seconds: 6));
}

/// Pumps frames for [d] of real time. Used instead of pumpAndSettle, which can
/// time out on screens with looping animations or pending network requests.
Future<void> _settle(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, String route, String name) async {
  app.navigatorKey.currentState!.pushNamed(route);
  await _shot(tester, name);
  app.navigatorKey.currentState!.pop();
  await _settle(tester, const Duration(seconds: 1));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App Store screenshots', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', _lang);

    await Firebase.initializeApp();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DrawerState()),
          ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ],
        child: const app.MyApp(),
      ),
    );

    // Splash waits 3 s, then routes to the home screen.
    await _settle(tester, const Duration(seconds: 6));
    await _shot(tester, '1_home');

    tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await _shot(tester, '2_menu');
    app.navigatorKey.currentState!.pop(); // close the drawer
    await _settle(tester, const Duration(seconds: 1));

    await _open(tester, '/transactionTracking', '3_transaction_tracking');
    await _open(tester, '/feesSimulation', '4_fees_simulation');
    await _open(tester, '/titleRegisterChange', '5_title_register_changes');
    await _open(tester, '/ownershipTracking', '6_ownership_tracking');

    // ignore: avoid_print
    print('STORE_SHOT_DONE');
  });
}
