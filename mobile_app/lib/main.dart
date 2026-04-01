import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
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