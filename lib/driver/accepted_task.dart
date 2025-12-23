import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../categories/dm/task_dm.dart';
import '../widgets/task_card.dart';

class AcceptedTasksScreen extends StatefulWidget {
  static const String routeName = "acceptedTask";
  const AcceptedTasksScreen({super.key});

  @override
  State<AcceptedTasksScreen> createState() => _AcceptedTasksScreenState();
}

class _AcceptedTasksScreenState extends State<AcceptedTasksScreen> {
  final supabase = Supabase.instance.client;
  List<TaskDM> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _subscribeTasks();
  }

  void _subscribeTasks() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final stream = supabase.from('tasks').stream(primaryKey: ['id']);
    stream.listen((rows) {
      final list = (rows as List).cast<Map<String, dynamic>>();
      final myTasks =
          list
              .where(
                (t) => t['driver_id'] == user.id && t['status'] == 'accepted',
              )
              .map(TaskDM.fromSupabase)
              .toList();

      if (mounted) {
        setState(() {
          _tasks = myTasks;
          _loading = false;
        });
      }
    });
  }

  String _distance(TaskDM task) {
    if (task.pickupLat == 0 || task.deliveryLat == 0) return 'غير متاح';
    final m = Geolocator.distanceBetween(
      task.pickupLat,
      task.pickupLon,
      task.deliveryLat,
      task.deliveryLon,
    );
    return '${(m / 1000).toStringAsFixed(1)} كم';
  }

  Future<void> _finishTask(TaskDM task) async {
    try {
      // تحديث المهمة لـ delivered
      await supabase
          .from('tasks')
          .update({'status': 'delivered'})
          .eq('id', task.id!);

      // إرسال إشعار للعميل
      await supabase.from('notifications').insert({
        'user_id': task.customerId,
        'title': 'تم توصيل طلبك 🚀',
        'body': 'تم توصيل طلبك بنجاح! يمكنك تقييم الطيار الآن.',
        'task_id': task.id,
        'read': false,
      });

      // إزالة المهمة من القائمة فوراً
      if (mounted) {
        setState(() {
          _tasks.removeWhere((t) => t.id == task.id);
        });
      }
    } catch (e) {
      print('Error finishing task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء إنهاء المهمة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('الرجاء تسجيل الدخول')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مهامي الحالية',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo.shade800,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _tasks.isEmpty
              ? const Center(child: Text('لا توجد مهام حالياً'))
              : RefreshIndicator(
                onRefresh: () async {
                  // لتحديث المهام، نعيد استدعاء الاشتراك
                  setState(() {
                    _loading = true;
                  });
                  await Future.delayed(const Duration(milliseconds: 500));
                  _subscribeTasks();
                }, // هذا سيجلب المهام مرة أخرى
                child: ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, i) {
                    final task = _tasks[i];
                    return TaskCard(
                      task: task,
                      distance: _distance(task),
                      showFinishButton: true,
                      onAccept: () => _finishTask(task),
                    );
                  },
                ),
              ),
    );
  }
}
