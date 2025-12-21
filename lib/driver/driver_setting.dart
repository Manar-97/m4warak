import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_wrapper.dart';

class DriverSettingScreen extends StatelessWidget {
  const DriverSettingScreen({super.key});
  static const String routeName = 'driversetting';

  void _signOut(BuildContext context) async {
    // تسجيل الخروج من Supabase
    await Supabase.instance.client.auth.signOut();
    // توجيه المستخدم إلى شاشة الدخول عبر AuthWrapper
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AuthWrapper.routeName, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Icon(
                Icons.vpn_key_outlined,
                color: Colors.indigo.shade800,
              ),
              title: const Text('تغيير كلمة المرور'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('صفحة تغيير كلمة المرور قريباً'),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.indigo.shade800),
              title: const Text('حول التطبيق'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('صفحة حول التطبيق قريباً')),
                );
              },
            ),
            const Divider(),
            // زر تسجيل الخروج (مكرر من Profile screen لكن قد يحتاجه المستخدم هنا)
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _signOut(context),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
