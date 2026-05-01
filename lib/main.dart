import 'package:flutter/material.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/welcome_screen.dart';
// import 'features/auth/login_screen.dart';
// import 'features/home/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RESIK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Montserrat',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        // '/login': (context) => const LoginScreen(),
        // '/home': (context) => const HomeScreen(),
      },
    );
  }
}