import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../categories/dm/task_dm.dart';

class CustomerTrackingScreen extends StatefulWidget {
  final int taskId;
  const CustomerTrackingScreen({super.key, required this.taskId});
  static const String routeName = 'customer_tracking';

  @override
  State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen> {
  final supabase = Supabase.instance.client;
  int _refreshKey = 0; // لإعادة بناء الـ ListView عند الريفريش

  String _mapStatusToArabic(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'جاري البحث عن طيار';
      case TaskStatus.accepted:
        return 'تم قبول الطلب، الطيار في طريقه';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع الطلب'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() {
            _refreshKey++;
          });
        },
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase
              .from('tasks')
              .stream(primaryKey: ['id'])
              .eq('id', widget.taskId),
          builder: (context, snapshot) {
            // لو البيانات لسه ما وصلت
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      'لم يتم العثور على الطلب أو تم حذفه.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              );
            }

            final task = TaskDM.fromSupabase(snapshot.data!.first);
            final status = task.status;
            final (icon, color) = _getIconAndColor(status);

            return ListView(
              key: ValueKey(_refreshKey),
              padding: const EdgeInsets.all(20),
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
                if (status == TaskStatus.pending)
                  const Text('الطلب جاري البحث عن طيار...'),
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
                    label: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildDriverInfo(String driverId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future:
          supabase
              .from('profiles')
              .select('full_name, phone_number')
              .eq('id', driverId)
              .maybeSingle(),
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

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color ?? Colors.teal.shade100,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(color: Colors.black87)),
      ),
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
        await supabase
            .from('tasks')
            .delete()
            .eq('id', taskId)
            .select(); // هيرجع الصف اللي تم حذفه لو عايز تتأكد
    print('✅ Task deleted successfully: $response');
  }
}
