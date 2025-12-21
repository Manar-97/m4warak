import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../auth/auth_wrapper.dart';
import '../categories/dm/task_dm.dart';
import '../widgets/task_card.dart';

class DriverTasksScreen extends StatefulWidget {
  const DriverTasksScreen({super.key});
  static const String routeName = 'driver_tasks';

  @override
  State<DriverTasksScreen> createState() => _DriverTasksScreenState();
}

class _DriverTasksScreenState extends State<DriverTasksScreen> {
  final _supabase = Supabase.instance.client;

  List<TaskDM> _tasks = []; // هتحفظ المهام المؤقتة
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _subscribeTasks();
  }

  void _subscribeTasks() {
    final stream = _supabase.from('tasks').stream(primaryKey: ['id']);
    stream.listen((rows) {
      final data = (rows as List).cast<Map<String, dynamic>>();
      final availableTasks =
          data
              .where((t) => t['status'] == 'pending' && t['driver_id'] == null)
              .map(TaskDM.fromSupabase)
              .toList();
      if (mounted) {
        setState(() {
          _tasks = availableTasks;
          _loading = false;
        });
      }
    });
  }

  String _calculateDistance(TaskDM task) {
    if (task.pickupLat == 0 || task.deliveryLat == 0) return 'غير متاح';
    final meters = Geolocator.distanceBetween(
      task.pickupLat,
      task.pickupLon,
      task.deliveryLat,
      task.deliveryLon,
    );
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  Future<void> _acceptTask(TaskDM task) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showSnackBar('الرجاء تسجيل الدخول كسائق');
      return;
    }

    try {
      final response =
          await _supabase
              .from('tasks')
              .update({'status': 'accepted', 'driver_id': user.id})
              .eq('id', task.id!)
              .eq('status', 'pending')
              .select();

      if (response.isEmpty) {
        _showSnackBar('تم قبول المهمة من سائق آخر', color: Colors.orange);
        return;
      }

      // ✅ إزالة المهمة من القائمة فور قبولها
      if (mounted) {
        setState(() {
          _tasks.removeWhere((t) => t.id == task.id);
        });
      }

      _showSnackBar('تم قبول المهمة بنجاح 🚀', color: Colors.green);
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء قبول المهمة');
      print('Error accepting task: $e');
    }
  }

  void _showSnackBar(String msg, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.right),
        backgroundColor: color,
      ),
    );
  }

  void _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AuthWrapper.routeName, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المهام المتاحة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade800,
        centerTitle: true,
        actions: [
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _tasks.isEmpty
              ? const Center(
                child: Text(
                  'لا توجد مهام متاحة حالياً',
                  style: TextStyle(fontSize: 18),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return TaskCard(
                    task: task,
                    distance: _calculateDistance(task),
                    onAccept: () => _acceptTask(task),
                  );
                },
              ),
    );
  }
}
