import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../categories/dm/task_dm.dart';
import '../tasks/customer_tracking.dart';

class CustomerTasksScreen extends StatefulWidget {
  const CustomerTasksScreen({super.key});

  @override
  State<CustomerTasksScreen> createState() => _CustomerTasksScreenState();
}

class _CustomerTasksScreenState extends State<CustomerTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;
  int _refreshKey = 0;

  final activeStatuses = [TaskStatus.pending.name, TaskStatus.accepted.name];

  final finishedStatuses = [
    TaskStatus.delivered.name,
    TaskStatus.completed.name,
  ];

  final cancelledStatuses = [TaskStatus.cancelled.name];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الطلبات'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'جارية'),
            Tab(text: 'مكتملة'),
            Tab(text: 'ملغية'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTasks(userId, [TaskStatus.pending, TaskStatus.accepted]),
          _buildTasks(userId, [TaskStatus.delivered, TaskStatus.completed]),
          _buildTasks(userId, [TaskStatus.cancelled]),
        ],
      ),
    );
  }

  Widget _buildTasks(String userId, List<TaskStatus> allowedStatuses) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('tasks')
          .stream(primaryKey: ['id'])
          .eq('customer_id', userId)
          .order('created_at'),
      builder: (context, snapshot) {
        // 🔹 أول ما تفتح الشاشة: CircularProgressIndicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 🔹 تحويل البيانات + فلترة حسب الحالة
        final tasks =
            snapshot.data
                ?.map((e) => TaskDM.fromSupabase(e))
                .where((task) => allowedStatuses.contains(task.status))
                .toList() ??
            [];

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 800));
            setState(() {
              _refreshKey++;
            });
          },
          child:
              tasks.isEmpty
                  ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 300),
                      Center(child: Text('لا يوجد طلبات')),
                    ],
                  )
                  : ListView.builder(
                    key: ValueKey(_refreshKey),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.local_shipping),
                          title: Text(task.taskType),
                          subtitle: Text(task.pickupAddress),
                          trailing: _statusChip(task.status),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => CustomerTrackingScreen(
                                      taskId: task.id!,
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
        );
      },
    );
  }

  Widget _statusChip(TaskStatus status) {
    return Chip(
      label: Text(
        mapStatusToArabic(status),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: statusColor(status),
    );
  }

  String mapStatusToArabic(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'جاري البحث عن طيار';
      case TaskStatus.accepted:
        return 'تم قبول الطلب';
      case TaskStatus.delivered:
        return 'تم التسليم';
      case TaskStatus.completed:
        return 'تم إنهاء الطلب';
      case TaskStatus.cancelled:
        return 'تم إلغاء الطلب';
    }
  }

  Color statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.grey;
      case TaskStatus.accepted:
        return Colors.orange;
      case TaskStatus.delivered:
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }
}
