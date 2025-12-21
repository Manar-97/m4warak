import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rate_driver.dart';

class CustomerNotificationsScreen extends StatelessWidget {
  const CustomerNotificationsScreen({super.key});
  static const String routeName = 'customer_notifications';

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('الرجاء تسجيل الدخول')));
    }

    // Stream للإشعارات الخاصة بالعميل
    final notificationsStream = supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;

          if (notifications.isEmpty) {
            return const Center(child: Text('لا توجد إشعارات حالياً'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif['read'] as bool? ?? false;

              return ListTile(
                tileColor: isRead ? Colors.white : Colors.yellow.shade100,
                title: Text(notif['title'] ?? ''),
                subtitle: Text(notif['body'] ?? ''),
                trailing: Icon(
                  isRead ? Icons.check_circle : Icons.notifications_active,
                  color: isRead ? Colors.green : Colors.orange,
                ),
                onTap: () async {
                  // تحديث حالة الإشعار إلى مقروء
                  await supabase
                      .from('notifications')
                      .update({'read': true})
                      .eq('id', notif['id']);

                  // إذا هناك مهمة مرتبطة، فتح صفحة التقييم
                  final taskId = notif['task_id'];
                  if (taskId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RateDriverScreen(taskId: taskId),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
