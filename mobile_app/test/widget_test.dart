import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app_settings.dart';
import 'package:mobile_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppSettingsController settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = AppSettingsController();
    await settings.load();
  });

  testWidgets('App loads shell, greeting, and navigation', (WidgetTester tester) async {
    await tester.pumpWidget(DukaSmartRoot(settings: settings));
    await tester.pumpAndSettle();

    expect(find.text('DukaSmart'), findsOneWidget);
    expect(
      find.textContaining('Hi'),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Sales'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
