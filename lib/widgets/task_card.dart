import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../categories/dm/task_dm.dart';

class TaskCard extends StatelessWidget {
  final TaskDM task;
  final String distance;
  final VoidCallback onAccept;
  final VoidCallback? onReject; // ✨
  final bool showFinishButton;

  const TaskCard({
    super.key,
    required this.task,
    required this.distance,
    required this.onAccept,
    this.onReject, // ✨
    this.showFinishButton = false,
  });

  Future<void> _finishTask(BuildContext context, TaskDM task) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase
          .from('tasks')
          .update({'status': 'delivered'})
          .eq('id', task.id!);

      await supabase.from('notifications').insert({
        'user_id': task.customerId,
        'title': 'تم توصيل طلبك 🚀',
        'body': 'تم توصيل طلبك بنجاح! يمكنك تقييم الطيار الآن.',
        'task_id': task.id,
        'read': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنهاء المهمة وإرسال الإشعار للعميل ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء إنهاء المهمة أو إرسال الإشعار'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error finishing task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    task.taskType,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.indigo.shade600,
                ),
                Text(
                  'المسافة: $distance',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'التفاصيل:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              task.taskDetails,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(),
            _buildLocationRow(
              Icons.location_on,
              'نقطة الالتقاط:',
              task.pickupAddress,
            ),
            _buildLocationRow(
              Icons.flag,
              'وجهة التسليم:',
              task.deliveryAddress,
            ),
            const SizedBox(height: 10),
            // ✨ أزرار المهمة
            showFinishButton
                ? ElevatedButton.icon(
                  onPressed: () => _finishTask(context, task),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'إنهاء المهمة',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                  ),
                )
                : Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(
                          Icons.delivery_dining,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'قبول المهمة',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        label: const Text(
                          'رفض المهمة',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String address) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 5),
        Expanded(
          child: Text('$label $address', overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
