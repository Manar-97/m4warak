import 'package:flutter/material.dart';
import 'package:mshawer/main_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../driver/driver_tasks.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const String routeName = "login";

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.right),
          backgroundColor: color,
        ),
      );
    }
  }

  // 1. دالة التوجيه بناءً على الدور
  void _redirectUser(String role) {
    if (!mounted) return;
    if (role == 'driver') {
      Navigator.of(context).pushReplacementNamed(DriverTasksScreen.routeName);
    } else if (role == 'client') {
      // التوجيه لشاشة العميل
      Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
    } else {
      // دور غير معروف أو غير موجود، نعود لشاشة الدخول
      _showSnackBar('خطأ: دور مستخدم غير معروف.', color: Colors.orange);
      setState(() => _isLoading = false);
    }
  }

  // 2. جلب الدور بعد تسجيل الدخول
  Future<void> _fetchAndRedirectUser(String userId) async {
    try {
      final response =
          await _supabase
              .from('profiles')
              .select('role')
              .eq('id', userId)
              .single();

      final role = response['role'] as String?;
      if (role != null) {
        _redirectUser(role);
      } else {
        _showSnackBar(
          'خطأ: لم يتم العثور على دور المستخدم في ملفه الشخصي.',
          color: Colors.orange,
        );
      }
    } catch (e) {
      _showSnackBar(
        'خطأ في جلب الملف الشخصي: ${e.toString()}',
        color: Colors.orange,
      );
    }
  }

  // 3. دالة تسجيل الدخول الرئيسية
  Future<void> signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("الرجاء إدخال البريد الإلكتروني وكلمة المرور.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = response.user;
      if (user != null) {
        await _fetchAndRedirectUser(user.id);
        // سيتم إيقاف التحميل في _redirectUser
      }
    } on AuthException catch (e) {
      _showSnackBar("خطأ في المصادقة: ${e.message}");
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      _showSnackBar("حدث خطأ غير متوقع: ${e.toString()}");
      if (mounted) setState(() => _isLoading = false);
    }
    // لا نضع finally هنا، لأن التوجيه سيحدث داخل try
    if (mounted && _isLoading) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'تسجيل الدخول',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                //  <--- افتراضي أن لديك صورة شعار
                const SizedBox(height: 25),
                // EMAIL FIELD
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "البريد الإلكتروني",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 15),
                // PASSWORD FIELD
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: "كلمة المرور",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            "دخول",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("ليس لديك حساب؟ "),
                    GestureDetector(
                      child: const Text(
                        "سجل الآن",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      onTap: () {
                        Navigator.pushReplacementNamed(
                          context,
                          SignUpScreen.routeName,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
