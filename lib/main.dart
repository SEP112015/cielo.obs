import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'utils/app_colors.dart';

void main() {
  runApp(const CieloObsApp());
}

class CieloObsApp extends StatelessWidget {
  const CieloObsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cielo Obs',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.secondary,
          centerTitle: true,
        ),
        cardColor: AppColors.card,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}