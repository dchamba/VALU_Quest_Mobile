import 'package:flutter/material.dart';
import 'package:valu_quest/test.dart';
import 'package:valu_quest/view/bmi/bmi_calculator.dart';
import 'package:valu_quest/view/splash/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false,
      title: 'Valu Quest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
