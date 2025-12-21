import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main_screen.dart'; // مسار MainScreen
import 'login.dart'; // مسار LoginScreen

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  static const String routeName = "authwrapper";

  @override
  Widget build(BuildContext context) {
    // استخدام StreamBuilder للاستماع اللحظي لتغيرات المصادقة
    return StreamBuilder<AuthState>(
      // المصدر هو تدفق حالة المصادقة من Supabase
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // 1. حالة التحميل: انتظر حتى يتلقى StreamBuilder أول حالة
        if (snapshot.connectionState == ConnectionState.waiting) {
          // يمكن هنا إضافة شاشة ترحيب بسيطة أو ترك شاشة التحميل
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }
        final session = snapshot.data?.session;
        // 2. حالة تسجيل الدخول: إذا كان هناك جلسة نشطة
        if (session != null) {
          // التوجيه مباشرة إلى الشاشة الرئيسية
          return const MainScreen();
        } else {
          // 3. حالة عدم تسجيل الدخول: التوجيه إلى شاشة الدخول
          return const LoginScreen();
        }
      },
    );
  }
}
