import 'package:flutter_application_1/screens/main.dart';
import 'package:flutter_application_1/screens/main_screen.dart';
import 'package:flutter_application_1/screens/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App initialization and navigation test',
      (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const MyApp());

    // Verify the SplashScreen is shown
    expect(find.byType(SplashScreen), findsOneWidget);

    // Wait for the SplashScreen to finish and navigate to MainScreen
    await tester
        .pumpAndSettle(); // Ensure all animations and frames are processed
    await Future.delayed(const Duration(seconds: 3), () {});
    await tester.pumpAndSettle(); // Wait for navigation to complete

    // Verify the MainScreen is shown after the splash screen
    expect(find.byType(MainScreen), findsOneWidget);
  });
}
