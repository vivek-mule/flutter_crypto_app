import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_crypto_app/features/home/HomePage.dart' as home;
import 'features/shared/BottomNavPage.dart' as nav;
import 'features/auth/login/LoginPage.dart' as login;
import 'features/news/NewsPage.dart' as news;
import 'features/settings/SettingsPage.dart' as settings;
import 'features/auth/signup/SignupPage.dart' as signup;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  debugPrint("Working directory: ${Directory.current.path}");
  await dotenv.load(fileName: ".env");

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        primaryColor: Colors.deepPurple,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1E1E1E),
          border: OutlineInputBorder(),
          labelStyle: TextStyle(color: Colors.white70),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white70,
          displayColor: Colors.white,
        ),
      ),
      routes: {
        '/': (ctx) => const nav.MainScaffold(),
        '/settings': (ctx) => const settings.SettingsPage(),
        '/home': (ctx) => const home.HomePage(),
        '/login': (ctx) => login.LoginPage(),
        '/signup': (ctx) => signup.SignupPage(),
        '/news': (ctx) => const news.NewsPage(),
      },
    );
  }
}
