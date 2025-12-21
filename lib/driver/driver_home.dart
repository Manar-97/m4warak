import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/category_card.dart';
import 'accepted_task.dart';
import 'driver_rating.dart';
import 'driver_tasks.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});
  static const String routeName = 'driverhome';

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final _supabase = Supabase.instance.client;

  String displayName = "طيار";
  String userRole = "driver";
  bool _isUserDataLoading = true;
  String driverId = "";

  late final List<Map<String, dynamic>> services;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      driverId = user.id; // حفظ driverId للاستخدام في الشاشة
      try {
        final response =
            await _supabase
                .from('profiles')
                .select('full_name, role')
                .eq('id', user.id)
                .single();

        setState(() {
          displayName = response['full_name'] as String? ?? "طيار";
          userRole = response['role'] as String? ?? "driver";
          _isUserDataLoading = false;

          // تهيئة قائمة الخدمات بعد معرفة driverId
          services = [
            {
              'name': 'المهام المتاحة',
              'icon': Icons.task_alt,
              'color': Colors.blue.shade700,
              'action': () {
                Navigator.pushNamed(context, DriverTasksScreen.routeName);
              },
            },
            {
              'name': 'مهامي الحالية',
              'icon': Icons.history_toggle_off,
              'color': Colors.green.shade700,
              'action': () {
                Navigator.pushNamed(context, AcceptedTasksScreen.routeName);
              },
            },
            {
              'name': 'تقييماتي',
              'icon': Icons.star,
              'color': Colors.yellow[700],
              'action': () {
                Navigator.pushNamed(
                  context,
                  DriverRatingsScreen.routeName,
                  arguments: driverId, // تمرير driverId للشاشة
                );
              },
            },
          ];
        });
      } on PostgrestException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في جلب بيانات المستخدم: ${e.message}')),
          );
          setState(() {
            _isUserDataLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isUserDataLoading = false;
          });
        }
      }
    }
  }

  String getRoleText() {
    return userRole == 'driver' ? 'طيار (سائق)' : 'عميل';
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'الطيار',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: Colors.indigo.shade800,
      foregroundColor: Colors.white,
    );
  }

  Widget _buildServiceList() {
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.9,
      children:
          services.map((service) {
            return CategoryCard(
              onPressed: service['action'] as VoidCallback,
              icon: service['icon'] as IconData,
              iconColor: service['color'] as Color,
              text: service['name'] as String,
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isUserDataLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'أهلاً بك، $displayName 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
          ),
          Expanded(child: _buildServiceList()),
        ],
      ),
    );
  }
}
