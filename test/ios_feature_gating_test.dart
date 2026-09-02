// Verifies that the Title Register purchase flow is hidden on iOS and still
// present on Android.
//
// Why a test: `Features.titleRegister` is a compile-time-invisible, runtime
// platform check, and the iOS path cannot be exercised on the Windows dev
// machine. `debugDefaultTargetPlatformOverride` lets both branches be checked
// here, so a regression (a new entry point, or the drawer indices drifting)
// fails in CI instead of on a reviewer's iPhone.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_application_1/config/features.dart';
import 'package:flutter_application_1/generated/l10n.dart';
import 'package:flutter_application_1/models/drawer_state.dart';
import 'package:flutter_application_1/screens/index.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';

/// Minimal host: the localization delegates the screens need, plus the
/// [DrawerState] they read. Deliberately not `AppTheme`/`MyApp`, to keep
/// google_fonts and Firebase out of the test.
Widget _host(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: ChangeNotifierProvider(
        create: (_) => DrawerState(),
        child: child,
      ),
    );

/// Home-tile titles. `Category` renders them with `AutoSizeText`, which
/// `find.text` does not match — and which builds an inner `Text` with the same
/// string, so matching both types would double-count every tile.
Finder _tileTitle(String text) => find.byWidgetPredicate(
      (w) => w is AutoSizeText && w.data == text,
      description: 'tile titled "$text"',
    );

/// `testWidgets` asserts that all foundation debug variables are unset at the
/// end of the test body — before `addTearDown` callbacks run — so the platform
/// override has to be cleared inside the body.
Future<void> _asPlatform(
  TargetPlatform platform,
  Future<void> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  group('Features.titleRegister', () {
    test('is false on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(Features.titleRegister, isFalse);
    });

    test('is true on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(Features.titleRegister, isTrue);
    });
  });

  group('home dashboard', () {
    testWidgets('omits the Title Register tile on iOS', (tester) async {
      await _asPlatform(TargetPlatform.iOS, () async {
        await tester.pumpWidget(_host(Index(onLocaleChange: (_) {})));
        await tester.pumpAndSettle();

        expect(_tileTitle('Title Register'), findsNothing);
        // The other five tiles are untouched.
        expect(_tileTitle('Transaction Tracking'), findsOneWidget);
        expect(_tileTitle('Title Register Changes'), findsOneWidget);
        expect(_tileTitle('Paid Invoices'), findsOneWidget);
      });
    });

    testWidgets('keeps the Title Register tile on Android', (tester) async {
      await _asPlatform(TargetPlatform.android, () async {
        await tester.pumpWidget(_host(Index(onLocaleChange: (_) {})));
        await tester.pumpAndSettle();

        expect(_tileTitle('Title Register'), findsOneWidget);
        expect(_tileTitle('Transaction Tracking'), findsOneWidget);
      });
    });
  });

  group('side drawer', () {
    Future<void> openDrawer(WidgetTester tester) async {
      await tester.pumpWidget(_host(
        const Scaffold(drawer: SideDrawer(), body: SizedBox.shrink()),
      ));
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
    }

    testWidgets('omits the Title Register row on iOS', (tester) async {
      await _asPlatform(TargetPlatform.iOS, () async {
        await openDrawer(tester);

        expect(find.text('Title Register'), findsNothing);
        // Every other row survives — i.e. the remaining destinations did not
        // shift or get dropped along with it.
        expect(find.text('Homepage'), findsOneWidget);
        expect(find.text('Transaction Tracking'), findsOneWidget);
        expect(find.text('Title Register Changes'), findsOneWidget);
        expect(find.text('Paid Invoices'), findsOneWidget);
      });
    });

    testWidgets('keeps the Title Register row on Android', (tester) async {
      await _asPlatform(TargetPlatform.android, () async {
        await openDrawer(tester);

        expect(find.text('Title Register'), findsOneWidget);
        expect(find.text('Homepage'), findsOneWidget);
        expect(find.text('Paid Invoices'), findsOneWidget);
      });
    });
  });
}
