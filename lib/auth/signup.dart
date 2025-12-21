import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  static const String routeName = "signup";

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // تأكدنا من أن الدور يتوافق مع 'client' أو 'driver'
  String userRole = "client";
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
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

  Future<void> signUp() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      _showSnackBar("الرجاء ملء جميع الحقول المطلوبة.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final fullName = _nameController.text.trim();
      final phoneNumber = _phoneController.text.trim();

      // 1. التسجيل في Supabase Auth
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        // إذا فشلت عملية المصادقة لأي سبب غير متوقع
        _showSnackBar("فشل في التسجيل. الرجاء التحقق من البيانات.");
        return;
      }

      // 2. إدراج التفاصيل في جدول profiles
      await _supabase.from('profiles').insert({
        'id': user.id,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'role': userRole, // حفظ الدور المختار
      });

      // 3. إذا كان السائق، قم بإضافة تفاصيل السائق
      if (userRole == 'driver') {
        await _supabase.from('driver_details').insert({
          'profile_id': user.id,
          'is_available': false,
          // يمكن إضافة تفاصيل أخرى للسائق هنا (مثل نوع المركبة)
        });
      }

      // 4. عرض رسالة نجاح واضحة والتوجيه لشاشة الدخول
      _showSnackBar(
        "تم إنشاء الحساب بنجاح! يمكنك الآن تسجيل الدخول.",
        color: Colors.green,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    } on AuthException catch (e) {
      _showSnackBar("خطأ في المصادقة: ${e.message}");
    } on PostgrestException catch (e) {
      _showSnackBar("خطأ في البيانات (تكرار رقم الهاتف/بريد): ${e.message}");
    } catch (e) {
      _showSnackBar("حدث خطأ غير متوقع: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'إنشاء حساب جديد',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                //
                const SizedBox(height: 20),

                // NAME
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "الاسم الكامل",
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 15),
                // PHONE
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "رقم الهاتف",
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 15),
                // EMAIL
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "البريد الإلكتروني",
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 15),
                // PASSWORD
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: "كلمة المرور",
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 20),

                // USER TYPE DROPDOWN (Role Selection)
                DropdownButtonFormField<String>(
                  value: userRole,
                  items: const [
                    DropdownMenuItem(
                      value: "client",
                      child: Text("عميل (طالب خدمة)"),
                    ),
                    DropdownMenuItem(
                      value: "driver",
                      child: Text("مُشاوِر (مقدم خدمة)"),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      userRole = val!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "نوع الحساب",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  alignment: Alignment.centerRight,
                ),
                const SizedBox(height: 25),
                // SIGN UP BUTTON
                ElevatedButton(
                  onPressed: _isLoading ? null : signUp,
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
                            "تسجيل",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("لديك حساب بالفعل؟ "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                          context,
                          LoginScreen.routeName,
                        );
                      },
                      child: const Text(
                        "سجل دخول",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
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
