import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme brightness and app language, persisted locally.
class AppSettingsController extends ChangeNotifier {
  AppSettingsController();

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  static const _kDark = 'pref_dark_mode';
  static const _kLang = 'pref_language';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final dark = p.getBool(_kDark) ?? false;
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    final code = p.getString(_kLang) ?? 'en';
    _locale = Locale(code == 'sw' ? 'sw' : 'en');
    notifyListeners();
  }

  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> setDarkMode(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDark, dark);
    notifyListeners();
  }

  Future<void> toggleTheme() async => setDarkMode(!isDark);

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode == 'sw' ? 'sw' : 'en';
    _locale = Locale(code);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, code);
    notifyListeners();
  }
}

class AppSettingsScope extends InheritedWidget {
  const AppSettingsScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final AppSettingsController controller;

  static AppSettingsController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope not found');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(AppSettingsScope oldWidget) =>
      controller != oldWidget.controller;
}
