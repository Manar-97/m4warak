import 'package:flutter/material.dart';
import 'package:mshawer/customer/customer_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mshawer/widgets/category_card.dart';
import 'package:mshawer/new_task_request_screen.dart';
import 'categories/dm/task_dm.dart';
import 'driver/driver_tasks.dart'; // نحتاج للمسار عند تسجيل الخروج

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const String routeName = 'home';
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  String displayName = "مستخدم";
  String userRole = "client";
  bool _isUserDataLoading = true; // حالة لتحميل بيانات الاسم والدور

  late final List<Map<String, dynamic>> services;

  @override
  void initState() {
    super.initState();
    loadUserData();
    // تهيئة قائمة الخدمات
    services = [
      {
        'name': 'توصيل واستلام أوردر فوري',
        'code': 'delivery',
        'icon': Icons.flash_on,
        'color': Colors.red.shade700,
        'action':
            () =>
                _navigateToTaskRequest('توصيل واستلام أوردر فوري', 'delivery'),
      },
      {
        'name': 'توصيل وشراء جميع طلبات المنزل',
        'code': 'delivery',
        'icon': Icons.shopping_bag,
        'color': Colors.green.shade700,
        'action':
            () => _navigateToTaskRequest(
              'توصيل وشراء جميع طلبات المنزل',
              'delivery',
            ),
      },
      {
        'name': 'حجز تذاكر قطار',
        'code': 'ticketing',
        'icon': Icons.train,
        'color': Colors.blue.shade700,
        'action': () => _navigateToTaskRequest('حجز تذاكر قطار', 'ticketing'),
      },
      {
        'name': 'حجز كشف الدكتور في نجح حمادي',
        'code': 'health',
        'icon': Icons.medical_services,
        'color': Colors.purple.shade700,
        'action':
            () => _navigateToTaskRequest(
              'حجز كشف الدكتور في نجح حمادي',
              'health',
            ),
      },
      {
        'name': 'روشتة علاجك لحد بيتك',
        'code': 'health',
        'icon': Icons.local_pharmacy,
        'color': Colors.orange.shade700,
        'action':
            () => _navigateToTaskRequest('روشتة علاجك لحد بيتك', 'health'),
      },
      {
        'name': 'توصيل الأبناء للمدرسة او الدرس او تمرين',
        'code': 'escort',
        'icon': Icons.school,
        'color': Colors.teal.shade700,
        'action':
            () => _navigateToTaskRequest(
              'توصيل الأبناء للمدرسة او الدرس او تمرين',
              'escort',
            ),
      },
      {
        'name': 'طلب مشوار بالسيارة',
        'code': 'custom',
        'icon': Icons.drive_eta,
        'color': Colors.teal.shade400,
        'action': () => _navigateToTaskRequest('طلب مشوار بالسيارة', 'custom'),
      },
      // {
      //   'name': 'سجل الطلبات',
      //   'code': 'custom',
      //   'icon': Icons.history,
      //   'color': Colors.grey.shade600,
      //   'action': () => _showComingSoon('سجل الطلبات'),
      // },
    ];
  }

  // دالة مضافة: للتحقق من وجود طلب نشط للعميل الحالي
  Future<int?> _checkForActiveTask(String userId, SupabaseClient client) async {
    try {
      final response =
          await client
              .from('tasks')
              .select('id')
              .eq('customer_id', userId)
              .inFilter('status', [
                TaskStatus.pending.name,
                TaskStatus.accepted.name,
              ])
              .limit(1)
              .maybeSingle();

      return response?['id'];
    } catch (e) {
      debugPrint('Error checking active task: $e');
      return null;
    }
  }

  void _navigateToTaskRequest(String serviceName, String serviceCode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NewTaskRequestScreen(
              serviceName: serviceName,
              serviceCode: serviceCode,
            ),
      ),
    );
  }

  void _showComingSoon(String serviceName) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('خدمة $serviceName قريباً!')));
  }

  Future<void> loadUserData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final response =
            await _supabase
                .from('profiles')
                .select('full_name, role')
                .eq('id', user.id)
                .single();

        setState(() {
          displayName = response['full_name'] as String? ?? "عميل";
          userRole = response['role'] as String? ?? "client";
          _isUserDataLoading = false;
        });

        // إذا قام المستخدم بالتحايل أو تم تسجيله بالخطأ كـ 'driver' وتم توجيهه هنا،
        // يجب إعادته لشاشة السائق
        if (userRole == 'driver' && mounted) {
          Navigator.of(context).pushReplacementNamed(
            DriverTasksScreen.routeName, // يجب التأكد من استيرادها لاحقاً
          );
        }
      } on PostgrestException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في جلب بيانات المستخدم: ${e.message}')),
          );
          setState(() {
            _isUserDataLoading = false;
          });
        }
      } catch (e) {
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

  // ويدجت شريط التطبيق
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'العميل',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, CustomerNotificationsScreen.routeName);
          },
          icon: Icon(Icons.notifications),
        ),
      ],
    );
  }

  // ويدجت محتوى الشاشة (قائمة الخدمات)
  Widget _buildServiceList() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أهلاً بك، $displayName 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                textDirection: TextDirection.rtl,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      userRole == 'driver'
                          ? Colors.blue.shade100
                          : Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  getRoleText(),
                  style: TextStyle(
                    color:
                        userRole == 'driver'
                            ? Colors.blue.shade800
                            : Colors.teal.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            onChanged: (value) {},
            decoration: InputDecoration(
              hintText: 'إيه المشوار اللي محتاج تخلصه دلوقتي؟',
              prefixIcon: const Icon(Icons.search, color: Colors.teal),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 20),
          const Text(
            'الخدمات المطلوبة',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 10),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
            children:
                services.map((service) {
                  return CategoryCard(
                    onPressed: service['action'] as VoidCallback,
                    icon: service['icon'] as IconData,
                    iconColor: service['color'] as Color,
                    text: service['name'] as String,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null || _isUserDataLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<int?>(
      future: _checkForActiveTask(currentUser.id, _supabase),
      builder: (context, snapshot) {
        int? activeTaskId = snapshot.data;
        return Scaffold(
          appBar: _buildAppBar(),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // if (activeTaskId != null)
                // InkWell(
                //   onTap: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder:
                //             (context) =>
                //                 CustomerTrackingScreen(taskId: activeTaskId),
                //       ),
                //     );
                //   },
                //   child: Container(
                //     padding: const EdgeInsets.all(12),
                //     margin: const EdgeInsets.only(bottom: 16),
                //     decoration: BoxDecoration(
                //       color: Colors.yellow.shade700,
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //       children: const [
                //         Text(
                //           'لديك طلب شغّال! اضغط هنا للتتبع',
                //           style: TextStyle(
                //             fontWeight: FontWeight.bold,
                //             color: Colors.white,
                //           ),
                //         ),
                //         Icon(Icons.arrow_forward_ios, color: Colors.white),
                //       ],
                //     ),
                //   ),
                // ),
                Expanded(child: _buildServiceList()),
              ],
            ),
          ),
        );
      },
    );
  }
}
