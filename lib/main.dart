import 'package:flutter/material.dart';
import 'package:memoire/Compane/HoneCompane.dart';
import 'package:memoire/Homepage/Home1.dart';
import 'package:memoire/Tabbar.dart';
import 'package:memoire/auth/GetstLogin.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // ضمان تهيئة Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // التحقق من حالة تسجيل الدخول
  final prefs = await SharedPreferences.getInstance();
  final userType = prefs.getString('userType');
  final isLoggedIn = userType != null;

  runApp(MyApp(isLoggedIn: isLoggedIn, userType: userType));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? userType;

  const MyApp({super.key, required this.isLoggedIn, this.userType});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF36305E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF36305E),
          primary: const Color(0xFF36305E),
          secondary: const Color(0xFF8A70D6),
        ),
      ),
      home: _getHomeScreen(),
      routes: {
        '/login': (context) => const Login(),
        '/company_home': (context) => const Honecompane(),
        '/jobseeker_home': (context) => const Tabbar(),
      },
    );
  }

  // دالة لتحديد الشاشة الرئيسية بناءً على حالة تسجيل الدخول
  Widget _getHomeScreen() {
    // إذا كان المستخدم مسجل دخول
    if (isLoggedIn) {
      // التحقق من نوع المستخدم
      if (userType == 'company') {
        print('Starting app as logged in company');
        return const Honecompane();
      } else if (userType == 'jobseeker') {
        print('Starting app as logged in jobseeker');
        return const Tabbar();
      }
    }

    // إذا لم يكن مسجل دخول أو كان هناك خطأ في نوع المستخدم
    // نبدأ بشاشة الترحيب
    print('Starting app with welcome screen');
    return const Home1();
  }
}
