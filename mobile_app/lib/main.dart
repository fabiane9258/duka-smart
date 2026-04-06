import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' deferred as sqfliteFfiWeb;
import 'screens/home_screen.dart';

void main() async {
  if (kIsWeb) {
    databaseFactory = sqfliteFfiWeb.databaseFactoryFfiWeb;
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const DukaSmartApp());
}

class DukaSmartApp extends StatelessWidget {
  const DukaSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "DukaSmart",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomeScreen(),
    );
  }
}