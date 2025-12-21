import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_wrapper.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});
  static const String routeName = 'driverprofile';

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        // إذا لم يكن هناك مستخدم، قم بتسجيل الخروج وتوجيهه لشاشة الدخول
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AuthWrapper.routeName, (route) => false);
      }
      return;
    }

    try {
      // **جلب جميع بيانات الملف الشخصي من جدول profiles**
      final response =
          await _supabase
              .from('profiles')
              .select('*')
              .eq('id', user.id)
              .single();

      setState(() {
        userProfile = response;
        _isLoading = false;
      });
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب الملف الشخصي: ${e.message}')),
        );
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AuthWrapper.routeName, (route) => false);
    }
  }

  String getRoleText(String role) {
    if (role == 'driver') return 'طيار (سائق)';
    if (role == 'client') return 'عميل (طالب خدمة)';
    return role;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: Colors.indigo.shade800),
              )
              : userProfile == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('فشل في تحميل بيانات المستخدم.'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _loadProfile,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.person, size: 60),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          userProfile!['full_name'] ?? 'لا يوجد اسم',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // عرض الدور
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                userProfile!['role'] == 'driver'
                                    ? Colors.blue.shade100
                                    : Colors.indigo.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            getRoleText(userProfile!['role'] ?? 'غير معروف'),
                            style: TextStyle(
                              color:
                                  userProfile!['role'] == 'driver'
                                      ? Colors.blue.shade800
                                      : Colors.indigo.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.phone, color: Colors.indigo.shade800),
                    title: const Text('رقم الهاتف'),
                    subtitle: Text(userProfile!['phone'] ?? 'لم يحدد'),
                  ),
                  ListTile(
                    leading: Icon(Icons.email, color: Colors.indigo.shade800),
                    title: const Text('البريد الإلكتروني'),
                    subtitle: Text(
                      _supabase.auth.currentUser?.email ?? 'غير متوفر',
                    ),
                  ),
                  const Divider(),
                  // زر تسجيل الخروج
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: ElevatedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
