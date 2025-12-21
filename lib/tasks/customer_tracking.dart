import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../categories/dm/task_dm.dart';

class CustomerTrackingScreen extends StatelessWidget {
  final int taskId;
  const CustomerTrackingScreen({super.key, required this.taskId});
  static const String routeName = 'customer_tracking';

  String _mapStatusToArabic(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'جاري البحث عن مُشاوِر';
      case TaskStatus.accepted:
        return 'تم قبول الطلب، المشاوِر في طريقه';
      case TaskStatus.delivered:
        return 'تم تسليم الطلب بنجاح';
      case TaskStatus.cancelled:
        return 'تم إلغاء الطلب';
      case TaskStatus.completed:
        return 'تم إنهاء الطلب';
    }
  }

  (IconData, Color) _getIconAndColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return (Icons.search, Colors.grey);
      case TaskStatus.accepted:
        return (Icons.directions_bike, Colors.amber);
      case TaskStatus.delivered:
        return (Icons.check_box, Colors.green);
      case TaskStatus.cancelled:
        return (Icons.cancel, Colors.red);
      case TaskStatus.completed:
        return (Icons.done_all, Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع الطلب'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('tasks')
            .stream(primaryKey: ['id'])
            .eq('id', taskId),
        builder: (context, snapshot) {
          // لو مفيش بيانات نهائي
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'لم يتم العثور على الطلب أو تم حذفه.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }
          // جلب بيانات الطلب
          final task = TaskDM.fromSupabase(snapshot.data!.first);
          final status = task.status;
          final (icon, color) = _getIconAndColor(status);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(icon, size: 60, color: color),
                        const SizedBox(height: 15),
                        const Text('حالة طلبك الحالي:'),
                        Text(
                          _mapStatusToArabic(status),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // لو الطلب مازال pending
                if (status == TaskStatus.pending)
                  const Text('الطلب جاري البحث عن مُشاوِر...'),

                // لو في سائق معين
                if (status != TaskStatus.pending && task.driverId != null)
                  _buildDriverInfo(task.driverId!),

                const SizedBox(height: 25),

                _buildSummaryCard(task),

                const SizedBox(height: 20),

                if (status != TaskStatus.delivered &&
                    status != TaskStatus.cancelled)
                  ElevatedButton.icon(
                    onPressed:
                        () => _showCancelDialog(context, task.id!, status),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Text(
                        'إلغاء الطلب',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDriverInfo(String driverId) {
    final supabase = Supabase.instance.client;

    return FutureBuilder<Map<String, dynamic>>(
      future:
          supabase
              .from('profiles')
              .select('full_name, phone_number')
              .eq('id', driverId)
              .single(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data!;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(data['full_name'] ?? 'غير معروف'),
            subtitle: Text(data['phone_number'] ?? 'غير متوفر'),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(TaskDM task) {
    return Card(
      child: Column(
        children: [
          _buildInfoRow('الخدمة', task.taskType, Icons.category),
          _buildInfoRow('الالتقاط', task.pickupAddress, Icons.location_on),
          _buildInfoRow('التسليم', task.deliveryAddress, Icons.flag),
          _buildInfoRow('التفاصيل', task.taskDetails, Icons.notes),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }

  void _showCancelDialog(BuildContext context, int taskId, TaskStatus status) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('تأكيد الإلغاء'),
            content: const Text('هل أنت متأكد من إلغاء الطلب؟'),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('تراجع'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteTask(taskId);
                },
                child: const Text('إلغاء', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteTask(int taskId) async {
    final response =
        await Supabase.instance.client
            .from('tasks')
            .delete()
            .eq('id', taskId)
            .select(); // هيرجع الصف اللي تم حذفه لو عايز تتأكد

    print('✅ Task deleted successfully: $response');
  }

  // Future<void> _cancelTask(BuildContext context, int taskId) async {
  //   final response =
  //       await Supabase.instance.client
  //           .from('tasks')
  //           .update({'status': TaskStatus.cancelled.name})
  //           .eq('id', taskId)
  //           .select()
  //           .maybeSingle(); // هيرجع الصف المحدث
  //
  //   if (response != null) {
  //     print('✅ Task cancelled successfully: $response');
  //   } else {
  //     print('⚠️ Task cancelled, but no data returned');
  //   }
  //
  //   if (context.mounted) {
  //     Navigator.of(context).popUntil((route) => route.isFirst);
  //   }
  // }
}
