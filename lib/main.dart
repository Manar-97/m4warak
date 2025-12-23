import 'package:flutter/material.dart';
import 'package:mshawer/auth/login.dart';
import 'package:mshawer/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/auth_wrapper.dart';
import 'auth/signup.dart';
import 'customer/customer_notifications.dart';
import 'driver/accepted_task.dart';
import 'driver/driver_home.dart';
import 'driver/driver_notification.dart';
import 'driver/driver_rating.dart';
import 'driver/driver_profile.dart';
import 'driver/main_driver_screen.dart';
import 'customer/rate_driver.dart';
import 'tasks/customer_tracking.dart';
import 'driver/driver_tasks.dart';
import 'home.dart';
import 'main_screen.dart';
import 'new_task_request_screen.dart';

const SUPABASE_URL = "https://fnnllyfgvrtoxkirhcmx.supabase.co";
const SUPABASE_ANON_KEY =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZubmxseWZndnJ0b3hraXJoY214Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyNTcwNzgsImV4cCI6MjA3OTgzMzA3OH0.YqK2TEaH-kuwfsKUvGqawA_CvR-IZEubEC3XnpjXKhg";

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // لضمان تهيئة Flutter أولاً
  await Supabase.initialize(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MASHWARK',
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      routes: {
        AuthWrapper.routeName: (_) => AuthWrapper(),
        LoginScreen.routeName: (_) => LoginScreen(),
        SignUpScreen.routeName: (_) => SignUpScreen(),
        MainScreen.routeName: (_) => const MainScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        MainDriverScreen.routeName: (_) => const MainDriverScreen(),
        DriverHomeScreen.routeName: (_) => const DriverHomeScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        DriverProfileScreen.routeName: (_) => const DriverProfileScreen(),
        NewTaskRequestScreen.routeName: (context) {
          return const NewTaskRequestScreen(
            serviceName: 'تجهيز الطلب',
            serviceCode: 'default',
          );
        },
        DriverTasksScreen.routeName: (context) => const DriverTasksScreen(),
        AcceptedTasksScreen.routeName: (context) => const AcceptedTasksScreen(),
        CustomerNotificationsScreen.routeName:
            (context) => const CustomerNotificationsScreen(),
        DriverNotificationsScreen.routeName:
            (context) => const DriverNotificationsScreen(),
      },
      // توفير onGenerateRoute لمعالجة المسارات التي تتطلب وسيطات
      onGenerateRoute: (settings) {
        // مسار تتبع الطلب للعميل
        if (settings.name == CustomerTrackingScreen.routeName) {
          final taskId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => CustomerTrackingScreen(taskId: taskId),
          );
        }
        // مسار تقييم الطيار
        if (settings.name == RateDriverScreen.routeName) {
          final taskId = settings.arguments as int; // لازم تبعت taskId هنا
          return MaterialPageRoute(
            builder: (context) => RateDriverScreen(taskId: taskId),
          );
        }
        // مسار تقييمات الطيار
        if (settings.name == DriverRatingsScreen.routeName) {
          final driverId = settings.arguments as String; // لازم تبعت taskId هنا
          return MaterialPageRoute(
            builder: (context) => DriverRatingsScreen(driverId: driverId),
          );
        }
        return null; // دع المسارات الأخرى تعمل بشكل طبيعي
      },
      initialRoute: MainDriverScreen.routeName,
      // initialRoute: MainScreen.routeName,
    );
  }
}
