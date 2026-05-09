import 'package:flutter/material.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/login/login_screen.dart';
import 'features/auth/register/register_step1.dart';
import 'features/auth/register/register_step2.dart';
import 'features/auth/forgot_password/forgot_password_screen.dart';
import 'features/auth/forgot_password/verify_otp_screen.dart';
import 'features/auth/forgot_password/reset_password_screen.dart';
import 'features/home/home_user_screen.dart';
import 'features/admin/home_admin_screen.dart';
import 'package:provider/provider.dart';
import 'providers/statistik_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => StatistikProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RESIK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Montserrat'),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/register-step1': (context) => const RegisterStep1(),
        '/register-step2': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return RegisterStep2(
            nama: args['nama'] ?? '',
            gender: args['gender'],
            tglLahir: args['tglLahir'],
            alamat: args['alamat'] ?? '',
            job: args['job'],
            dinasId: args['dinasId'],
          );
        },
        '/verify-otp': (context) {
          final email = ModalRoute.of(context)!.settings.arguments as String;
          return VerifyOtpScreen(email: email);
        },
        '/reset-password': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ResetPasswordScreen(
            email: args['email'],
            token: args['token'],
          );
        },
        '/home-user': (context) => const HomeUserScreen(),
        '/home-admin': (context) => const HomeAdminScreen(),
        //'/scan': (context) => const ScanPage(),
        //'/penjemputan': (context) => const PenjemputanPage(),
      },
    );
  }
}
