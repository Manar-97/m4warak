import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../categories/dm/task_dm.dart';
import '../driver/driver_tasks.dart';

class ActiveTaskScreen extends StatefulWidget {
  final TaskDM initialTask;
  const ActiveTaskScreen({super.key, required this.initialTask});
  static const String routeName = 'active_task';

  @override
  State<ActiveTaskScreen> createState() => _ActiveTaskScreenState();
}

class _ActiveTaskScreenState extends State<ActiveTaskScreen> {
  final _supabase = Supabase.instance.client;
  late TaskDM currentTask;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    currentTask = widget.initialTask;
    _listenToTaskUpdates();
  }

  // 🔴 Real-time updates
  void _listenToTaskUpdates() {
    _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('id', currentTask.id!)
        .listen((data) {
          if (data.isNotEmpty) {
            final updatedTask = TaskDM.fromSupabase(data.first);

            if (updatedTask.status == TaskStatus.cancelled) {
              _showCompletionDialog(
                title: 'تم إلغاء الطلب!',
                content: 'قام العميل بإلغاء هذا الطلب.',
                color: Colors.red,
              );
            }

            setState(() => currentTask = updatedTask);
          }
        });
  }

  // 🔴 Update status
  Future<void> _updateTaskStatus(TaskStatus newStatus) async {
    setState(() => _isLoading = true);

    try {
      await _supabase
          .from('tasks')
          .update({'status': newStatus.name})
          .eq('id', currentTask.id!);

      setState(() {
        currentTask = TaskDM(
          id: currentTask.id,
          customerId: currentTask.customerId,
          driverId: currentTask.driverId,
          taskType: currentTask.taskType,
          taskDetails: currentTask.taskDetails,
          pickupAddress: currentTask.pickupAddress,
          pickupLat: currentTask.pickupLat,
          pickupLon: currentTask.pickupLon,
          deliveryAddress: currentTask.deliveryAddress,
          deliveryLat: currentTask.deliveryLat,
          deliveryLon: currentTask.deliveryLon,
          status: newStatus,
          createdAt: currentTask.createdAt,
          totalPrice: currentTask.totalPrice,
        );
      });

      if (newStatus == TaskStatus.delivered) {
        _showCompletionDialog(
          title: 'اكتمل الطلب!',
          content: 'تم تسليم الطلب بنجاح.',
          color: Colors.green,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في تحديث الحالة: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCompletionDialog({
    required String title,
    required String content,
    required Color color,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: Text(title, style: TextStyle(color: color)),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil(
                    (route) =>
                        route.settings.name == DriverTasksScreen.routeName,
                  );
                  if (!Navigator.of(context).canPop()) {
                    Navigator.pushReplacementNamed(
                      context,
                      DriverTasksScreen.routeName,
                    );
                  }
                },
                child: const Text('حسناً'),
              ),
            ],
          ),
    );
  }

  // 🗺️ Maps
  Future<void> _launchMaps(double lat, double lng) async {
    final uri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // 📞 Call client
  Future<void> _callClient() async {
    final data = await _fetchClientDetails(currentTask.customerId);
    final phone = data.split(';').last;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<String> _fetchClientDetails(String id) async {
    final res =
        await _supabase
            .from('profiles')
            .select('full_name, phone_number')
            .eq('id', id)
            .single();

    return '${res['full_name']};${res['phone_number']}';
  }

  @override
  Widget build(BuildContext context) {
    if (currentTask.status == TaskStatus.cancelled ||
        currentTask.status == TaskStatus.delivered) {
      return const Scaffold(
        body: Center(child: Text('هذه المهمة لم تعد نشطة')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('المهمة النشطة')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // 📌 Status card
  Widget _buildStatusCard() {
    final statusText =
        {
          TaskStatus.pending: 'جاري البحث عن مُشاوِر',
          TaskStatus.accepted: 'المشاوِر في الطريق',
          TaskStatus.delivered: 'تم تسليم الطلب',
          TaskStatus.cancelled: 'تم إلغاء الطلب',
        }[currentTask.status];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          statusText ?? 'جاري التحديث...',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // 🚦 Action buttons
  Widget _buildActionButtons() {
    late TaskStatus nextStatus;
    late String text;
    late Color color;

    switch (currentTask.status) {
      case TaskStatus.pending:
        nextStatus = TaskStatus.accepted;
        text = 'المشاوِر في الطريق';
        color = Colors.amber;
        break;
      case TaskStatus.accepted:
        nextStatus = TaskStatus.delivered;
        text = 'إنهاء المهمة';
        color = Colors.green;
        break;
      default:
        return const SizedBox.shrink(); // لا أزرار لحالات delivered أو cancelled
    }

    return ElevatedButton(
      onPressed: _isLoading ? null : () => _updateTaskStatus(nextStatus),
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child:
          _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(text),
    );
  }
}
