import 'package:clima_app/screen/home_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ClimaApp());
}


class ClimaApp extends StatelessWidget {
  const ClimaApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}