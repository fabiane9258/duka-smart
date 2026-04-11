import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app_settings.dart';
import 'screens/main_shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettingsController();
  await settings.load();
  if (!kIsWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(DukaSmartRoot(settings: settings));
}

const Color _kSeed = Color(0xFF0F766E);

ThemeData buildAppTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _kSeed,
    brightness: brightness,
  );
  final light = brightness == Brightness.light;
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor:
        light ? Colors.white : const Color(0xFF0F172A),
    appBarTheme: AppBarTheme(
      backgroundColor:
          light ? Colors.white : const Color(0xFF0F172A),
      foregroundColor:
          light ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: light ? Colors.white : const Color(0xFF1E293B),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor:
          light ? const Color(0xFFF9FAFB) : const Color(0xFF1E293B),
      selectedIconTheme: const IconThemeData(color: _kSeed),
      selectedLabelTextStyle: const TextStyle(
        color: _kSeed,
        fontWeight: FontWeight.w600,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:
          light ? Colors.white : const Color(0xFF1E293B),
      indicatorColor: _kSeed.withOpacity(0.22),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: light ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _kSeed,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: light
          ? const Color(0xFFF9FAFB)
          : const Color(0xFF334155),
      border: const OutlineInputBorder(),
    ),
  );
}

class DukaSmartRoot extends StatelessWidget {
  const DukaSmartRoot({super.key, required this.settings});

  final AppSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      controller: settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return MaterialApp(
            title: 'DukaSmart',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: settings.themeMode,
            locale: settings.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('sw'),
            ],
            home: const MainShellScreen(),
          );
        },
      ),
    );
  }
}
