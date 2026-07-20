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
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';
import 'features/admin/notification_list_screen_admin.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ INITIALIZE FIREBASE
  await Firebase.initializeApp();

  // ✅ SETUP FIREBASE MESSAGING
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // ✅ REQUEST PERMISSION NOTIFIKASI
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // ✅ GET FCM TOKEN
  String? fcmToken = await messaging.getToken();
  print('🔵 FCM Token: $fcmToken');

  // ✅ AUTO-UPDATE TOKEN JIKA USER SUDAH LOGIN
  if (fcmToken != null) {
    await _updateFcmTokenIfLoggedIn(fcmToken);
  }

  // ✅ LISTEN TOKEN REFRESH
  messaging.onTokenRefresh.listen((newToken) async {
    print('🔄 FCM Token refreshed: $newToken');
    await _updateFcmTokenIfLoggedIn(newToken);
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => StatistikProvider(),
      child: const MyApp(),
    ),
  );
} // ← tutup main()

// ✅ FUNCTION BARU: UPDATE TOKEN KE BACKEND
Future<void> _updateFcmTokenIfLoggedIn(String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!isLoggedIn) {
      print('⚠️ User belum login, skip update FCM token');
      return;
    }

    final userDataStr = prefs.getString('user_data');
    final userType = prefs.getString('user_type');

    if (userDataStr == null || userType == null) return;

    final userData = jsonDecode(userDataStr);
    int? userId;

    if (userType == 'masyarakat') {
      userId = userData['id_masyarakat'];
    } else if (userType == 'pns') {
      userId = userData['id_pns'];
    } else if (userType == 'petugas') {
      userId = userData['id_petugas'];
    }

    if (userId == null) return;

    final response = await http.post(
      Uri.parse(ApiConfig.saveFcmToken),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'tipe': userType,
        'fcm_token': token,
      }),
    );

    if (response.statusCode == 200) {
      print('✅ FCM Token berhasil diupdate ke backend!');
    }
  } catch (e) {
    print('❌ Error update FCM token: $e');
  }
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
        '/notification-admin': (context) => const NotificationListScreenAdmin(),
      },
    );
  }
}
