import 'package:flutter/material.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/login/login_screen.dart';
import 'features/auth/register/register_screen.dart';
import 'features/auth/forgot_password/forgot_password_screen.dart';
import 'features/auth/forgot_password/verify_otp_screen.dart';
import 'features/auth/forgot_password/reset_password_screen.dart';
import 'features/home/home_user_screen.dart';
import 'features/admin/home_admin_screen.dart';
import 'package:provider/provider.dart';
import 'providers/statistik_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
      navigatorKey: navigatorKey,
      title: 'RESIK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Montserrat'),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/register': (context) => const RegisterScreen(),

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
      },
    );
  }
}
