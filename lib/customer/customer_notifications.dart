import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rate_driver.dart';

class CustomerNotificationsScreen extends StatelessWidget {
  const CustomerNotificationsScreen({super.key});
  static const String routeName = 'customer_notifications';

  Future<Map<String, dynamic>?> _getCustomerName(int taskId) async {
    // جلب بيانات المهمة
    final task =
        await Supabase.instance.client
            .from('tasks')
            .select('customer_id')
            .eq('id', taskId)
            .maybeSingle();

    if (task == null) return null;

    final customerId = task['customer_id'];

    // جلب اسم العميل من جدول profiles
    final profile =
        await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', customerId)
            .maybeSingle();

    return profile;
  }

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
        title: const Text('الإشعارات', style: TextStyle(color: Colors.white)),
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
              final taskId = notif['task_id'];

              return FutureBuilder<Map<String, dynamic>?>(
                future:
                    taskId != null
                        ? _getCustomerName(taskId)
                        : Future.value(null),
                builder: (context, snapshotName) {
                  final customerName =
                      snapshotName.data?['full_name'] ?? 'العميل';
                  return ListTile(
                    tileColor: isRead ? Colors.white : Colors.yellow.shade100,
                    title: Text('${notif['title'] ?? ''} - $customerName'),
                    subtitle: Text(notif['body'] ?? ''),
                    trailing: Icon(
                      isRead ? Icons.check_circle : Icons.notifications_active,
                      color: isRead ? Colors.green : Colors.orange,
                    ),
                    onTap: () async {
                      await Supabase.instance.client
                          .from('notifications')
                          .update({'read': true})
                          .eq('id', notif['id']);

                      if (taskId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => RateDriverScreen(taskId: taskId),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
