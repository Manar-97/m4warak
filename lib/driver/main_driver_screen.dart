import 'package:flutter/material.dart';
import 'driver_home.dart';
import 'driver_profile.dart';
import 'driver_setting.dart';

class MainDriverScreen extends StatefulWidget {
  const MainDriverScreen({super.key});
  static const String routeName = 'maindriver';
  @override
  State<MainDriverScreen> createState() => _MainDriverScreenState();
}

class _MainDriverScreenState extends State<MainDriverScreen> {
  int _currentIndex = 0;

  final List<Widget> screens = [
    DriverHomeScreen(),
    DriverProfileScreen(),
    DriverSettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
