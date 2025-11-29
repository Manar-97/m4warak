import 'package:flutter/material.dart';
import 'package:mshawer/profile.dart';
import 'package:mshawer/setting.dart';

import 'home.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
static const String routeName = 'main';
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> screens = [HomeScreen(), Profile(), Setting()];

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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
      ),

    );
  }
}
