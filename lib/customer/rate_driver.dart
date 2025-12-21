import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RateDriverScreen extends StatefulWidget {
  static const String routeName = 'driver_rate';
  const RateDriverScreen({super.key, required this.taskId});

  final int taskId;

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  double rating = 1;
  final TextEditingController notesController = TextEditingController();
  bool isLoading = false; // حالة تحميل

  Future<void> submitRating() async {
    final supabase = Supabase.instance.client;

    if (rating < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('من فضلك اختر تقييم')));
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1️⃣ جلب driver_id من المهمة
      final taskResponse =
          await supabase
              .from('tasks')
              .select('driver_id')
              .eq('id', widget.taskId)
              .single();

      final driverId = taskResponse['driver_id'] as String?;
      if (driverId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد سائق مرتبط بالمهمة')),
        );
        setState(() => isLoading = false);
        return;
      }

      // 2️⃣ إضافة التقييم
      await supabase.from('driver_ratings').insert({
        'task_id': widget.taskId,
        'customer_id': supabase.auth.currentUser!.id,
        'driver_id': driverId,
        'rating': rating.toInt(),
        'notes': notesController.text,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 3️⃣ تحديث حالة المهمة
      await supabase
          .from('tasks')
          .update({'status': 'delivered'})
          .eq('id', widget.taskId);

      // 4️⃣ إرسال إشعار للسائق
      await supabase.from('notifications').insert({
        'user_id': driverId,
        'title': 'تم تقييمك ⭐',
        'body':
            'لقد حصلت على تقييم ${rating.toInt()} نجوم من العميل.\nملاحظات: ${notesController.text.isEmpty ? "لا توجد" : notesController.text}',
        'read': false,
        'task_id': widget.taskId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 5️⃣ رسالة نجاح وإغلاق الشاشة
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال التقييم بنجاح ✅'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(
          const Duration(seconds: 2),
          () => Navigator.pop(context, true),
        );
      }
    } catch (e) {
      print('Error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء إرسال التقييم'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقييم الطيار'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'قيّم الطيار',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Slider(
              value: rating,
              onChanged: (v) => setState(() => rating = v),
              min: 1,
              max: 5,
              divisions: 4,
              label: rating.toString(),
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات إضافية',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 30,
                ),
              ),
              child:
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'إرسال التقييم',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
