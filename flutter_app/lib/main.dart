import 'package:flutter/material.dart';
import 'views/phone_frame.dart';
import 'views/welcome.dart';

void main() => runApp(const CatalogApp());

class CatalogApp extends StatelessWidget {
  const CatalogApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Restaurant catalog',
    debugShowCheckedModeBanner: false,
    builder: (context, child) => PhoneFrame(child: child!),
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF245C42)),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: const CatalogPage(),
  );
}
